#!/bin/sh
# (c) Pete Birley

cd /source/libreoffice && ./autogen.sh --enable-gtk3 --without-java --without-doxygen &&  make

#this sets the vnc password
/usr/local/etc/start-vnc-expect-script.sh

#fixes a warning with starting nautilus on firstboot - which we will always be doing.
mkdir -p ~/.config/nautilus &

#this starts the vnc server
USER=root vncserver :1 -geometry 1366x768 -depth 24 &

#this starts noVNC
/noVNC/utils/launch.sh --vnc 127.0.0.1:5901 --listen 80 &

bash

