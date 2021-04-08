# See LICENSE file for copyright and license details
# quark - simple web server
.POSIX:

include config.mk

COMPONENTS = connection data http queue server sock util

all: quark

connection.o: connection.c config.h connection.h data.h http.h server.h sock.h util.h config.mk
data.o: data.c config.h data.h http.h server.h util.h config.mk
http.o: http.c config.h http.h server.h util.h config.mk
main.o: main.c arg.h config.h server.h sock.h util.h config.mk
server.o: server.c config.h connection.h http.h queue.h server.h util.h config.mk
sock.o: sock.c config.h sock.h util.h config.mk
util.o: util.c config.h util.h config.mk

quark: config.h $(COMPONENTS:=.o) $(COMPONENTS:=.h) main.o config.mk
	$(CC) -o $@ $(CPPFLAGS) $(CFLAGS) $(COMPONENTS:=.o) main.o $(LDFLAGS)

config.h:
	cp config.def.h $@

clean:
	rm -f quark main.o $(COMPONENTS:=.o)

dist:
	rm -rf "quark-$(VERSION)"
	mkdir -p "quark-$(VERSION)"
	cp -R LICENSE Makefile arg.h config.def.h config.mk quark.1 \
		$(COMPONENTS:=.c) $(COMPONENTS:=.h) main.c "quark-$(VERSION)"
	tar -cf - "quark-$(VERSION)" | gzip -c > "quark-$(VERSION).tar.gz"
	rm -rf "quark-$(VERSION)"

install: all
	mkdir -p "$(DESTDIR)$(PREFIX)/bin"
	cp -f quark "$(DESTDIR)$(PREFIX)/bin"
	chmod 755 "$(DESTDIR)$(PREFIX)/bin/quark"
	mkdir -p "$(DESTDIR)$(MANPREFIX)/man1"
	cp quark.1 "$(DESTDIR)$(MANPREFIX)/man1/quark.1"
	chmod 644 "$(DESTDIR)$(MANPREFIX)/man1/quark.1"

uninstall:
	rm -f "$(DESTDIR)$(PREFIX)/bin/quark"
	rm -f "$(DESTDIR)$(MANPREFIX)/man1/quark.1"
