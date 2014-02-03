#!/bin/sh

V=9.7.3
wget http://ftp.isc.org/isc/bind9/${V}/bind-${V}.tar.gz
tar -zxvf bind-${V}.tar.gz
cd bind-${V}/contrib/queryperf
./configure && make
cp queryperf ../../..
cd ../../..
rm -rf bind-${V}
