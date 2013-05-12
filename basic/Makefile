PROJECT=hello

.PHONY: all clean

all: build

src/dist/setup:
	mirari configure $(B)

build: src/dist/setup
	mirari build $(B)

run:
	./mir-$(PROJECT)

clean:
	mirari clean
