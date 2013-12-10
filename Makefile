MIRAGE = mirage
# MODE ?= xen
MODE   ?= unix
BFLAGS ?= #--no-opam

COMMON_TESTS = basic block_test ## basic_net io_page ping tcp static_website # dns
XEN_TESTS    = block_perf suspend

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
	$(MIRAGE) configure $*/config.ml $(BFLAGS) --$(MODE)

%-build: %-configure
	$(MIRAGE) build $*/config.ml

%-run: %-build
	$(MIRAGE) run $*/config.ml

%-clean:
	$(MIRAGE) clean $*/config.ml $(BFLAGS)
