# https://github.com/NLnetLabs/unbound
# https://packages.debian.org/en/stable/net/unbound

FROM debian:12

LABEL maintainer="Ivan Cherniy <kar-kar@r4ven.me>"

WORKDIR /etc/unbound/

COPY ./*.conf /tmp/

ARG DEBIAN_FRONTEND=noninteractive

RUN set -x && \
    apt update && \
    apt install --yes --no-install-recommends \
        tini \
        unbound \
        unbound-anchor \
        iproute2 \
        iputils-ping \
        ldnsutils \
        bc \
        less \
        ca-certificates \
        curl && \
    usermod -u 14956 unbound && \
    groupmod -g 14956 unbound && \
    { unbound-anchor -a /etc/unbound/root.key; true; } && \
    curl -sSL https://www.internic.net/domain/named.cache > /etc/unbound/root.hints && \
    cp /tmp/*.conf /etc/unbound/ && \
    cp /tmp/*.conf /usr/share/doc/unbound/ && \
    cp /etc/unbound/root.key /etc/unbound/root.hints /usr/share/doc/unbound/ && \
    chown -R unbound:unbound /etc/unbound/ && \
    apt purge --yes --auto-remove && \
    apt clean --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

COPY ./unbound.sh ./check.sh /

EXPOSE 53/tcp
EXPOSE 53/udp

HEALTHCHECK --interval=5m --timeout=20s --start-period=20s \
    CMD drill @127.0.0.1 opennameserver.org > /dev/null || exit 1

ENTRYPOINT ["/unbound.sh"]

# CMD ["/usr/sbin/unbound", "-vvv", "-d", "-p", "-c", "/etc/unbound/unbound.conf"]
CMD ["/usr/bin/tini", "--", "/usr/sbin/unbound", "-d", "-p", "-c", "/etc/unbound/unbound.conf"]

