#!/bin/sh
set -x
# http://lifehacker.com/5887462/how-to-disable-ubuntus-annoying-global-menu-bar
sudo aptitude purge appmenu-gtk appmenu-gtk3 appmenu-qt indicator-appmenu
