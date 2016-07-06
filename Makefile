-include Makefile.config

TESTS = console network stackv4 ethifv4 io_page lwt ping static_website dns \
        conduit_server conduit_server_manual static_website_tls http-fetch \
        dhcp hello block kv_ro_crunch kv_ro netif-forward ping6

ifdef WITH_TRACING
TESTS += tracing
endif

BUILDS  = $(patsubst %, %-build,     $(TESTS))
TESTRUN = $(patsubst %, %-testrun,   $(TESTS))
CLEANS  = $(patsubst %, %-clean,     $(TESTS))

all: build

build: $(BUILDS)
testrun: $(TESTRUN)
clean: $(CLEANS)

## lwt special cased
lwt-build:
	$(MAKE) -C lwt build

lwt-clean:
	$(MAKE) -C lwt clean

lwt-testrun:
	@ :

## default tests
%-build:
	$(MIRAGE) configure -f $*/config.ml --$(MODE) $(MIRAGE_FLAGS)
	cd $* && $(MAKE)

%-clean:
	$(MIRAGE) clean -f $*/config.ml
	cd $* && $(RM) log static*.mli

%-testrun:
	$(SUDO) sh ./testrun.sh $*
