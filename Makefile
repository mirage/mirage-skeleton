include Makefile.config

COMMON_SUBDIRS=basic basic_net io_page ping tcp static_website # dns

XEN_ONLY_SUBDIRS=block_perf block_test suspend

ifeq ($(strip $(PLATFORM)),mirage-xen)
		SUBDIRS := $(COMMON_SUBDIRS) $(XEN_ONLY_SUBDIRS)
else
		SUBDIRS := $(COMMON_SUBDIRS)
endif

build: $(patsubst %,build-%,$(SUBDIRS))
clean: $(patsubst %,clean-%,$(SUBDIRS))
configure: $(patsubst %,configure-%,$(SUBDIRS))

configure-lwt:
	$(MAKE) -C lwt configure

build-lwt:
	$(MAKE) -C lwt build

clean-lwt:
	$(MAKE) -C lwt clean

configure-dns:
	$(MAKE) -C dns configure

build-dns:
	$(MAKE) -C dns build

clean-dns:
	$(MAKE) -C dns clean

configure-static_website:
	@echo "\n### static_website: configure"
	$(MAKE) -C static_website configure

build-static_website: configure-static_website
	@echo "\n### static_website: build"
	$(MAKE) -C static_website build

clean-static_website:
	@echo "\n### static_website: clean"
	$(MAKE) -C static_website clean

build-%: configure-%
	cd $* && mirari build $(BACKEND)

configure-%:
	@echo "\n### $*: configure"
	cd $* && mirari configure $(BACKEND)

clean-%:
	@echo "\n### $*: clean"
	if [ ! -r $*/Makefile ]; then \
		$(MAKE) configure-$* ;\
	fi ; \
	cd $* && mirari clean ;\
	$(RM) $*/myocamlbuild.ml $*/Makefile $*/*.xl main.native main.ml

run-%:
	cd $* && mirari run $(BACKEND)
