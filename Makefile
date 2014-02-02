MIRAGE  = mirage
MODE   ?= unix
FLAGS  ?=

## basic_net must run under "sudo" to access tap0 network device
COMMON_TESTS = console basic_block basic_net io_page ## ping tcp static_website # dns
XEN_TESTS    = ## block_perf suspend

ifeq ($(MODE),xen)
		TESTS := $(COMMON_TESTS) $(XEN_TESTS)
else
		TESTS := $(COMMON_TESTS)
endif

CONFIGS = $(patsubst %, %-configure, $(TESTS))
BUILDS  = $(patsubst %, %-build,     $(TESTS))
RUNS    = $(patsubst %, %-run,       $(TESTS))
CLEANS  = $(patsubst %, %-clean,     $(TESTS))

all: build

configure: $(CONFIGS)
build: $(BUILDS)
run: $(RUNS)
clean: $(CLEANS)

%-configure:
	$(MIRAGE) configure $*/config.ml --$(MODE) $(FLAGS)

%-build: %-configure
	$(MIRAGE) build $*/config.ml

%-run: %-build
	$(MIRAGE) run $*/config.ml

%-clean:
	$(MIRAGE) clean $*/config.ml

## create raw device for block_test
UNAME_S := $(shell uname -s)
block_test/disk.raw:
	[ "$(PLATFORM)" = "Darwin" ] &&						\
		hdiutil create -sectors 12 -layout NONE disk.raw && \
		mv disk.raw.dmg block_test/disk.raw
