#!/bin/bash
set -euo pipefail

set -x

sudo apt install plymouth-theme-ubuntu-logo

# select splash screen
sudo update-alternatives --config default.plymouth

# regenerate initramfs
sudo update-initramfs -u

