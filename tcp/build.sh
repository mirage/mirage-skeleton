#!/bin/sh -e
rm -rf _build setup.data
ocaml setup.ml -configure --enable-xen
ocaml setup.ml -build -j 8
