-include Makefile.config


expected_opam_version_major := 2
expected_opam_version_minor := 1
current_opam_version := $(shell opam --version)
current_opam_version_major := $(shell echo $(current_opam_version) | cut -f1 -d.)
current_opam_version_minor := $(shell echo $(current_opam_version) | cut -f2 -d.)
OPAM_VERSION_OK := $(shell [ $(current_opam_version_major) -gt $(expected_opam_version_major) -o \( $(current_opam_version_major) -eq $(expected_opam_version_major) -a $(current_opam_version_minor) -ge $(expected_opam_version_minor) \) ] && echo true)

ifneq ($(OPAM_VERSION_OK),true)
$(error Unexpected opam version (found: ${current_opam_version}, expected: >=${expected_opam_version_major}.${expected_opam_version_minor}.*))
endif

expected_mirage_version:= v4
current_mirage_version := $(shell mirage --version)

ifeq ($(filter ${expected_mirage_version}.%,${current_mirage_version}),)
$(error Unexpected mirage version (found: ${current_mirage_version}, expected: ${expected_mirage_version}.*))
endif


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

OPAM_SWITCH = $(patsubst %, %/mirage/*-switch.opam, $(TESTS))

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

OPAMFILES = $(shell for i in $(TESTS); do (cd $$i/mirage; ls *-monorepo.opam | sed -e 's/\.opam$$//'); done)

lock:
	@$(MAKE) -s repo-add
	$(OPAM) monorepo lock --recurse-opam $(OPAMFILES) --build-only --ocaml-version $(shell ocamlc --version) -l $(LOCK)
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

comma := ,
repo-add:
	$(foreach OVERLAY,$(subst $(comma), ,$(MIRAGE_EXTRA_REPOS)), \
		$(eval NAME = $(shell echo --no $(OVERLAY) | cut -d: -f1)) \
		$(eval URL  = $(shell echo --no $(OVERLAY) | cut -d: -f2-)) \
		$(OPAM) repo add $(NAME) $(URL) || $(OPAM) repo set-url $(NAME) $(URL) ; \
	)

repo-rm:
	$(foreach OVERLAY,$(subst $(comma), ,$(MIRAGE_EXTRA_REPOS)), \
	  $(eval NAME = $(echo -n $(OVERLAY) | cut -d: -f1)) \
	  $(OPAM) repo remove $(NAME) ; \
	)
