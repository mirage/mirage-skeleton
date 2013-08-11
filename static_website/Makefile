include ../Makefile.config

clean:
	if [ ! -r src/Makefile ]; then \
		$(MAKE) configure ;\
	fi ;\
	$(MAKE) -C src clean
	$(RM) src/filesystem_static.ml src/Makefile src/myocamlbuild.ml

configure:
	cd src && mirari configure $(BACKEND)
