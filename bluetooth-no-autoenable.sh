#!/bin/bash
set -euo pipefail

run () {
    echo >&2 "+ $*"
    "$@"
}

if grep -x "AutoEnable=false" /etc/bluetooth/main.conf; then
    echo "Nothing to do"
    exit
fi

if ! grep -x "AutoEnable=true" /etc/bluetooth/main.conf; then
    echo "Error: could not find expected line in /etc/bluetooth/main.conf"
    exit 1
fi

pat='s/^AutoEnable=true$/#AutoEnable=true\nAutoEnable=false/'

run sudo sed -i~ -r "$pat" /etc/bluetooth/main.conf

echo "All done"
