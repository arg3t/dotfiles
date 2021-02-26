.POSIX:

include config.mk

all: scroll

config.h:
	cp config.def.h config.h

scroll: scroll.c config.h

install: scroll
	mkdir -p $(DESTDIR)$(BINDIR) $(DESTDIR)$(MANDIR)/man1
	cp -f scroll $(DESTDIR)$(BINDIR)
	cp -f scroll.1 $(DESTDIR)$(MANDIR)/man1

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/scroll $(DESTDIR)$(MANDIR)/man1/scroll.1

test: scroll ptty
	# check usage
	if ./ptty ./scroll -h; then exit 1; fi
	# check exit passthrough of child
	if ! ./ptty ./scroll true;  then exit 1; fi
	if   ./ptty ./scroll false; then exit 1; fi
	./up.sh

clean:
	rm -f scroll ptty

distclean: clean
	rm -f config.h scroll-$(VERSION).tar.gz

dist: clean
	mkdir -p scroll-$(VERSION)
	cp -R README scroll.1 TODO Makefile config.mk config.def.h \
		ptty.c scroll.c up.sh up.log \
		scroll-$(VERSION)
	tar -cf - scroll-$(VERSION) | gzip > scroll-$(VERSION).tar.gz
	rm -rf scroll-$(VERSION)

.c:
	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o $@ $< -lutil

.PHONY: all install test clean distclean dist
