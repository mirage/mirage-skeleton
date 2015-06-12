-include Makefile.config

TESTS = console network stackv4 ethifv4 io_page lwt ping static_website dns \
        conduit_server conduit_server_manual static_website_tls http-fetch

CONFIGS = $(patsubst %, %-configure, $(TESTS))
BUILDS  = $(patsubst %, %-build,     $(TESTS))
RUNS    = $(patsubst %, %-run,       $(TESTS))
CLEANS  = $(patsubst %, %-clean,     $(TESTS))

all: build

configure: $(CONFIGS)
build: $(BUILDS) lwt-build
run: $(RUNS)
clean: $(CLEANS) lwt-clean

## lwt special cased
lwt: lwt-clean lwt-build
lwt-configure:
	@ :

lwt-build:
	$(MAKE) -C lwt build

lwt-clean:
	$(MAKE) -C lwt clean

## default tests
%-configure:
	$(MIRAGE) configure $*/config.ml --$(MODE) $(FLAGS)

%-build: %-configure
	cd $* && $(MAKE)

%-clean:
	$(MIRAGE) clean $*/config.ml
	$(RM) log

## create raw device for block_test
UNAME_S := $(shell uname -s)
block_test/disk.raw:
	[ "$(PLATFORM)" = "Darwin" ] &&						\
		hdiutil create -sectors 12 -layout NONE disk.raw && \
		mv disk.raw.dmg block_test/disk.raw
