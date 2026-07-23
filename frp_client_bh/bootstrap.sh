#!/bin/sh
# Build-time installer: downloads frpc v<FRP_VERSION> for the build arch into /usr/src/frpc.
# Plain sh (no bashio) — runs during `docker build`.
set -e

build_arch=$1
version=$2
frp_url="https://github.com/fatedier/frp/releases/download/"
app_path="/usr/src"

case "$build_arch" in
    aarch64) machine="arm64" ;;
    amd64)   machine="amd64" ;;
    armhf)   machine="arm" ;;
    armv7)   machine="arm" ;;
    i386)    machine="386" ;;
    *) echo "Unsupported build arch: $build_arch" >&2; exit 1 ;;
esac

file_name="frp_${version}_linux_${machine}.tar.gz"
file_url="${frp_url}v${version}/${file_name}"
file_dir="frp_${version}_linux_${machine}"

echo "Installing frpc v${version} (${machine}) from ${file_url}"
mkdir -p "$app_path" /tmp/extract
curl -fsSL "$file_url" -o "/tmp/${file_name}"
tar xzf "/tmp/${file_name}" -C /tmp/extract
cp -f "/tmp/extract/${file_dir}/frpc" "${app_path}/frpc"
chmod +x "${app_path}/frpc"
rm -rf "/tmp/${file_name}" /tmp/extract
ls -la "$app_path"
