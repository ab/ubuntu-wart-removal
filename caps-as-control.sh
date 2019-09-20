#!/bin/sh

run() {
    echo >&2 "+ $*"
    "$@"
}

schema=org.gnome.desktop.input-sources
key=xkb-options

current_val="$(run gsettings get $schema $key)"

desired_val="['terminate:ctrl_alt_bksp', 'caps:ctrl_modifier']"

case "$current_val" in
  ""|"@as []")
    run gsettings set "$schema" "$key" "$desired_val"
    ;;
  "$desired_val")
    echo >&2 "$key already set to desired val: $desired_val"
    echo >&2 "Nothing to do"
    ;;
  *)
    echo >&2 "Error: $key is nonempty, I don't know how to change safely"
    echo >&2 "Current value: '$current_val'"
    exit 1
    ;;
esac
