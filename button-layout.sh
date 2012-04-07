#!/bin/sh
# move buttons right or left

if [ $# -lt 1 ]; then
    echo "$(basename "$0") [right|left]"
    exit 1
fi

if [ "$1" = "right" ]; then
    layout="menu:minimize,maximize,close"
elif [ "$1" = "left" ]; then
    layout="close,minimize,maximize:"
else
    echo "unknown layout"
    exit 2
fi

echo "current: '$(gconftool -g /apps/metacity/general/button_layout)'"
echo "target:  '$(gconftool -g /apps/metacity/general/button_layout)'"

set -x
gconftool -t string -s /apps/metacity/general/button_layout "$layout"
