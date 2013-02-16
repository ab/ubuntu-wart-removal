#!/bin/sh
set -eux

# http://askubuntu.com/questions/34214/how-do-i-disable-overlay-scrollbars

#sudo aptitude remove overlay-scrollbar liboverlay-scrollbar3-0.2-0 liboverlay-scrollbar-0.2-0
echo 'export LIBOVERLAY_SCROLLBAR=0' >> ~/.xprofile
