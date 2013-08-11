include Makefile.config

SUBDIRS=basic block_perf dns io_page ping static_website suspend tcp

clean: $(patsubst %,clean-%,$(SUBDIRS))
configure: $(patsubst %,configure-%,$(SUBDIRS))

configure-static_website:
	@echo "\n###static_website: configure"
	$(MAKE) -C static_website configure

configure-dns:
	@echo "\n### dns: configure"
	@echo "*** dns: no mirari conf file"

configure-%:
	@echo "\n### $*: configure"
	cd $* && mirari configure $(BACKEND)

clean-static_website:
	@echo "\n### static_website: clean"
	$(MAKE) -C static_website clean

clean-dns:
	@echo "\n### dns: clean"
	cd dns && ./clean.sh

clean-%: 
	@echo "\n### $*: clean"
	if [ ! -r $*/Makefile ]; then \
		$(MAKE) configure-$* ;\
	fi ; \
	$(MAKE) -C $* clean ;\
	$(RM) $*/myocamlbuild.ml $*/Makefile
