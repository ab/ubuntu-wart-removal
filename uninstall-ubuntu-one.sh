#!/bin/sh
set -eux

if [ -e ~/Ubuntu\ One/ ]; then
    rm -fv ~/Ubuntu\ One/Shared\ With\ Me
    rmdir -v ~/Ubuntu\ One/
fi

if pgrep -fl ubuntuone; then
    killall -2 -v ubuntuone-login ubuntuone-preferences ubuntuone-syncdaemon
fi

pgrep -fl ubuntuone && exit 2 || true

rm -rf ~/.local/share/ubuntuone
rm -rf ~/.cache/ubuntuone
rm -rf ~/.config/ubuntuone

sudo apt-get purge ubuntuone-client python-ubuntuone-storage*
