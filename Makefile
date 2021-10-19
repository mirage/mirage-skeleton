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
  device-usage/prng \
  applications/dhcp \
  applications/git \
  applications/crypto \
  applications/static_website_tls
# disabled as it is using an old version of conduit:
# device-usage/pgx

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
CLEANS  = $(patsubst %, %-clean,     $(TESTS))

OPAM_SWITCH = $(patsubst %, %/mirage/*-switch.opam, $(TESTS))

all:
	$(MAKE) configure
	$(MAKE) lock
	$(MAKE) depends
	$(MAKE) pull
	$(MAKE) build

configure: $(CONFIGS)
clean: $(CLEANS)
	rm -f *.opam $(LOCK)
	rm -rf duniverse

%-configure:
	$(MIRAGE) configure -f $*/config.ml -t $(MODE) $(MIRAGE_FLAGS)

lock:
	@for i in $(TESTS); do cp $$i/mirage/*-monorepo.opam .; done
	@$(MAKE) -s repo-add
	$(OPAM) monorepo lock --build-only --ocaml-version $(shell ocamlc --version) -l $(LOCK)
	@$(MAKE) -s repo-rm

depends:
	opam install $(OPAM_SWITCH) --deps-only --yes
	opam monorepo depext -y -l $(LOCK)

pull:
	opam monorepo pull

build:
	dune build

%-clean:
	mirage clean -f $*/config.ml

repo-add:
	$(OPAM) repo add dune-universe $(OVERLAY) ||\
	$(OPAM) repo set-url dune-universe $(OVERLAY)

repo-rm:
	$(OPAM) repo remove dune-universe
