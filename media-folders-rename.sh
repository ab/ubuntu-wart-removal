#!/bin/bash
set -euo pipefail

run() {
    echo >&2 "+ $*"
    "$@"
}

mkdir -p ~/media

if [ -d ~/Videos ]; then
    video_dir=~/media/video
    mv -nvT ~/Videos "$video_dir"
    run xdg-user-dirs-update --set VIDEOS "$video_dir"
fi
if [ -d ~/Music ]; then
    music_dir=~/media/music
    mv -nvT ~/Music "$music_dir"
    run xdg-user-dirs-update --set MUSIC "$music_dir"
fi
