#!/usr/bin/with-contenv bashio
# Runtime: generate frpc.toml (TOML, frp 0.70.x) from the add-on options and start frpc.
# TCP proxy: HA (127.0.0.1:<port>, host_network) <-> frps remotePort.
#
# haport = 0 (default) -> the local HA port is auto-detected from the Supervisor
# API (bashio::core.port), so the tunnel follows the HA web-server port wherever
# it moves (8123 legacy, 80 on HA 2026.8+ "portless" setups, or any custom value
# set in Settings > System > Network > Web server). A positive haport overrides.
set -eu

SERVER_IP=$(bashio::config 'serverip')
SERVER_PORT=$(bashio::config 'serverport')
TOKEN=$(bashio::config 'token')
HA_PORT=$(bashio::config 'haport')
REMOTE_PORT=$(bashio::config 'remoteport')
ENC=$(bashio::config 'encryption')
COMP=$(bashio::config 'compression')

if [ -z "${HA_PORT}" ] || [ "${HA_PORT}" = "null" ] || [ "${HA_PORT}" = "0" ]; then
    if DETECTED=$(bashio::core.port) && [ -n "${DETECTED}" ] && [ "${DETECTED}" != "null" ]; then
        HA_PORT="${DETECTED}"
        bashio::log.info "Auto-detected Home Assistant port: ${HA_PORT}"
    else
        HA_PORT=8123
        bashio::log.warning "Could not auto-detect the HA port via the Supervisor API; falling back to 8123"
    fi
else
    bashio::log.info "Using manually configured HA port: ${HA_PORT} (set haport: 0 for auto-detection)"
fi

CONF=/etc/frpc.toml
{
    echo "serverAddr = \"${SERVER_IP}\""
    echo "serverPort = ${SERVER_PORT}"
    echo "auth.method = \"token\""
    echo "auth.token = \"${TOKEN}\""
    echo "log.to = \"console\""
    echo "log.level = \"info\""
    echo ""
    echo "[[proxies]]"
    # Proxy names must be unique across ALL clients of one frps (no `user` prefix is set), so the
    # name carries the house's remotePort — itself unique per house (frps allowPorts). v1.2.0.
    echo "name = \"homeassistant-${REMOTE_PORT}\""
    echo "type = \"tcp\""
    echo "localIP = \"127.0.0.1\""
    echo "localPort = ${HA_PORT}"
    echo "remotePort = ${REMOTE_PORT}"
    if [ "$ENC" = "true" ]; then echo "transport.useEncryption = true"; fi
    if [ "$COMP" = "true" ]; then echo "transport.useCompression = true"; fi
} > "$CONF"

bashio::log.info "frpc 0.70.1 -> ${SERVER_IP}:${SERVER_PORT}; HA 127.0.0.1:${HA_PORT} <-> remote ${REMOTE_PORT}"
grep -v '^auth.token' "$CONF"
exec /usr/src/frpc -c "$CONF"
