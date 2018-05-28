#!/bin/sh
# Enable the logout option in gnome shell
set -eux
gsettings set org.gnome.shell always-show-log-out true
