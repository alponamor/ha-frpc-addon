ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_ARCH
ARG FRP_VERSION

ENV LANG C.UTF-8

# Download + install frpc 0.70.1 for the build arch (matches the BalealHome frps 0.70.1).
COPY bootstrap.sh /
COPY run.sh /

RUN chmod a+x /bootstrap.sh /run.sh
RUN /bootstrap.sh "$BUILD_ARCH" "$FRP_VERSION"

CMD [ "/run.sh" ]
