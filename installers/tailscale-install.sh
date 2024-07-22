#!/bin/bash

set -euo pipefail

if which tailscale; then
    tailscale version
    exit
fi

run() {
    echo >&2 "+ $*"
    "$@"
}

colorecho() {
    # shellcheck disable=SC2230
    if which colorecho >/dev/null 2>&1; then
        command colorecho "$@"
    else
        shift
        echo "$@"
    fi
}

codename=$(run lsb_release -cs)

colorecho >&2 blue "Downloading tailscale apt repo files"

cd "$(run mktemp -d)"

run wget --no-verbose \
    "https://pkgs.tailscale.com/stable/ubuntu/$codename.noarmor.gpg" \
    "https://pkgs.tailscale.com/stable/ubuntu/$codename.tailscale-keyring.list"

colorecho >&2 blue "Installing tailscale apt repo files"
sudo cp -v "$codename.noarmor.gpg" /usr/share/keyrings/tailscale-archive-keyring.gpg
sudo cp -v "$codename.tailscale-keyring.list" /etc/apt/sources.list.d/tailscale.list


if [ -d /etc/.git ]; then
    echo >&2
    colorecho >&2 blue "Pausing for manual etckeeper changes"
    echo >&2 "Detected git repo in /etc/.git (etckeeper?)"
    cd /etc
    while [ -n "$(sudo git status --porcelain)" ]; do
        run sudo git status
        echo >&2
        colorecho >&2 yellow "Git repo in /etc/.git has changes"
        colorecho >&2 yellow "Please git add / git commit changes as needed."
        read -rp "Press enter to continue, when ready to apt install... "
    done
fi

colorecho blue >&2 "Installing tailscale"

run sudo apt update
run sudo apt install tailscale

colorecho blue >&2 "Setting up VPN"

run sudo tailscale up

colorecho green >&2 "All done!"

colorecho blue >&2 "Tailscale info:"
run tailscale status
run tailscale ip

cat >&2 <<EOM

Important:
If this is a headless server, you may want to disable key expiry for this
machine here: https://login.tailscale.com/admin/machines
EOM
