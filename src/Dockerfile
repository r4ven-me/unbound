# https://github.com/NLnetLabs/unbound
# https://packages.debian.org/en/stable/net/unbound

FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

LABEL maintainer="Ivan Cherniy <kar-kar@r4ven.me>"

RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=bind,target=/src,source=./ \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/var/log \
    --mount=type=tmpfs,target=/var/tmp \
    --mount=type=tmpfs,target=/var/cache/debconf \
    --mount=type=tmpfs,target=/run \
    --mount=type=tmpfs,target=/tmp \
    set -x && \
    apt update && \
    apt install --yes --no-install-recommends --no-install-suggests \
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
    cp /src/*.conf /etc/unbound/ && \
    cp /src/*.conf /usr/share/doc/unbound/ && \
    cp /src/unbound.sh /src/check.sh / && \
    cp /etc/unbound/root.key /etc/unbound/root.hints /usr/share/doc/unbound/ && \
    chown -R unbound:unbound /etc/unbound/ && \
    apt purge --yes --auto-remove

EXPOSE 53/tcp \
       53/udp

HEALTHCHECK --interval=5m --timeout=20s --start-period=20s \
    CMD drill @127.0.0.1 opennameserver.org > /dev/null || exit 1

ENTRYPOINT ["/unbound.sh"]

# CMD ["/usr/sbin/unbound", "-vvv", "-d", "-p", "-c", "/etc/unbound/unbound.conf"]
CMD ["/usr/bin/tini", "--", "/usr/sbin/unbound", "-d", "-p", "-c", "/etc/unbound/unbound.conf"]

