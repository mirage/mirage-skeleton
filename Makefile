-include Makefile.config

TESTS = console network stackv4 ethifv4 io_page lwt ping static_website dns

CONFIGS = $(patsubst %, %-configure, $(TESTS))
DEPENDS = $(patsubst %, %-depend,    $(TESTS))
BUILDS  = $(patsubst %, %-build,     $(TESTS))
RUNS    = $(patsubst %, %-run,       $(TESTS))
CLEANS  = $(patsubst %, %-clean,     $(TESTS))

all:
	@echo Run:
	@echo make configure
	@echo make depend
	@echo make build

configure: $(CONFIGS)
depend: $(DEPENDS)
build: $(BUILDS) lwt-build
run: $(RUNS)
clean: $(CLEANS) lwt-clean

## lwt special cased
lwt: lwt-clean lwt-build
lwt-configure:
	@ :

lwt-depend:
	@ :

lwt-build:
	$(MAKE) -C lwt build

lwt-clean:
	$(MAKE) -C lwt clean

## default tests
%-configure:
	$(MIRAGE) configure $*/config.ml --$(MODE) $(FLAGS)
	cd $* && $(MAKE) depend

%-depend:
	cd $* && $(MAKE) depend

%-build:
	cd $* && $(MAKE)

%-run:
	@grep "PKGS.*=.*mirage-xen" $*/Makefile ;\
	if [ $$? -eq 0 ]; then \
		echo "use your preferred toolchain to boot your unikernel" ;\
	else \
		echo execute the output as a POSIX process by ;\
		echo $$ sudo $(MIRAGE) run $*/config.ml ;\
	fi

%-clean:
	$(MIRAGE) clean $*/config.ml
	$(RM) log

## create raw device for block_test
UNAME_S := $(shell uname -s)
block_test/disk.raw:
	[ "$(PLATFORM)" = "Darwin" ] &&						\
		hdiutil create -sectors 12 -layout NONE disk.raw && \
		mv disk.raw.dmg block_test/disk.raw
