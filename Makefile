-include Makefile.config

TESTS = \
  block \
  clock \
  conduit_server \
  console \
  dhcp \
  dns \
  ethifv4 \
  hello \
  hello-key \
  http-fetch \
  io_page \
  kv_ro \
  kv_ro_crunch \
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
