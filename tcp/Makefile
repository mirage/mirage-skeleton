include ../Makefile.config

PROJECT=iperf_self

.PHONY: all clean

all: build
	@

src/dist/setup:
	mirari configure $(BACKEND)

build: src/dist/setup
	mirari build $(BACKEND)

clean:
	mirari clean
	rm -f pinglog*
