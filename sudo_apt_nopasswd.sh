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

conf_path=/etc/sudoers.d/apt-nopasswd
if [ -e "$conf_path" ]; then
    echo "file already exists: $conf_path"
    exit 0
fi

echo "Writing config to $conf_path"

cat > "$conf_path" <<EOM
# Allow members of sudo to run apt update passwordless
%sudo ALL=(ALL) NOPASSWD: /usr/bin/apt update
%sudo ALL=(ALL) NOPASSWD: /usr/bin/apt-get update
%sudo ALL=(ALL) NOPASSWD: /usr/bin/aptitude update
EOM
run chmod 0440 "$conf_path"

if run visudo -c; then
    echo "Passwordless apt update enabled"
else
    echo "Something went wrong, starting interactive shell"
    /bin/bash
fi
