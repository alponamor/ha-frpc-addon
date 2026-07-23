#!/usr/bin/with-contenv bashio
# Runtime: generate frpc.toml (TOML, frp 0.70.x) from the add-on options and start frpc.
# TCP proxy: HA (127.0.0.1:haport, host_network) <-> frps remotePort.
set -eu

SERVER_IP=$(bashio::config 'serverip')
SERVER_PORT=$(bashio::config 'serverport')
TOKEN=$(bashio::config 'token')
HA_PORT=$(bashio::config 'haport')
REMOTE_PORT=$(bashio::config 'remoteport')
ENC=$(bashio::config 'encryption')
COMP=$(bashio::config 'compression')

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
    echo "name = \"homeassistant\""
    echo "type = \"tcp\""
    echo "localIP = \"127.0.0.1\""
    echo "localPort = ${HA_PORT}"
    echo "remotePort = ${REMOTE_PORT}"
    [ "$ENC" = "true" ] && echo "transport.useEncryption = true"
    [ "$COMP" = "true" ] && echo "transport.useCompression = true"
} > "$CONF"

bashio::log.info "frpc 0.70.1 -> ${SERVER_IP}:${SERVER_PORT}; HA 127.0.0.1:${HA_PORT} <-> remote ${REMOTE_PORT}"
cat "$CONF"
exec /usr/src/frpc -c "$CONF"
