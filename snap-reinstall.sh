#!/bin/bash
set -euo pipefail


run() {
    echo >&2 "+ $*"
    "$@"
}

snap_name=$1

run snap remove "$snap_name"

run snap install "$snap_name"

snapshot=$(snap saved | grep -w "$snap_name" | sort -nk1 | tail -n1)

echo "Snapshot: $snapshot"

snapshot_id=$(echo "$snapshot" | awk '{print $1}')

read -rp "continue... "

run snap restore "$snapshot_id"
