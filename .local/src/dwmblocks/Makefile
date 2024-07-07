.POSIX:

PREFIX = /usr/local
CC = gcc

HOSTNAME = $(shell cat /etc/hostname || echo "Unknown")
HOSTNAME_VAR = HOSTNAME_$(HOSTNAME)

USERNAME = $(shell id -nu 1000)
USERNAME_VAR = USERNAME="/home/$(USERNAME)"

dwmblocks: dwmblocks.o
	$(CC) -D$(HOSTNAME_VAR) -D'$(USERNAME_VAR)' dwmblocks.o -lX11 -o dwmblocks
dwmblocks.o: dwmblocks.c config.h
	$(CC) -D$(HOSTNAME_VAR) -D'$(USERNAME_VAR)' -c dwmblocks.c
clean:
	rm -f *.o *.gch dwmblocks
install: dwmblocks
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp -f dwmblocks $(DESTDIR)$(PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/dwmblocks
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/dwmblocks

.PHONY: clean install uninstall
