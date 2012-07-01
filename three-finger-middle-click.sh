#!/bin/sh
set -eu

usage() {
    cat >&2 <<EOM
usage: $(basename "$0") ACTION

ACTION:
    apply     Run synclient to enable three finger middle click.
    install   Install this script as a hotplug command so the setting persists.
EOM
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

case "$1" in
    apply)
        set -x
        synclient TapButton3=2
        ;;
    install)
        setting=org.gnome.settings-daemon.peripherals.input-devices
        set -x
        gsettings set "$setting" hotplug-command "$0"
        ;;
    *)
        usage
        echo >&2
        echo >&2 "Error: unknown ACTION"
        exit 2
esac
