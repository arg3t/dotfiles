CFLAGS=-O2 -Wall -Wextra -lX11 -lpci
PREFIX=/usr/local
CACHE=$(shell if [ "$$XDG_CACHE_HOME" ]; then echo "$$XDG_CACHE_HOME"; else echo "$$HOME"/.cache; fi)

all: paleofetch

clean:
	rm -f paleofetch $(CACHE)/paleofetch

paleofetch: paleofetch.c paleofetch.h config.h
	$(eval battery_path := $(shell ./config_scripts/battery_config.sh))
	$(CC) paleofetch.c -o paleofetch $(CFLAGS) -D $(battery_path)
	strip paleofetch

install: paleofetch
	mkdir -p $(PREFIX)/bin
	install ./paleofetch $(PREFIX)/bin/paleofetch
