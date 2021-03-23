/* See LICENSE file for copyright and license details. */
#ifndef SOCK_H
#define SOCK_H

#include <stddef.h>
#include <sys/socket.h>
#include <sys/types.h>

int sock_get_ips(const char *, const char *);
int sock_get_uds(const char *, uid_t, gid_t);
void sock_rem_uds(const char *);
int sock_set_timeout(int, int);
int sock_set_nonblocking(int);
int sock_get_inaddr_str(const struct sockaddr_storage *, char *, size_t);
int sock_same_addr(const struct sockaddr_storage *,
                   const struct sockaddr_storage *);

#endif /* SOCK_H */
