#!/bin/sh

run() {
    echo >&2 "+ $*"
    "$@"
}

schema=org.gnome.desktop.input-sources
key=xkb-options

current_val="$(run gsettings get $schema $key)"

desired_val="['terminate:ctrl_alt_bksp', 'caps:ctrl_modifier']"

if [ -z "$current_val" ]; then
    run gsettings set $schema $key \
        "$desired_val"
else
    echo >&2 "$key already set to $current_val"
    if [ "$current_val" != "$desired_val" ]; then
        exit 1
    else
        exit 0
    fi
fi
