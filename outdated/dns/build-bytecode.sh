#!/bin/sh

./gen_crunch.sh
ocamlbuild main.byte -lflags -ccopt,-custom,-ccopt,-lunixrun
