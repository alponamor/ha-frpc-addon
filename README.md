# FRP Client add-on (BalealHome) — frpc 0.70.1 (TOML)

Community add-on that runs **frpc 0.70.1** on Home Assistant OS, exposing HA to the FRP
server over a TCP tunnel. Forked from `JaccoVeldscholten/HassIO-FRP-Client`,
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
