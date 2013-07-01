include ../Makefile.config

PROJECT=hello

.PHONY: all clean

all: build

src/dist/setup:
	mirari configure $(BACKEND)

build: src/dist/setup
	mirari build $(BACKEND)

run:
	mirari run $(BACKEND)

clean:
	mirari clean
