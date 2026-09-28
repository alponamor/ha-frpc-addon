# BalealHome FRP Client — HA OS add-on (frpc 0.70.1, TOML)

Home Assistant OS add-on running **frpc 0.70.1**, tunneling Home Assistant to the BalealHome FRP
server (`<house>.balealhome.com`, e.g. `fhb`, `stal`) over a TCP tunnel. frp 0.70.1 matches the BalealHome `frps 0.70.1`
(frp requires frpc and frps to be the same version — off-the-shelf HA frpc add-ons bundle
old/mismatched versions, so this fork pins 0.70.1).

## v1.3.0 — work-connection pool (ATL-2026-0053)

New option `poolcount` (default 20) → frpc `transport.poolCount`. With frp defaults frps keeps at most
11 ready work connections per client (`min(poolCount 1, maxPoolCount 5) + 10`) and refills each one taken;
a dashboard load opening more parallel connections overflows it and frpc logs
`StartWorkConn contains error: work connection pool is full, discarding` (harmless, extra connections are
dropped). With 20 (frps `transport.maxPoolCount = 50`) the pool holds 30 and 20 are ready up front.
After updating an existing install, check that `poolcount: 20` appears in the add-on Configuration.

## v1.2.0 — several houses on one frps (ATL-2026-0051)

The frpc proxy is named `homeassistant-<remoteport>` (was the fixed `homeassistant`). frps rejects a
second client that registers an already-used proxy name (`proxy [homeassistant] already exists`), so
with the fixed name only ONE house could be connected at a time. `remoteport` is unique per house,
hence so is the name. Existing 1.1.0 installs keep working (fhb: `homeassistant` on 8123); updating
them is optional — the name changes, the tunnel does not.

⚠ Every house MUST set its own `remoteport` (fhb 8123, stal 8124, …). The default 8123 is fhb's.

## v1.1.0 — port-agnostic (HA 2026.8 "minus the magic number")

Since HA 2026.8, new HA OS installs listen on **port 80** (no `:8123`), and any install can move
its web-server port via *Settings → System → Network → Web server*. The add-on therefore
**auto-detects the local HA port** from the Supervisor API (`bashio::core.port`, enabled by
`hassio_api: true`) when `haport: 0` (the new default). A positive `haport` value overrides
auto-detection (legacy behaviour). The tunnel follows the HA port wherever it moves — 8123,
80, or custom — after an add-on restart.

⚠ **Upgrading from ≤1.0.2:** the saved option `haport: 8123` survives the add-on update — set it
to `0` manually in the add-on Configuration to enable auto-detection.

⚠ **Do not restrict the HA web-server listen interface** (Settings → System → Network):
frpc reaches HA via `127.0.0.1` (host_network), so localhost must stay listening.

Other v1.1.0 changes: least-privilege (dropped `privileged: NET_ADMIN` + `/dev/net/tun` — frpc
only makes an outbound TCP connection), `token` is a masked `password` field in the UI, and the
FRPS token is no longer echoed into the add-on log.

## Repository layout (HA docs: `repository.yaml` + add-on in its own folder)

```
repository.yaml          # makes this repo a valid HA add-on store
frp_client_bh/           # the add-on
  config.yaml            # HA add-on config + options/schema (token, haport, remoteport, ...)
  build.json             # build_from per arch (injects BUILD_FROM) + FRP_VERSION=0.70.1
  Dockerfile             # installs frpc 0.70.1 inline (no bootstrap.sh) + strips CRLF from run.sh
  run.sh                 # resolves the HA port (auto/override), generates frpc.toml, execs frpc
```

## Install (deployed at github.com/alponamor/ha-frpc-addon)

1. HA → Settings → Add-ons → Add-on Store → ⋮ → Repositories → add the repo URL.
2. Install **"BalealHome FRP Client"**.
3. Configuration: `token` = the frps `auth.token`; `serverip=217.28.140.223`, `serverport=7000`,
   `haport=0` (auto-detect; set a positive value only to override), `remoteport=8123`,
   `encryption=true`, `compression=true`.
4. Start → log shows the detected HA port, `login to server success` + `[homeassistant] start proxy success`.

## Ports / architecture

Browser → `https://fhb.balealhome.com` (443, Traefik LE cert) → Service `frps-tunnels:8123`
(ClusterIP) → `frps` → tunnel → `frpc` (HA OS, host_network) → HA `127.0.0.1:<detected port>`
(plain HTTP; TLS terminated at Traefik). HA's `http:` must NOT set `ssl_certificate` (plain HTTP
behind the proxy). NOTE: `remoteport=8123` is the **cluster-side tunnel port** (frps
allowPorts/Service/Ingress) — it is independent of the local HA port and stays 8123 even when
HA itself listens on 80.

## Scaling to more houses

Each house: its own `remoteport` here (8124, 8125…) inside frps `allowPorts` (8123–8130), a
`frps-svc-tunnels` port + `containerPort`, and a per-house Traefik Ingress + DNS A record — see
`../README.md` (Houses table) and `../../docs/runbooks/ha-house-onboarding.md`. `haport` stays `0` (auto) —
new HA OS installs (2026.8+) listen on port 80 and are detected automatically.

## Rollback

Source versioned in the `gitadmin/atlanti-infra` repo at `frp/ha-frpc-addon/` (rollback tag
`pre-ha-portless-2026-08-18`; GitHub deploy tag `v1.0.2` marks the pre-1.1.0 state, `v1.1.0` the pre-1.2.0 state — ATL-2026-0051,
infra rollback tag `pre-ha-stal-2026-09-28`). Disable/
uninstall the add-on in HA; frps resources removed via the `frp/` rollback in the plan.
