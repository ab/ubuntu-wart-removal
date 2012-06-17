#!/bin/bash
set -eu

if [ $UID -ne 0 ]; then
    echo "This script must be run as root."
    echo "You do have a root shell open, don't you?"
    exit 1
fi

if grep insults /etc/sudoers > /dev/null; then
    echo "insults appear to be already enabled"
    exit 0
fi

pat='s/^Defaults	env_reset$/Defaults	env_reset,insults/'
sed -i~ -e "$pat" /etc/sudoers
