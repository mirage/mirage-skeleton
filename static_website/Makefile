include ../Makefile.config

.PHONY: all clean

all: build
	@

src/dist/setup:
	cd src && mirari configure $(BACKEND)

build: src/dist/setup
	cd src && mirari build $(BACKEND)

run:
	cd src && mirari run $(BACKEND)

clean:
	cd src && mirari clean
