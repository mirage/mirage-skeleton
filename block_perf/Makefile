include ../Makefile.config

.PHONY: all clean

all: build
	@

dist/setup:
	mirari configure $(BACKEND)

build: dist/setup
	mirari build $(BACKEND)

clean:
	mirari clean
