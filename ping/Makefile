PROJECT=ping

.PHONY: all clean

XEN?= $(shell if ocamlfind query lwt.unix >/dev/null 2>&1; then echo ""; else echo "--xen"; fi)

all: build
	@

src/dist/setup:
	mirari configure $(PROJECT).conf $(XEN) $(CONF_FLAGS)

build: src/dist/setup
	mirari build $(PROJECT).conf $(XEN)

run:
	./mir-$(PROJECT)

clean:
	obuild clean
	rm -f main.ml main.obuild mir-$(PROJECT)* pinglog*
