#!/bin/sh
# Install my personal launchpad PPA
set -eu

KEY_FP=BCBFBA133BEE53D43AF0F44602ADED82E72ABF06
trustdb=/etc/apt/trusted.gpg.d/abrody.gpg
sources=/etc/apt/sources.list.d/abrody.list
release="$(lsb_release -cs)"

run() {
    echo >&2 "+ $*"
    "$@"
}

if [ "$(id -u)" != 0 ]; then
    set -x
    exec sudo "$0" "$@"
fi

if [ -e "$trustdb" ]; then
    echo "$trustdb already exists"
else
    run touch "$trustdb"
    run apt-key --keyring "$trustdb" adv --keyserver keyserver.ubuntu.com \
        --recv-keys "$KEY_FP"
fi

if [ -e "$sources" ]; then
    echo "$sources already exists"
else
    run tee "$sources" <<EOM
deb http://ppa.launchpad.net/abrody/ppa/ubuntu $release main
deb-src http://ppa.launchpad.net/abrody/ppa/ubuntu $release main
EOM
fi

apt-get update
