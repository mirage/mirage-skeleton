include Makefile.config

COMMON_SUBDIRS=basic basic_net io_page ping tcp static_website #dns

XEN_ONLY_SUBDIRS=block_perf suspend

ifeq ($(strip $(PLATFORM)),mirage-xen)
        SUBDIRS := $(COMMON_SUBDIRS) $(XEN_ONLY_SUBDIRS)
else
        SUBDIRS := $(COMMON_SUBDIRS)
endif

build: $(patsubst %,build-%,$(SUBDIRS))
clean: $(patsubst %,clean-%,$(SUBDIRS))
configure: $(patsubst %,configure-%,$(SUBDIRS))

build-static_website: configure-static_website
	@echo "\n### static_website: build"
	$(MAKE) -C static_website build

build-%: configure-%
	cd $* && mirari build $(BACKEND)

configure-static_website:
	@echo "\n### static_website: configure"
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
	cd $* && mirari clean ;\
	$(RM) $*/myocamlbuild.ml $*/Makefile $*/*.xl

run-%:
	cd $* && mirari run $(BACKEND)

