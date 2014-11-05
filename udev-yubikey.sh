#!/bin/bash
set -eu

source_file="$(dirname "$0")/data/70-u2f.rules"
content="$(cat "$source_file")"

url=https://raw.githubusercontent.com/Yubico/libu2f-host/master/70-u2f.rules
web_content="$(wget -O - "$url")"

echo "Checking that our saved data at $source_file is up to date from $url"

if [ "$web_content" != "$content" ]; then
    echo >&2 "Error: content from web at $url differs from $source_file"
    exit 1
fi

target=/etc/udev/rules.d/70-u2f.rules

if which colordiff >/dev/null; then
    diff=colordiff
else
    diff=diff
fi

if [ -e "$target" ]; then
    "$diff" -u -- "$source_file" "$target" && ret=$? || ret=$?

    case "$ret" in
        0)
            echo "$target already installed"
            exit 0
            ;;
        1)
            # there will be changes
            ;;
        *)
            echo >&2 "$diff exited with status $ret"
            exit "$ret"
            ;;
    esac
fi

set -x

sudo cp -iv -- "$source_file" "$target"
