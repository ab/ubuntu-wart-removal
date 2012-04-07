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

echo "current: '$(gconftool -g /apps/metacity/general/button_layout)'"
echo "target:  '$(gconftool -g /apps/metacity/general/button_layout)'"

set -x
gconftool -t string -s /apps/metacity/general/button_layout "$layout"
