# Deprecated - [See new build script here](https://github.com/Zackptg5/Curl-and-Aria2-For-Android)

# aria2-android

Compiles aria2 (and dependencies ) for Android

Note that it looks for /system/etc/security/ca-certificates.crt so you'll need to grab you're own for https support

## Issues

Static linked doens't resolve url names - use "--async-dns" flag
Like with curl, static link binary must be run as root or dns won't resolve on android Q+

## Prerequisites

Linux (I've tested this on Manjaro)

autoconf,libtool

## Download

If you do not want to compile them yourself, you can download pre-compiled static binaries from [Cross-Compiled-Binaries-Android](https://github.com/Zackptg5/Cross-Compiled-Binaries-Android).<br/>
Doing your own compilation is recommended, since the pre-compiled binary can become outdated soon.<br/>

Update git submodules to compile newer versions of the libraries:
```
cd submodule_directory
git checkout LATEST_STABLE_TAG
cd ..
```

## Usage

```
bash
git clone --recurse-submodules https://github.com/Zackptg5/aria2-android.git
```
Optional: Update git submodules to compile newer versions of the libraries:
```
cd submodule_directory
git checkout LATEST_STABLE_TAG
cd ..
```
Edit build.sh script:
```
NDK=android_ndk_version_you_want_to_use
export HOST_TAG=see_this_table_for_info # https://developer.android.com/ndk/guides/other_build_systems#overview
export MIN_SDK_VERSION=21 # or any version you want (dependent on the ndk version - keep 21 if in doubt)
export STATIC=false #Change to true for static binary - note that there will be less features then with dynamic
export ARCH="arm arm64 x86 x64" # Remove ones you don't want to compile
```
Run build script
```
chmod +x ./build.sh
./build.sh
```
All compiled libs are located in `build` directory.
