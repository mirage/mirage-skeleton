include Makefile.config

SUBDIRS=basic block_perf dns io_page ping static_website suspend tcp

clean: $(patsubst %,clean-%,$(SUBDIRS))

clean-%:
	if [ "$*" != "dns" -a "$*" != "static_website" ]; then \
		if [ ! -r $*/Makefile ]; then \
			cd $* && mirari configure $(BACKEND) && cd .. ; \
		fi ; \
		$(MAKE) -C $* clean ;\
		$(RM) $*/myocamlbuild.ml $*/Makefile ;\
	fi
