FROM ubuntu:22.04
LABEL maintainer="chuppa"

ARG DEBIAN_FRONTEND="noninteractive"
ARG ARCH_S6="amd64"
ARG ARCH_RCLONE="amd64"

ENV APP_DIR="/app" CONFIG_DIR="/config" PUID="1000" PGID="1000" UMASK="022" VERSION="image" BACKUP="yes"
ENV XDG_CONFIG_HOME="${CONFIG_DIR}/.config" XDG_CACHE_HOME="${CONFIG_DIR}/.cache" XDG_DATA_HOME="${CONFIG_DIR}/.local/share" LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8"
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

VOLUME ["${CONFIG_DIR}"]
ENTRYPOINT ["/init"]

# make folders
RUN mkdir "${APP_DIR}" && \
# create user
    useradd -u 1000 -U -d "${CONFIG_DIR}" -s /bin/false chuppa && \
    usermod -G users chuppa

# install packages
RUN apt update && \
    apt install -y --no-install-recommends --no-install-suggests \
        ca-certificates jq unzip curl fuse python figlet \
        libfuse-dev autoconf automake build-essential \
        locales tzdata nano && \
# generate locale
    locale-gen en_US.UTF-8 && \
# install s6-overlay
# https://github.com/just-containers/s6-overlay/releases
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-${ARCH_S6}.tar.gz" | tar xzf - -C / && \
# install rclone
# https://github.com/ncw/rclone/releases
    curl -fsSL -o "/tmp/rclone.deb" "https://github.com/ncw/rclone/releases/download/v1.56.2/rclone-v1.56.2-linux-${ARCH_RCLONE}.deb" && dpkg --install "/tmp/rclone.deb" && \
# install rar2fs
# https://github.com/hasse69/rar2fs/releases
# https://www.rarlab.com/rar_add.htm
    tempdir="$(mktemp -d)" && \
    curl -fsSL "https://github.com/hasse69/rar2fs/archive/v1.29.5.tar.gz" | tar xzf - -C "${tempdir}" --strip-components=1 && \
    curl -fsSL "https://www.rarlab.com/rar/unrarsrc-6.0.2.tar.gz" | tar xzf - -C "${tempdir}" && \
    cd "${tempdir}/unrar" && \
    make lib && make install-lib && \
    cd "${tempdir}" && \
    autoreconf -f -i && \
    ./configure && make && make install && \
    cd ~ && \
    rm -rf "${tempdir}" && \
# clean up
    apt purge -y libfuse-dev autoconf automake build-essential && \
    apt autoremove -y && \
    apt clean && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

COPY root/ /
