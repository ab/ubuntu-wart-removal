#!/bin/bash
set -eu

if which colordiff >/dev/null; then
    DIFF=colordiff
else
    DIFF=diff
fi

run() {
    echo >&2 "+ $*"
    "$@"
}

diff_cp() {
    local src dst
    if [ $# -lt 2 ]; then
        echo >&2 "do_compare SOURCE DEST"
        return 1
    fi
    src="$1"
    dst="$2"

    if [ -e "$dst" ]; then
        "$DIFF" -u -- "$src" "$dst" && ret=$? || ret=$?

        case "$ret" in
            0)
                echo "$dst already installed"
                return 0
                ;;
            1)
                # there will be changes
                ;;
            *)
                echo >&2 "$DIFF exited with status $ret"
                return "$ret"
                ;;
        esac
    fi

    run sudo cp -iv -- "$src" "$dst"
}

u2f_src="$(dirname "$0")/data/70-u2f.rules"
content="$(cat "$u2f_src")"

url=https://raw.githubusercontent.com/Yubico/libu2f-host/master/70-u2f.rules
web_content="$(wget -O - "$url")"

echo "Checking that our saved data at $u2f_src is up to date from $url"

if [ "$web_content" != "$content" ]; then
    echo >&2 "Error: content from web at $url differs from $u2f_src"
    exit 1
fi

diff_cp "$u2f_src" /etc/udev/rules.d/70-u2f.rules

yubikey_src="$(dirname "$0")/data/68-yubikey.rules"

diff_cp "$yubikey_src" /etc/udev/rules.d/68-yubikey.rules
