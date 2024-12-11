#!/bin/bash
set -euo pipefail

run () {
    echo >&2 "+ $*"
    "$@"
}


# Disable annoying settings from "Ubuntu Tiling Assistant", an extension for
# Gnome that has some irritating Windows-like default behavior.
#
# https://launchpad.net/ubuntu/+source/gnome-shell-extension-tiling-assistant
# https://extensions.gnome.org/extension/3733/tiling-assistant/
# gnome-shell-extension-tiling-assistant
#

# disable tiling popup
run gsettings set org.gnome.shell.extensions.tiling-assistant enable-tiling-popup false

# disable raise together
run gsettings set org.gnome.shell.extensions.tiling-assistant enable-raise-tile-group false

echo OK
