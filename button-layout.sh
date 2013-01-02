#!/bin/sh
# move buttons right or left

if [ $# -lt 1 ]; then
    echo "$(basename "$0") [right|nomenu|left]"
    exit 1
fi

case "$1" in
    right)
        layout="menu:minimize,maximize,close"
        ;;
    nomenu)
        layout=":minimize,maximize,close"
        ;;
    left)
        layout="close,minimize,maximize:"
        ;;
    *)
        echo "unknown layout"
        exit 2
        ;;
esac

path="org.gnome.desktop.wm.preferences"
var="button-layout"

echo "current: '$(gsettings get "$path" "$var")'"
echo "target:  '$layout'"

set -x
gsettings set "$path" "$var" "$layout"
