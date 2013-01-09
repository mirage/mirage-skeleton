#!/bin/sh -e
rm -rf _build
ocaml setup.ml -configure --enable-xen
ocaml setup.ml -build -j 8
