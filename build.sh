#!/bin/bash

NDK=r20b
export ANDROID_NDK_HOME=$PWD/android-ndk-$NDK
export HOST_TAG=linux-x86_64
export MIN_SDK_VERSION=21
export STATIC=false
export ARCH="arm arm64 x86 x64"

if [ -f /proc/cpuinfo ]; then
  export JOBS=$(grep flags /proc/cpuinfo | wc -l)
elif [ ! -z $(which sysctl) ]; then
  export JOBS=$(sysctl -n hw.ncpu)
else
  export JOBS=2
fi

# Set up Android NDK
[ -f "android-ndk-$NDK-$HOST_TAG.zip" ] || wget https://dl.google.com/android/repository/android-ndk-$NDK-$HOST_TAG.zip
[ -d "android-ndk-$NDK" ] || unzip -qo android-ndk-$NDK-$HOST_TAG.zip
export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG
export PATH=$TOOLCHAIN/bin:$PATH

export DIR=$PWD
$STATIC && export PREFIX=$DIR/build-static || export PREFIX=$DIR/build-dynamic
export PREFIXORIG=$PREFIX
$STATIC && CFLAGS="--static " LDFLAGS="--static "
export CFLAGS="$CFLAGS-Os"
export LDFLAGS="$LDFLAGS-Wl,-s"
export CFLAGSORIG="$CFLAGS"
export LDFLAGSORIG="$LDFLAGS"

chmod +x build_modules.sh
./build_modules.sh
