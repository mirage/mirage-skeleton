.PHONY: all clean

XEN?= $(shell if ocamlfind query lwt.unix >/dev/null 2>&1; then echo ""; else echo "--xen"; fi)

all: build
	@

dist/setup:
	mirari configure block_perf.conf $(XEN) $(CONF_FLAGS)

build: dist/setup
	mirari build block_perf.conf $(XEN)

clean:
	obuild clean
