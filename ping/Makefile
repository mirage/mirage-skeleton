include ../Makefile.config

.PHONY: all clean

all: build
	@

src/dist/setup:
	mirari configure --no-install $(BACKEND)

build: src/dist/setup
	mirari build $(BACKEND)

run:
	mirari run $(BACKEND)

clean:
	mirari clean
	rm -f pinglog*
