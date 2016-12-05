include ../Makefile.config

TARGETS=heads1 heads2 timeout1 timeout2 echo_server1

configure: $(patsubst %,%-configure,$(TARGETS))
build: $(patsubst %,%-build,$(TARGETS))
clean: $(patsubst %,%-clean,$(TARGETS))

%-build:
	cd src && TARGET=$* $(MIRAGE) configure -t $(MODE) $(MIRAGE_FLAGS)
	cd src && $(MAKE) depend && $(MAKE) build

%-clean:
	cd src && $(MAKE) clean
	$(RM) log
