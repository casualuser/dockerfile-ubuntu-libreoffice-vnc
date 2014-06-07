#
# Ubuntu Desktop (Gnome) Dockerfile
#
# https://github.com/intlabs/dockerfile-ubuntu-libreoffice-vnc
#

# Install GNOME3 and VNC server.
# (c) Pete Birley

# Pull base image.
#FROM dockerfile/ubuntu
FROM ubuntu:13.04

# Setup enviroment variables
ENV DEBIAN_FRONTEND noninteractive

#Update the package manager and upgrade the system
RUN apt-get update && \
apt-get upgrade -y && \
apt-get update

# Installing fuse filesystem is not possible in docker without elevated priviliges
# but we can fake installling it to allow packages we need to install for GNOME
RUN apt-get install libfuse2 -y && \
cd /tmp ; apt-get download fuse && \
cd /tmp ; dpkg-deb -x fuse_* . && \
cd /tmp ; dpkg-deb -e fuse_* && \
cd /tmp ; rm fuse_*.deb && \
cd /tmp ; echo -en '#!/bin/bash\nexit 0\n' > DEBIAN/postinst && \
cd /tmp ; dpkg-deb -b . /fuse.deb && \
cd /tmp ; dpkg -i /fuse.deb

# Upstart and DBus have issues inside docker.
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl


# Install libreoffice and tightvnc server.
#RUN apt-get update && apt-get install -y xorg gnome-core gnome-session-fallback tightvncserver libreoffice
RUN apt-get update && apt-get install -y xorg tightvncserver libreoffice


#Install the broadway gtk3 ppa for ubuntu 13.04
RUN apt-get install software-properties-common python-software-properties -y
RUN add-apt-repository ppa:malizor/gtk-next-broadway -y
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install broadwayd -y

#Install gedit
RUN apt-get install -y gedit net-tools

#Build Libreoffice - takes about an hour (7 Core xeon 1230v2, 16GB, SSD)
apt-get install -y libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev wget curl git
RUN apt-get build-dep libreoffice -y
RUN git clone git://anongit.freedesktop.org/libreoffice/core libreoffice
RUN cd libreoffice && ./autogen.sh --enable-gtk3 --without-java --without-doxygen &&  make


# Set up VNC
RUN apt-get install -y expect
RUN mkdir -p /root/.vnc
ADD xstartup /root/.vnc/xstartup
RUN chmod 755 /root/.vnc/xstartup
ADD spawn-desktop.sh /usr/local/etc/spawn-desktop.sh
RUN chmod +x /usr/local/etc/spawn-desktop.sh
ADD start-vnc-expect-script.sh /usr/local/etc/start-vnc-expect-script.sh
RUN chmod +x /usr/local/etc/start-vnc-expect-script.sh
ADD vnc.conf /etc/vnc.conf

#Install noVNC
RUN apt-get install -y git python-numpy
RUN cd / && git clone git://github.com/kanaka/noVNC && cp noVNC/vnc_auto.html noVNC/index.html

ENV HOME /root


# Define mountable directories.
VOLUME ["/data"]

# Define working directory.
WORKDIR /data

# Define default command.
CMD bash -C '/usr/local/etc/spawn-desktop.sh';'bash'
#CMD "bash"

# Expose ports.
#EXPOSE 5901
EXPOSE 80