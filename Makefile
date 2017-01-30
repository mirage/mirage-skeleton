-include Makefile.config

TESTS = \
  lwt_tutorial/echo_server \
  lwt_tutorial/heads1 \
  lwt_tutorial/heads2 \
  lwt_tutorial/timeout1 \
  lwt_tutorial/timeout2 \
  block \
  clock \
  conduit_server \
  console \
  dhcp \
  dns \
  hello \
  hello-key \
  http-fetch \
  kv_ro \
  lwt \
  netif-forward \
  network \
  noop \
  noop-functor \
  ping6 \
  stackv4 \
  static_website \
  static_website_tls

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
