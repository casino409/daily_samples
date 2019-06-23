FROM ubuntu:18.04

MAINTAINER Boril Marinov

RUN apt-get update && apt-get -qq -y install \
  autoconf automake libtool patch make cmake bzip2 unzip wget git mercurial \
  build-essential pkg-config texi2html software-properties-common \
  fontconfig fontconfig-config linux-headers-$(uname -r) \
  libfreetype6-dev \
  libgpac-dev \
  libsdl1.2-dev \
  libtheora-dev \
  libva-dev \
  libvdpau-dev \
  libvorbis-dev \
  libxcb1-dev \
  libxcb-shm0-dev \
  libxcb-xfixes0-dev \
  zlib1g-dev \
  libfribidi-dev \
  libfribidi0 \
  libfribidi-bin

ADD ffmpeg-build.sh /build.sh
RUN chmod 700 build.sh
RUN mkdir /result

CMD bash -c '/build.sh && cp -Rp ffmpeg-build-static-binaries/bin /result && echo Done'

