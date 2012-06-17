#!/bin/sh
set -eux

if grep allow-guest /etc/lightdm/lightdm.conf; then
    echo "allow-guest line already present"
    exit 1
else
    echo 'allow-guest=false' | sudo tee -a /etc/lightdm/lightdm.conf
fi
