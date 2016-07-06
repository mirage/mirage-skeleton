include ../Makefile.config

CP ?= cp -av
TARGETS = heads1 heads2 heads3 timeout1 timeout2 echo_server1

build: $(patsubst %,%-build,$(TARGETS))
clean: $(patsubst %,%-clean,$(TARGETS))

%-build:
	TARGET=$* $(MIRAGE) configure -f src/config.ml --$(MODE) $(MIRAGE_FLAGS)
	cd src && $(MAKE)

%-clean:
	TARGET=$* $(MIRAGE) clean -f src/config.ml
	$(RM) log
