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
  applications/docteur \
  applications/dhcp \
  applications/git \
  applications/dns \
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

OPAM_SWITCH = $(patsubst %, %/mirage/*.opam, $(TESTS))

all:
	$(MAKE) configure
	$(MAKE) lock
	$(MAKE) depends
	$(MAKE) pull
	$(MAKE) build

configure: $(CONFIGS)
clean: $(CLEANS)
	rm -f $(LOCK)
	rm -rf duniverse

%-configure:
	$(MIRAGE) configure -f $*/config.ml -t $(MODE) $(MIRAGE_FLAGS)

OPAMFILES = $(shell for i in $(TESTS); do (cd $$i/mirage; ls *.opam | sed -e 's/\.opam$$//'); done)

lock:
	@$(MAKE) -s repo-add
	env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo lock --recurse-opam $(OPAMFILES) --build-only --ocaml-version $(shell ocamlc --version) -l $(LOCK)
	@$(MAKE) -s repo-rm

depends:
	$(OPAM) install $(OPAM_SWITCH) --deps-only --yes
	env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo depext -y -l $(LOCK)

pull:
	env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo pull

build:
	dune build

%-clean:
	mirage clean -f $*/config.ml

comma := ,
comment := \#
repo-add:
	$(foreach OVERLAY,$(subst $(comma), ,$(MIRAGE_EXTRA_REPOS)), \
		$(eval NAME = $(shell echo --no $(OVERLAY) | cut -d: -f1)) \
		$(eval URL  = $(subst $(comment),\\\#,$(shell echo --no $(OVERLAY) | cut -d: -f2-))) \
		$(OPAM) repo add $(NAME) $(URL) || $(OPAM) repo set-url $(NAME) $(URL) ; \
	)

repo-rm:
	$(foreach OVERLAY,$(subst $(comma), ,$(MIRAGE_EXTRA_REPOS)), \
	  $(eval NAME = $(echo -n $(OVERLAY) | cut -d: -f1)) \
	  $(OPAM) repo remove $(NAME) ; \
	)
