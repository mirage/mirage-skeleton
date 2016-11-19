include ../Makefile.config

TARGETS=heads1 heads2 timeout1 timeout2 echo_server1

configure: $(patsubst %,%-configure,$(TARGETS))
build: $(patsubst %,%-build,$(TARGETS))
clean: $(patsubst %,%-clean,$(TARGETS))

%-build:
	TARGET=$* $(MIRAGE) configure -f src/config.ml -t $(MODE) $(MIRAGE_FLAGS)
	$(MAKE) -C src depend
	TARGET=$* $(MIRAGE) build -f src/config.ml -t $(MODE) $(MIRAGE_FLAGS)

%-clean:
	TARGET=$* $(MIRAGE) clean -f src/config.ml
	$(RM) log
