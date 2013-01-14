#!/bin/sh

./gen_crunch.sh
ocamlbuild main.native
V=9.7.3
curl -OL  http://ftp.isc.org/isc/bind9/${V}/bind-${V}.tar.gz
tar -zxvf bind-${V}.tar.gz
cd bind-${V}
patch -p1 < ../osx.diff
cd contrib/queryperf
./configure --with-libtool && make
cp queryperf ../../..
cd ../../..
rm -rf bind-${V}
