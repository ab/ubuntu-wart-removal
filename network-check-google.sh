#!/bin/bash
set -euo pipefail

# Use Google for NM connectivity / captive portal check.
# This avoids revealing to the network that we're running Ubuntu, and also is
# likely more reliable in the case that Canonical's servers are having issues.

target=/etc/NetworkManager/conf.d/connectivity-check-uri.conf

if [ -e "$target" ]; then
    echo "already exists: $target"
    exit
fi

echo "Writing config to $target:"

set -x

sudo tee "$target" <<EOM
# AB: phone home to Google, not Canonical for captive portal check
# Default is http://connectivity-check.ubuntu.com.
[connectivity]
uri = http://connectivitycheck.gstatic.com./generate_204
response =
interval = 300
EOM

sudo systemctl restart NetworkManager

echo OK
