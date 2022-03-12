#!/bin/sh
set -eu

size="${1-500M}"

set -x

sudo journalctl --rotate --vacuum-size="$size"
