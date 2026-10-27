#!/bin/sh
set -eu
export MACOSX_DEPLOYMENT_TARGET=10.4
SDK=/Developer/SDKs/MacOSX10.4u.sdk
export CC=/usr/bin/gcc CXX=/usr/bin/g++ OBJCXX=/usr/bin/g++
export CFLAGS="-O1 -g -arch ppc -isysroot $SDK"
export CXXFLAGS="-O1 -g -std=c++98 -arch ppc -isysroot $SDK"
export LDFLAGS=""
./configure PTHREAD_CFLAGS="" PTHREAD_LIBS="-lpthread" --enable-headless --disable-fortify --disable-clientupdate --enable-embedded-cryptopp --prefix="$HOME/Library/UrBackupTigerLab" > tiger-configure.log 2>&1 || { tail -60 tiger-configure.log; exit 1; }
/usr/bin/make -j2 urbackupclientbackend urbackupclientctl > tiger-make.log 2>&1 || { tail -100 tiger-make.log; exit 1; }
/usr/bin/file urbackupclientbackend urbackupclientctl
