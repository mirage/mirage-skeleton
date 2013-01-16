ifeq ($(MIRAGE_OS),xen)
FLAGS=--enable-xen --disable-unix
else
FLAGS=--enable-unix --disable-xen
endif

all: 
	ocaml setup.ml -configure $(FLAGS)
	ocaml setup.ml -build -classic-display

.PHONY:clean
clean:
	ocamlbuild -clean
	rm -f setup.log setup.data
