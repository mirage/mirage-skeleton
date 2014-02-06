include ../Makefile.config

TARGETS=heads1 heads2 heads3 timeout1 timeout2 \
	echo_server1 echo_server2 int_server stream_server

configure: $(patsubst %,%-configure,$(TARGETS))
build: $(patsubst %,%-build,$(TARGETS))
clean: $(patsubst %,%-clean,$(TARGETS))

# TARGETS=heads1 heads2 heads3 timeout1 timeout2 \
#	echo_server1 echo_server2 int_server stream_server
%-build:
	TARGET=$* $(MIRAGE) configure src/config.ml --$(MODE) $(FLAGS)
	TARGET=$* $(MIRAGE) build src/config.ml

%-clean:
	TARGET=$* $(MIRAGE) clean src/config.ml
	$(RM) log
