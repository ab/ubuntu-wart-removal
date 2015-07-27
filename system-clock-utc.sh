#!/bin/sh
set -eux

# Set the system clock to UTC
sudo sed -i~ 's/^UTC=no$/#UTC=no\nUTC=yes/' /etc/default/rcS
