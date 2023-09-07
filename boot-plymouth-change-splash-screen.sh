#!/bin/bash
set -euo pipefail

set -x

# select splash screen
sudo update-alternatives --config default.plymouth

# regenerate initramfs
sudo update-initramfs -u

