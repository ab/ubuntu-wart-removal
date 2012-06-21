#!/bin/sh
set -eux

config=/etc/NetworkManager/NetworkManager.conf
if grep -E '^dns=dnsmasq$' $config; then
    sudo sed -i~ 's/^dns=dnsmasq$/#dns=dnsmasq/' $config
    sudo service network-manager restart
else
    echo 'Nothing to do.'
fi
