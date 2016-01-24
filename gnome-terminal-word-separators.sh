#!/bin/sh
set -eu

non_word_separators='-#%&+,./:=?@_~'

if [ $# -lt 1 ]; then
    cat >&2 <<EOM
usage: $(basename "$0") GNOME_TERMINAL_PROFILE_UUID [NON_WORD_SEPARATORS]

Set word separator exceptions to the old gnome-terminal defaults.

Target default non-word-separators:
    $non_word_separators

You can find the GNOME Terminal profile UUID in Profile Preferences > General.

Known IDs:
$(dconf list /org/gnome/terminal/legacy/profiles:/ \
    | grep : | tr -d ':/' | sed 's/^/    /')

EOM
    exit 1
fi

uuid="$1"

if [ $# -ge 2 ]; then
    non_word_separators="$2"
fi

run() {
    echo >&2 "+ $*"
    "$@"
}

path="/org/gnome/terminal/legacy/profiles:/:$uuid/"

if [ -z "$(run dconf list "$path")" ]; then
    echo >&2 "error: Nothing at $path, are you sure $uuid is correct?"
    run dconf list /org/gnome/terminal/legacy/profiles:/
    exit 2
fi

run dconf write "${path}word-char-exceptions" "@ms \"$non_word_separators\""
