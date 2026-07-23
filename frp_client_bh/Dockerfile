ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_ARCH
ARG FRP_VERSION=0.70.1

ENV LANG=C.UTF-8

# Install frpc <FRP_VERSION> for the build arch inline (no bootstrap.sh) — must match frps 0.70.1
# on the BalealHome server. apk add curl + ca-certificates guarantees HTTPS works at build time.
RUN apk add --no-cache curl ca-certificates \
    && case "$BUILD_ARCH" in \
        aarch64)     FRP_ARCH=arm64 ;; \
        amd64)       FRP_ARCH=amd64 ;; \
        armhf|armv7) FRP_ARCH=arm ;; \
        i386)        FRP_ARCH=386 ;; \
        *) echo "Unsupported build arch: $BUILD_ARCH" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_${FRP_ARCH}.tar.gz" \
        | tar xz -C /tmp \
    && mkdir -p /usr/src \
    && mv "/tmp/frp_${FRP_VERSION}_linux_${FRP_ARCH}/frpc" /usr/src/frpc \
    && chmod +x /usr/src/frpc \
    && rm -rf /tmp/frp_*

COPY run.sh /run.sh
# Strip any CRLF (Windows) line endings so the #!/usr/bin/with-contenv bashio shebang works at runtime.
RUN sed -i 's/\r$//' /run.sh && chmod a+x /run.sh

CMD [ "/run.sh" ]
