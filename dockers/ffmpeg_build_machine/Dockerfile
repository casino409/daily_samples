FROM ubuntu:18.04

MAINTAINER Boril Marinov

# CUDA installation
RUN apt-get update && apt-get -qq -y install wget gnupg
RUN wget -q http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.1.168-1_amd64.deb
RUN dpkg -i cuda-repo-ubuntu1804_10.1.168-1_amd64.deb
RUN rm cuda-repo-ubuntu1804_10.1.168-1_amd64.deb
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub

RUN apt-get update && apt-get -qq -y install \
  autoconf automake libtool patch make cmake bzip2 unzip wget git mercurial \
  build-essential pkg-config texi2html software-properties-common \
  fontconfig fontconfig-config linux-headers-$(uname -r) \
  cuda-command-line-tools-10-1 cuda-npp-10-1 cuda-npp-dev-10-1 \
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

ADD ffmpeg-nvenc-build.sh /build.sh
RUN chmod 700 build.sh
RUN mkdir /result

CMD bash -c '/build.sh && cp -Rp ffmpeg-build-static-binaries/bin /result && echo Done'

