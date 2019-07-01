#!/bin/sh
# https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1722478
set -eux
sudo modprobe -r psmouse && sudo modprobe psmouse
