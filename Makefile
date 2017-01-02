-include Makefile.config

TESTS = console network stackv4 ethifv4 io_page static_website dns \
        conduit_server static_website_tls http-fetch \
        dhcp hello block kv_ro_crunch kv_ro netif-forward ping6

ifdef WITH_TRACING
TESTS += tracing
endif

CONFIGS = $(patsubst %, %-configure, $(TESTS))
BUILDS  = $(patsubst %, %-build,     $(TESTS))
TESTRUN = $(patsubst %, %-testrun,   $(TESTS))
CLEANS  = $(patsubst %, %-clean,     $(TESTS))

all: build

configure: $(CONFIGS)
build: $(BUILDS)
testrun: $(TESTRUN)
clean: $(CLEANS)

## lwt special cased
lwt: lwt-clean lwt-build
lwt-configure:
	@ :

lwt-build:
	$(MAKE) -C lwt build

lwt-clean:
	$(MAKE) -C lwt clean

lwt-testrun:
	@ :

## default tests
%-configure:
	cd $* && $(MIRAGE) configure -t $(MODE) $(MIRAGE_FLAGS)

%-build: %-configure
	-cp Makefile.user $*
	cd $* && $(MAKE) depend && $(MAKE)

%-clean:
	-cd $* && $(MAKE) clean
	-$(RM) $*/Makefile.user

%-testrun:
	$(SUDO) sh ./testrun.sh $*
