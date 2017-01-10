include ../Makefile.config

TARGETS=heads1 heads2 timeout1 timeout2 echo_server1

build: $(patsubst %, %-build, $(TARGETS))
clean: $(patsubst %, %-clean, $(TARGETS))

%-build:
	cd src && TARGET=$* mirage configure -t $(MODE) $(MIRAGE_FLAGS) \
	       && TARGET=$* mirage build

%-clean:
	cd src && TARGET=$* mirage configure -t $(MODE) $(MIRAGE_FLAGS) \
	       && TARGET=$* mirage clean
