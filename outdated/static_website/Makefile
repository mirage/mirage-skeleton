include ../Makefile.config

clean:
	if [ ! -r src/Makefile ]; then \
		$(MAKE) configure ;\
	fi ;\
        cd src && mirari clean

configure:
	cd src && mirari configure $(BACKEND)

build:
	cd src && mirari build $(BACKEND)

run:
	cd src && mirari run $(BACKEND)
