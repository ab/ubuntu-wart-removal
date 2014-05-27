#!/bin/sh
set -eux

rm -fv ~/Ubuntu\ One/Shared\ With\ me
rmdir -v ~/Ubuntu\ One/

killall -2 -v ubuntuone-login ubuntuone-preferences ubuntuone-syncdaemon
killall -2 -v ubuntuone-login ubuntuone-preferences ubuntuone-syncdaemon || true

rm -rf ~/.local/share/ubuntuone
rm -rf ~/.cache/ubuntuone
rm -rf ~/.config/ubuntuone

sudo apt-get purge ubuntuone-client python-ubuntuone-storage*
