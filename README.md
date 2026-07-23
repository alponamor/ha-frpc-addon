# FRP Client add-on (BalealHome) — frpc 0.70.1 (TOML)

Community add-on that runs **frpc 0.70.1** on Home Assistant OS, exposing HA to the BalealHome FRP
server (`fhb.balealhome.com`) over a TCP tunnel. Forked from `JaccoVeldscholten/HassIO-FRP-Client`,
bumped to **frp 0.70.1** and switched to **TOML** config so the client matches the BalealHome
`frps 0.70.1` (frp requires frpc and frps to be the same version — the original add-on's frp 0.46.1
would not connect).

## Why a fork

- `frps` on the BalealHome server is pinned to **0.70.1**.
- Off-the-shelf HA frpc add-ons bundle old/mismatched versions: JaccoVeldscholten = 0.46.1 (INI),
  WeeXnes = 0.60.0 (but its build fails with `BUILD_FROM blank`). None matches 0.70.1.
- This fork bumps `FRP_VERSION` to `0.70.1` (build.json) and rewrites `run.sh` to emit `frpc.toml`.

## Files (the whole add-on — push these to a GitHub repo)

`config.yaml`, `build.json`, `Dockerfile`, `bootstrap.sh`, `run.sh`.

## Install in Home Assistant

1. Push these files to a **public GitHub repo** (e.g. fork JaccoVeldscholten and replace `build.json`
   + `run.sh`, or create a new repo with all files). git.balealhome.com is NOT reliably reachable from
   the home network (DNS still on the old server + self-signed cert) → use GitHub.
2. HA → Settings → Add-ons → **Add-on Store** → ⋮ → **Repositories** → add your repo URL → close.
3. Refresh the store, find **"FRP Client (BalealHome)"**, **Install** (HA builds it locally).
4. Configuration:
   - `serverip`: `217.28.140.223`
   - `serverport`: `7000`
   - `token`: the FRPS token (same as the server's `frps.toml auth.token`)
   - `haport`: `8123`
   - `remoteport`: `8123`  (FHB; one per house on the server side)
   - `encryption`: `true`, `compression`: `true`
5. **Start**. Check the add-on log: `login to server success` + `proxy ... [homeassistant] get ... success`.
   On the server: `kubectl -n atlanti logs deploy/frps` shows the proxy registered.

## Scaling to more houses

Each house runs this same add-on with its own `remoteport` (8124, 8125…). Add that port to the server's
`frps-configmap.yaml` `allowPorts`, to `frps-svc-tunnels.yaml`, expose it on the frps Deployment, and add
a Traefik Ingress for that house's subdomain. `haport` stays 8123 (HA's local port) everywhere.

## Rollback

Uninstall/disable the add-on in HA. The source is versioned in `atlanti-web/k8s/frp/ha-frpc-addon/`
(rollback tag `pre-ha-frp-tunnel-2026-07-23` on `atlanti-web`).
