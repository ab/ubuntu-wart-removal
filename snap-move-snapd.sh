#!/bin/bash
set -euo pipefail

usage() {
    cat >&2 <<EOM
usage: $0 NEW_PATH

Move /var/lib/snapd to NEW_PATH and set up bind mounts.

For example:

    sudo mkdir /opt/snap
    sudo $0 /opt/snap/snapd

EOM
}

run() {
    echo >&2 "+ $*"
    "$@"
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

if grep /var/lib/snapd /etc/fstab; then
    echo "Found existing snapd mount in fstab, cowardly refusing to continue"
    exit 1
fi

if [[ $(id -u) -ne 0 ]]; then
    set -x
    exec sudo "$0" "$@"
fi

newpath=$1

# ensure trailing slash
newpath_noslash="${newpath%/}"
newpath="$newpath_noslash/"

echo "Will move /var/lib/snapd/ to $newpath"
read -rp "Press enter to continue..."

run systemctl stop snapd.service snapd.socket

run mkdir -v "$newpath"

run rsync -aH --del /var/lib/snapd/ "$newpath"

run mv -vT /var/lib/snapd /var/lib/snapd.bak

run mkdir -v /var/lib/snapd

echo "Writing help file at /var/lib/snapd/UNMOUNTED.txt"
cat > /var/lib/snapd/UNMOUNTED.txt <<EOM
This directory has been moved to $newpath.

If you are seeing this file, it means that the actual snapd directory is not
mounted. It should be bind mounted from $newpath, set up in /etc/fstab.
EOM

run chmod 555 /var/lib/snapd

echo "Updating /etc/fstab"
new_partition=$(df --output=target "$newpath" | tail -1)

# if new path is not on /, then our bind mount must wait for the parent mount
mount_opts=bind
if [[ $new_partition != / ]]; then
    mount_opts="bind,x-systemd.requires=$new_partition"
fi

run tee -a /etc/fstab <<EOM

# AB: mount /var/lib/snapd from $newpath_noslash
$newpath_noslash  /var/lib/snapd  none  $mount_opts  0  0
EOM

run mount -a

# sanity check that mount worked
if ! [ -s /var/lib/snapd/state.json ]; then
    echo >&2 "error: something is wrong with mount... can't find state.json"
    run ls -l /var/lib/snapd/
    exit 2
fi

run systemctl start snapd.service snapd.socket

run snap list

echo "All done! You should now be able to delete /var/lib/snapd.bak"
