-include Makefile.config

BASE_TESTS = \
  tutorial/noop \
  tutorial/noop-functor \
  tutorial/hello \
  tutorial/hello-key \
  tutorial/lwt/echo_server \
  tutorial/lwt/heads1 \
  tutorial/lwt/heads2 \
  tutorial/lwt/timeout1 \
  tutorial/lwt/timeout2 \
  tutorial/lwt/echo_server \
  tutorial/app_info \
  device-usage/clock \
  device-usage/conduit_server \
  device-usage/console \
  device-usage/http-fetch \
  device-usage/kv_ro \
  device-usage/network \
  device-usage/ping6 \
	device-usage/pgx \
  device-usage/prng \
  applications/dhcp \
  applications/static_website_tls

ifeq ($(MODE),muen)
	TESTS = $(BASE_TESTS)
else
	TESTS = $(BASE_TESTS)
	TESTS += device-usage/block
endif

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
	-cd $* && mirage clean
	-$(RM) $*/Makefile.user

%-testrun:
	$(SUDO) sh ./testrun.sh $*
