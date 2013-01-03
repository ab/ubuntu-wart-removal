#!/bin/sh
pat='s/^USERGROUPS_ENAB yes$/#USERGROUPS_ENAB yes\nUSERGROUPS_ENAB no/'
set -x
if grep -x 'USERGROUPS_ENAB yes' /etc/login.defs; then
    sudo sed -i~ -r "$pat" /etc/login.defs
fi
