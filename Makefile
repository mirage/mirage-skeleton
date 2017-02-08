-include Makefile.config

TESTS = \
  tutorial/noop \
  tutorial/noop-functor \
  tutorial/hello \
  tutorial/hello-key \
  tutorial/lwt/echo_server \
  tutorial/lwt/heads1 \
  tutorial/lwt/heads2 \
  tutorial/lwt/timeout1 \
  tutorial/lwt/timeout2 \
  device-usage/block \
  device-usage/clock \
  device-usage/conduit_server \
  device-usage/console \
  device-usage/kv_ro \
  device-usage/network \
  device-usage/ping6 \
  applications/dhcp \
  applications/dns \
  applications/static_website_tls

ifdef WITH_TRACING
TESTS += device-usage/tracing
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
