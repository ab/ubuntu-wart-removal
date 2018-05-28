#!/bin/bash
set -euo pipefail

set -o noclobber

run() {
    echo >&2 "+ $*"
    "$@"
}


if [ $UID -ne 0 ]; then
    echo "This script must be run as root."
    echo "You do have a root shell open, don't you?"
    exit 1
fi

if grep insults /etc/sudoers /etc/sudoers.d/* > /dev/null; then
    echo "insults appear to be already enabled"
    exit 0
fi

conf_path=/etc/sudoers.d/insults
run install -m 0440 <(echo 'Defaults	insults') "$conf_path"
echo "Wrote config to $conf_path"

if run visudo -c; then
    echo "Insults enabled"
else
    echo "Something went wrong, starting interactive shell"
    /bin/bash
fi
