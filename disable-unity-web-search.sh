#!/bin/sh
set -eu

CCUL=com.canonical.Unity.Lenses

set -x

gsettings set "$CCUL" remote-content-search none


gsettings set "$CCUL" disabled-scopes \
    "['more_suggestions-amazon.scope', 'more_suggestions-u1ms.scope',
    'more_suggestions-populartracks.scope', 'music-musicstore.scope',
    'more_suggestions-ebay.scope', 'more_suggestions-ubuntushop.scope',
    'more_suggestions-skimlinks.scope']"

# Block connections to Ubuntu's ad server, just in case
if ! grep -q "127.0.0.1 productsearch.ubuntu.com" /etc/hosts; then
    echo -e "\n127.0.0.1 productsearch.ubuntu.com" | sudo tee -a /etc/hosts
fi
