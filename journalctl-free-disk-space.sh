#!/bin/sh
set -eu

size="${1-500M}"

# See also SystemMaxUse in /etc/systemd/journald.conf
# For example, set SystemMaxUse=1G

set -x

sudo journalctl --rotate --vacuum-size="$size"
