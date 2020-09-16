#!/bin/bash
MODULES="zlib openssl libssh2 libexpat c-ares aria2"

patch_file() {
  echo "Applying patch"
  local DEST=$(basename $1)
  cp -f $1 $DEST
  patch -p0 -i $DEST
  [ $? -ne 0 ] && { echo "Patching failed! Did you verify line numbers? See README for more info"; exit 1; }
}

for BIN in $MODULES; do
  cd $BIN || { echo "$BIN doesn't exist!"; exit 1; }

  for i in $ARCH; do
    case $i in
      "arm64"|"aarch64") export TARGET_HOST=aarch64-linux-android; LARCH=arm64-v8a; OSARCH=android-arm64;;
      "arm"|"armeabi"|"armeabi_v7a") export TARGET_HOST=armv7a-linux-androideabi; LARCH=armeabi-v7a; OSARCH=android-arm;;
      "x86"|"i686") export TARGET_HOST=i686-linux-android; LARCH=x86; OSARCH=android-x86;;
      "x64"|"x86_64") export TARGET_HOST=x86_64-linux-android; LARCH=x86_64; OSARCH=android-x86_64;;
      *) echo "Invalid ARCH: $i!"; exit 1;;
    esac

    [ "$LARCH" == "armeabi-v7a" ] && export TARGET_HOST=arm-linux-androideabi
    export AR=$TOOLCHAIN/bin/$TARGET_HOST-ar
    export AS=$TOOLCHAIN/bin/$TARGET_HOST-as
    export LD=$TOOLCHAIN/bin/$TARGET_HOST-ld
    export RANLIB=$TOOLCHAIN/bin/$TARGET_HOST-ranlib
    export STRIP=$TOOLCHAIN/bin/$TARGET_HOST-strip
    [ "$LARCH" == "armeabi-v7a" ] && export TARGET_HOST=armv7a-linux-androideabi
    export CC=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang
    export CXX=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang++
    export GCC=$TOOLCHAIN/bin/$TARGET_HOST-gcc
    export GXX=$TOOLCHAIN/bin/$TARGET_HOST-g++
    ln -sf $CC $GCC
    ln -sf $CXX $GXX

    export PREFIX=$PREFIXORIG/$LARCH
    export CFLAGS="$CFLAGSORIG" LDFLAGS="$LDFLAGSORIG"
    mkdir -p $PREFIX
    git clean -dfx; git reset --hard

    case $BIN in
      "zlib")
        ./configure --prefix=$PREFIX
                    ;;
      "openssl") 
        if $STATIC; then
          sed -i "/#if \!defined(_WIN32)/,/#endif/d" fuzz/client.c
          sed -i "/#if \!defined(_WIN32)/,/#endif/d" fuzz/server.c
        fi
        ./Configure $OSARCH no-shared zlib \
                    -D__ANDROID_API__=$MIN_SDK_VERSION \
                    --prefix=$PREFIX \
                    --with-zlib-include=$PREFIX/include \
                    --with-zlib-lib=$PREFIX/lib
                    ;;
      "libssh2")
        ./buildconf
        ./configure --host=$TARGET_HOST \
                    --target=$TARGET_HOST \
                    --prefix=$PREFIX \
                    --enable-hidden-symbols \
                    --disable-examples-build \
                    --with-crypto=openssl \
                    --with-libssl-prefix=$PREFIX \
                    --with-libz \
                    --with-libz-prefix=$PREFIX
                    ;;
      "libexpat")
        cd expat
        ./buildconf.sh
        ./configure --host=$TARGET_HOST \
                    --target=$TARGET_HOST \
                    --prefix=$PREFIX \
                    --disable-shared
                    ;;
      "c-ares")
        ./buildconf
        ./configure --host=$TARGET_HOST \
                    --target=$TARGET_HOST \
                    --prefix=$PREFIX \
                    --disable-shared
                    ;;
      "aria2")
        autoreconf -i
        if $STATIC; then
          patch_file $DIR/timegm.patch # Remove timegm function - already declared in ndk
          # Pthread inside ndk's libc rather than separate, create empty one to skirt around errors - https://stackoverflow.com/questions/57289494/ndk-r20-ld-ld-error-cannot-find-lpthread
          [ "$LARCH" == "armeabi-v7a" ] && export TARGET_HOST=arm-linux-androideabi
          $AR cr $TOOLCHAIN/sysroot/usr/lib/$TARGET_HOST/libpthread.a
          $AR cr $TOOLCHAIN/sysroot/usr/lib/$TARGET_HOST/librt.a
          [ "$LARCH" == "armeabi-v7a" ] && export TARGET_HOST=armv7a-linux-androideabi
          ./configure --host=$TARGET_HOST \
                      --target=$TARGET_HOST \
                      --prefix=$PREFIX \
                      --disable-nls \
                      --without-gnutls \
                      --with-openssl \
                      --without-sqlite3 \
                      --without-libxml2 \
                      --with-libexpat \
                      --with-libcares \
                      --with-libz \
                      --with-libssh2 \
                      --with-ca-bundle='/system/etc/security/ca-certificates.crt' \
                      ARIA2_STATIC=yes \
                      CXXFLAGS="$CFLAGS -g" \
                      CFLAGS="$CFLAGS -I$PREFIX/include" \
                      LDFLAGS="$LDFLAGS -L$PREFIX/lib -static-libstdc++" \
                      PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig"
        else
          ./configure --host=$TARGET_HOST \
                      --target=$TARGET_HOST \
                      --prefix=$PREFIX \
                      --build=`dpkg-architecture -qDEB_BUILD_GNU_TYPE` \
                      --disable-nls \
                      --without-gnutls \
                      --with-openssl \
                      --without-sqlite3 \
                      --without-libxml2 \
                      --with-libexpat \
                      --with-libcares \
                      --with-libz \
                      --with-libssh2 \
                      --with-ca-bundle='/system/etc/security/ca-certificates.crt' \
                      CXXFLAGS="$CFLAGS -g" \
                      CFLAGS="$CFLAGS -I$PREFIX/include" \
                      CPPFLAGS="-fPIE" \
                      LDFLAGS="$LDFLAGS -fPIE -pie -L$PREFIX/lib -static-libstdc++" \
                      PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig"
        fi
        ;;
    esac
    make -j$JOBS
    [ "$BIN" == "openssl" ] && make install_sw || make install
    cd $DIR/$BIN
  done
  cd $DIR
done
echo -e "\nOutput can be found in $PREFIX\n"
