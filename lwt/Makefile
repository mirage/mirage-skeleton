include ../Makefile.config

TARGETS=heads1 heads2 heads3

build: $(patsubst %,build-%,$(TARGETS))
clean: $(patsubst %,clean-%,$(TARGETS))
configure: $(patsubst %,configure-%,$(TARGETS))

build-%: configure-%
	cd src && mirari build $(BACKEND) $*.conf

configure-%:
	cd src && mirari configure $(BACKEND) $*.conf

clean-%: configure-%
	cd src && mirari clean $*.conf ;\
	$(RM) src/myocamlbuild.ml src/Makefile src/*.xl

run-%:
	cd src && mirari run $(BACKEND) $*.conf
