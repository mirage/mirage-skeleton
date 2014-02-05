MIRAGE  = mirage
MODE   ?= unix
FLAGS  ?=

TESTS = console network stackv4 ethifv4

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

%-run:
	$(MIRAGE) run $*/config.ml

%-clean:
	$(MIRAGE) clean $*/config.ml

## create raw device for block_test
UNAME_S := $(shell uname -s)
block_test/disk.raw:
	[ "$(PLATFORM)" = "Darwin" ] &&						\
		hdiutil create -sectors 12 -layout NONE disk.raw && \
		mv disk.raw.dmg block_test/disk.raw
