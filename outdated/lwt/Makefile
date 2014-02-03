.PHONY: clean-% configure-% build-% run-%
include ../Makefile.config

TARGETS=heads1 heads2 heads3 timeout1 timeout2 \
	echo_server1 echo_server2 int_server stream_server

configure: $(patsubst %,configure-%,$(TARGETS))
build: $(patsubst %,build-%,$(TARGETS))
clean: $(patsubst %,clean-%,$(TARGETS))

configure-%:
	cd src && mirari configure $(BACKEND) $*.conf

build-%: configure-%
	cd src && mirari build $(BACKEND) $*.conf

clean-%:
	if [ ! -r src/Makefile ]; then $(MAKE) configure-$* ; fi
	cd src && mirari clean $*.conf ;\
	$(RM) src/myocamlbuild.ml src/Makefile src/*.xl

run-%: configure-% build-%
	cd src && mirari run $(BACKEND) $*.conf
