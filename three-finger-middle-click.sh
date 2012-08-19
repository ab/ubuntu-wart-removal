#!/bin/sh
set -eu

usage() {
    cat >&2 <<EOM
usage: $(basename "$0") ACTION ...

ACTION
    install   Install this script as a hotplug command so the setting persists.
    [*]       Run synclient to enable three finger middle click.

This script logs its arguments to syslog when run.
EOM
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

log_cmd() {
    logger -t "$(basename "$0")" "$*"
}

case "$1" in
    -h|--help)
        usage
        exit 0
        ;;
    install)
        log_cmd "Installing hotplug hook (args: $*)"
        setting=org.gnome.settings-daemon.peripherals.input-devices
        script="$(readlink -e "$0")"
        set -x
        gsettings get "$setting" hotplug-command
        gsettings set "$setting" hotplug-command "$script"
        ;;
    *)
        if echo "$*" | grep Synaptics; then
            log_cmd "Applying synclient settings (args: $*)"
            set -x
            synclient TapButton3=2
        else
            log_cmd "Ignoring event (args: $*)"
        fi
        ;;
esac
