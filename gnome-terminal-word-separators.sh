#!/bin/bash
set -eu

PROFILES_PREFIX=/org/gnome/terminal/legacy/profiles:

run() {
    echo >&2 "+ $*"
    "$@"
}

list_gnome_terminal_profile_uuids() {
    dconf list "$PROFILES_PREFIX/" | grep : | tr -d ':/'
}

usage() {
    cat >&2 <<EOM
usage: $(basename "$0") [-p UUID|--all] NON_WORD_SEPARATORS

Set word separator exceptions for GNOME Terminal. For double click selection,
all punctuation will break words by default. The list of word-char-exceptions
is a set of unicode characters that will be treated as part of the word and not
as a word boundary.

Set punctuation like hyphen or underscore here if you want them to be treated
as a single unit with the word for double click selection.

Options:
    -h, --help          Display this message
    --all               Set word chars for all gnome-terminal profiles
    -p, --profile UUID  Set word chars for given gnome-terminal profile UUID
    --sensible-default  Use old GNOME Terminal default chars

For example:
    # set word-char-exceptions for all profiles
    $0 --all '#%&+,-./:=?@_~'

    # set word-char-exceptions for a specific profile
    $0 -p 8741a4c2-15c8-45bb-86ec-34c3080526a7 '#%&+,-./:=?@_~'

    # escape word-char-exceptions that start with hyphen
    $0 --all -- '-#%&+,./:=?@_~'

    # set a sensible default (restore old GNOME Terminal behavior)
    $0 --all --sensible-default

FYI: The help description of word-char-exceptions in dconf was backwards in
gnome-terminal versions prior to 3.51.90.

You can find your GNOME Terminal profile UUID in Profile Preferences > General.

EOM

    local name uuid

    echo >&2 "Known GNOME Terminal profiles:"
    for uuid in $(list_gnome_terminal_profile_uuids); do
        name="$(dconf read "$PROFILES_PREFIX/:$uuid/visible-name")"
        echo >&2 "	$uuid	$name"
    done
    echo >&2
}

set_exceptions() {
    local uuid path

    uuid="$1"
    path="$PROFILES_PREFIX/:$uuid/"

    echo "Setting word-char-exceptions for profile $uuid"

    if [ -z "$(run dconf list "$path")" ]; then
        echo >&2 "error: Nothing at $path, are you sure $uuid is correct?"
        run dconf list /org/gnome/terminal/legacy/profiles:/
        exit 2
    fi

    run dconf write "${path}word-char-exceptions" "@ms \"$non_word_separators\""
}

mode='<unset>'
uuid=
non_word_separators=

while [ $# -gt 0 ] && [[ $1 == -* ]]; do
    case "$1" in
        -h|--help)
            usage
            exit
            ;;
        --all)
            mode=all
            ;;
        -p|--profile)
            mode=single
            uuid="$2"
            shift
            ;;
        --sensible-default)
            non_word_separators='#%&+,-./:=?@_~'
            ;;
        --)
            shift
            break
            ;;
        *)
            usage
            echo >&2 "Error: Unknown option '$1'"
            exit 1
            ;;
    esac
    shift
done

if [ -n "$non_word_separators" ]; then
    if [ $# -ne 0 ]; then
        usage
        echo >&2 "Can't pass --sensible-default and NON_WORD_SEPARATORS"
        exit 1
    fi

else
    if [ $# -ne 1 ]; then
        usage
        exit 1
    fi

    non_word_separators="$1"
fi

case "$mode" in
    single)
        set_exceptions "$uuid"
        ;;
    all)
        for uuid in $(list_gnome_terminal_profile_uuids); do
            set_exceptions "$uuid"
        done
        ;;
    '<unset>')
        usage
        echo >&2 "Must set profile with --all or -p/--profile UUID"
        exit 1
        ;;
    *)
        echo >&2 "Invalid mode $mode"
        exit 3
        ;;
esac
