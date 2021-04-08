/* See LICENSE file for copyright and license details. */
#ifndef SERVER_H
#define SERVER_H

#include <regex.h>
#include <stddef.h>

struct vhost {
	char *chost;
	char *regex;
	char *dir;
	char *prefix;
	regex_t re;
};

struct map {
	char *chost;
	char *from;
	char *to;
};

struct server {
	char *host;
	char *port;
	char *docindex;
	int listdirs;
	struct vhost *vhost;
	size_t vhost_len;
	struct map *map;
	size_t map_len;
};

void server_init_thread_pool(int, size_t, size_t, const struct server *);

#endif /* SERVER_H */
