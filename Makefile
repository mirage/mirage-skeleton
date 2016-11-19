-include Makefile.config

TESTS = console network stackv4 ethifv4 io_page lwt static_website dns \
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
build: $(BUILDS) lwt-build
testrun: $(TESTRUN)
clean: $(CLEANS) lwt-clean

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
	$(MIRAGE) configure -f $*/config.ml -t $(MODE) $(MIRAGE_FLAGS)

%-build: %-configure
	cd $* && $(MAKE) depend && $(MAKE)

%-clean:
	make -C $* clean
	$(RM) log

%-testrun:
	$(SUDO) sh ./testrun.sh $*
