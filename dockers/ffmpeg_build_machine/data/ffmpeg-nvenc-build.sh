#!/bin/sh -e

# This script will compile and install a static ffmpeg build with support for nvenc un ubuntu.

# Based on: https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
# Based on: https://gist.github.com/Brainiarc7/3f7695ac2a0905b05c5b
# Rewritten here: https://github.com/ilyaevseev/ffmpeg-build-static/

# Globals
NASM_VERSION="2.14rc15"
YASM_VERSION="1.3.0"
LAME_VERSION="3.100"
OPUS_VERSION="1.2.1"
LASS_VERSION="0.14.0"
CUDA_DIR="/usr/local/cuda-10.1"
WORK_DIR="/ffmpeg-build-static-sources"
DEST_DIR="/ffmpeg-build-static-binaries"

mkdir -p "$WORK_DIR" "$DEST_DIR" "$DEST_DIR/bin"

export PATH="$DEST_DIR/bin:$PATH"

####  Routines  ################################################

Wget() { wget -cN "$@"; }

Make() { make -j$(nproc); make "$@"; }

Clone() {
    local DIR="$(basename "$1" .git)"

    cd "$WORK_DIR/"
    test -d "$DIR/.git" || git clone --depth=1 "$@"

    cd "$DIR"
    git pull
}

installNvidiaSDK() {
    echo "Installing the nVidia NVENC SDK."
    Clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
    make
    make install PREFIX="$DEST_DIR"
}

compileNasm() {
    echo "Compiling nasm"
    cd "$WORK_DIR/"
    Wget "http://www.nasm.us/pub/nasm/releasebuilds/$NASM_VERSION/nasm-$NASM_VERSION.tar.gz"
    tar xzvf "nasm-$NASM_VERSION.tar.gz"
    cd "nasm-$NASM_VERSION"
    ./configure --prefix="$DEST_DIR" --bindir="$DEST_DIR/bin"
    Make install distclean
}

compileYasm() {
    echo "Compiling yasm"
    cd "$WORK_DIR/"
    Wget "http://www.tortall.net/projects/yasm/releases/yasm-$YASM_VERSION.tar.gz"
    tar xzvf "yasm-$YASM_VERSION.tar.gz"
    cd "yasm-$YASM_VERSION/"
    ./configure --prefix="$DEST_DIR" --bindir="$DEST_DIR/bin"
    Make install distclean
}

compileLibX264() {
    echo "Compiling libx264"
    cd "$WORK_DIR/"
    Wget http://download.videolan.org/pub/x264/snapshots/last_x264.tar.bz2
    rm -rf x264-snapshot*/ || :
    tar xjvf last_x264.tar.bz2
    cd x264-snapshot*
    ./configure --prefix="$DEST_DIR" --bindir="$DEST_DIR/bin" --enable-static --enable-pic
    Make install distclean
}

compileLibX265() {
    if cd "$WORK_DIR/x265/"; then
        hg pull
        hg update
    else
        cd "$WORK_DIR/"
        hg clone https://bitbucket.org/multicoreware/x265
    fi

    cd "$WORK_DIR/x265/build/linux/"
    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$DEST_DIR" -DENABLE_SHARED:bool=off ../../source
    Make install

    # forward declaration should not be used without struct keyword!
    sed -i.orig -e 's,^ *x265_param\* zoneParam,struct x265_param* zoneParam,' "$DEST_DIR/include/x265.h"
}

compileLibAom() {
    echo "Compiling libaom"
    Clone https://aomedia.googlesource.com/aom
    mkdir -p ../aom_build
    cd ../aom_build
    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$DEST_DIR" -DENABLE_SHARED=off -DENABLE_NASM=on ../aom
    Make install
}

compileLibfdkcc() {
    echo "Compiling libfdk-cc"
    cd "$WORK_DIR/"
    Wget -O fdk-aac.zip https://github.com/mstorsjo/fdk-aac/zipball/master
    unzip -o fdk-aac.zip
    cd mstorsjo-fdk-aac*
    autoreconf -fiv
    ./configure --prefix="$DEST_DIR" --disable-shared
    Make install distclean
}

compileLibMP3Lame() {
    echo "Compiling libmp3lame"
    cd "$WORK_DIR/"
    Wget "http://downloads.sourceforge.net/project/lame/lame/$LAME_VERSION/lame-$LAME_VERSION.tar.gz"
    tar xzvf "lame-$LAME_VERSION.tar.gz"
    cd "lame-$LAME_VERSION"
    ./configure --prefix="$DEST_DIR" --enable-nasm --disable-shared
    Make install distclean
}

compileLibOpus() {
    echo "Compiling libopus"
    cd "$WORK_DIR/"
    Wget "http://downloads.xiph.org/releases/opus/opus-$OPUS_VERSION.tar.gz"
    tar xzvf "opus-$OPUS_VERSION.tar.gz"
    cd "opus-$OPUS_VERSION"
    ./configure --prefix="$DEST_DIR" --disable-shared
    Make install distclean
}

compileLibVpx() {
    echo "Compiling libvpx"
    Clone https://chromium.googlesource.com/webm/libvpx
    ./configure --prefix="$DEST_DIR" --disable-examples --enable-runtime-cpu-detect --enable-vp9 --enable-vp8 \
    --enable-postproc --enable-vp9-postproc --enable-multi-res-encoding --enable-webm-io --enable-better-hw-compatibility \
    --enable-vp9-highbitdepth --enable-onthefly-bitpacking --enable-realtime-only \
    --cpu=native --as=nasm --disable-docs
    Make install clean
}

compileLibAss() {
    echo "Compiling libass"
    cd "$WORK_DIR/"
    Wget "https://github.com/libass/libass/releases/download/$LASS_VERSION/libass-$LASS_VERSION.tar.xz"
    tar Jxvf "libass-$LASS_VERSION.tar.xz"
    cd "libass-$LASS_VERSION"
    autoreconf -fiv
    ./configure --prefix="$DEST_DIR" --disable-shared --disable-require-system-font-provider
    Make install distclean
}

compileFfmpeg() {
    echo "Compiling ffmpeg"
    Clone https://github.com/FFmpeg/FFmpeg -b master

    export PATH="$CUDA_DIR/bin:$PATH"
    PKG_CONFIG_PATH="$DEST_DIR/lib/pkgconfig:$DEST_DIR/lib64/pkgconfig" \
    ./configure \
      --pkg-config-flags="--static" \
      --prefix="$DEST_DIR" \
      --bindir="$DEST_DIR/bin" \
      --extra-cflags="-I $DEST_DIR/include -I $CUDA_DIR/include/" \
      --extra-ldflags="-L $DEST_DIR/lib -L $CUDA_DIR/lib64/" \
      --extra-libs="-lpthread" \
      --enable-cuda \
      --enable-cuda-nvcc \
      --enable-cuvid \
      --enable-nvenc \
      --enable-gpl \
      --enable-libass \
      --enable-libfdk-aac \
      --enable-vaapi \
      --enable-libfreetype \
      --enable-libmp3lame \
      --enable-libopus \
      --enable-libtheora \
      --enable-libvorbis \
      --enable-libvpx \
      --enable-libx264 \
      --enable-libx265 \
      --enable-nonfree \
      --enable-libaom
    # TODO --enable-libnpp
    # current state is asking a linnpp**.so.10 on new machine
    Make install distclean
    hash -r
}

installNvidiaSDK

compileNasm
compileYasm
compileLibX264
compileLibX265
compileLibAom
compileLibVpx
compileLibfdkcc
compileLibMP3Lame
compileLibOpus
compileLibAss
compileFfmpeg

