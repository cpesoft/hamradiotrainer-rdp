FROM phusion/baseimage:0.11
MAINTAINER Carsten Perthel <carsten@cpesoft.de>

# set proxy (uncomment and modify when needed)
#ENV http_proxy "http://user:password@proxy:port"
#ENV https_proxy "http://user:password@proxy:port"

# Ensure UTF-8 and correct locale
RUN \
  locale-gen de_DE.UTF-8 && \
  update-locale LANG=de_DE.UTF-8
ENV LANG       de_DE.UTF-8
ENV LANGUAGE   de_DE.UTF-8
ENV LC_ALL     de_DE.UTF-8

# Set timezone
ENV TZ Europe/Berlin

# set HOME
# see: https://github.com/phusion/baseimage-docker#environment-variables
RUN echo /root > /etc/container_environment/HOME
ENV HOME /root

# set other environment variables
ENV DEBIAN_FRONTEND noninteractive
# suppress all wine console logs
# you can set this to 'trace+all' to get all trace information
ENV WINEDEBUG=-all
ENV WINEPREFIX=/home/user/.wine

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

###############################################################################
# ADD PPAs
###############################################################################

# Update ubuntu base system
RUN \
  apt-get update && \
  apt-get upgrade -y -o Dpkg::Options::="--force-confold"

# Install basic packages (needed for ppa handling etc.)
RUN \
  apt-get install -y --no-install-recommends \
  curl \
  wget \
  apt-utils

# Add wine ppa
RUN \
    echo "deb https://dl.winehq.org/wine-builds/ubuntu $(lsb_release -c -s) main" | tee /etc/apt/sources.list.d/winehq.list && \
    wget --quiet -O - "https://dl.winehq.org/wine-builds/winehq.key"  | apt-key add -
# Enable i386 architecture for wine install
RUN \
    dpkg --add-architecture i386

# ###############################################################################
# # INSTALL PACKAGES
# ###############################################################################

RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends \
# essentials
  sudo \
  python-minimal \
  p7zip-full \
# GUI and desktop environment
  xorgxrdp \
  xrdp \
  openbox \
  xfce4-terminal \
  firefox \
# wine (stable version)
  winehq-stable \
  winetricks

# ###############################################################################
# # SYSTEM SETTINGS & CONFIG
# ###############################################################################

# Create user and group for rdp
RUN \
  groupadd tsusers && \
  useradd --create-home --groups tsusers,sudo --shell /bin/bash user && \
  echo user:user | chpasswd && \
  echo 'openbox-session' > /home/user/.xsession

# ###############################################################################
# # WINE SEETINGS & CONFIG
# ###############################################################################

# if mono and gecko gets not detected automatically and wine prompts to install them,
# you have to use the correct versions which correspond to the currently
# installed wine version
# to find out for which files wine is looking, start wine with:
# env WINEDEBUG=trace+all wine foo.exe
# and watch the logs
RUN \
  mkdir -p /opt/wine-stable/share/wine/mono && \
  wget http://dl.winehq.org/wine/wine-mono/4.7.5/wine-mono-4.7.5.msi -O /opt/wine-stable/share/wine/mono/wine-mono-4.7.5.msi
RUN \
  mkdir -p /opt/wine-stable/share/wine/gecko && \
  wget http://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86.msi -O /opt/wine-stable/share/wine/gecko/wine_gecko-2.47-x86.msi && \
  wget http://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86_64.msi -O /opt/wine-stable/share/wine/gecko/wine_gecko-2.47-x86_64.msi

# install fonts and enable font smoothing
USER user
RUN \
  winetricks corefonts && \
  winetricks tahoma && \
  winetricks fontsmooth=rgb

# ###############################################################################
# # HAMRADIOTRAINER
# ###############################################################################

# install hamradiotrainer
WORKDIR /tmp
RUN \
  wget http://www.hamradiotrainer.de/download/HamRadioTrainer-Portable-4.0.zip && \
  7z x /tmp/HamRadioTrainer-Portable-4.0.zip -o/home/user/HamRadioTrainer && \
  chown -R user:user /home/user/HamRadioTrainer

# ###############################################################################
# # CONFIGURE PHUSION/BASEIMAGE SETTINGS
# ###############################################################################

USER root
# integrate xrdp/xrdp-sesman in init system
RUN \
  mkdir -p /etc/service/xrdp && \
  mkdir -p /etc/service/xrdp-sesman && \
  mkdir -p /etc/my_init.d && \
  echo '#! /bin/sh \n/usr/sbin/xrdp --nodaemon' > /etc/service/xrdp/run && \
  echo '#! /bin/sh \n/usr/sbin/xrdp-sesman --nodaemon' > /etc/service/xrdp-sesman/run && \
  echo '#! /bin/sh \nchown -R user:user /home/user/HamRadioTrainer/user' > /etc/my_init.d/volume_permissions && \
  chmod +x /etc/service/xrdp/run && \
  chmod +x /etc/service/xrdp-sesman/run && \
  chmod +x /etc/my_init.d/volume_permissions

###############################################################################
# VOLUMES AND PORTS
###############################################################################

EXPOSE 3389 22

VOLUME ["/home/user/HamRadioTrainer/user"]

###############################################################################
# CLEAN UP
###############################################################################

# uninstall not needed packages, clean tmp dir and apt lists
#XXX
#RUN \
#  apt-get purge \
#  && apt-get clean \
#  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt

# unset proxy
ENV http_proxy ""
ENV https_proxy ""

###############################################################################
# END OF DOCKERFILE
###############################################################################
