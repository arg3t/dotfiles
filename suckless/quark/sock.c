/* See LICENSE file for copyright and license details. */
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <netinet/in.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/un.h>
#include <unistd.h>

#include "sock.h"
#include "util.h"

int
sock_get_ips(const char *host, const char* port)
{
	struct addrinfo hints = {
		.ai_flags    = AI_NUMERICSERV,
		.ai_family   = AF_UNSPEC,
		.ai_socktype = SOCK_STREAM,
	};
	struct addrinfo *ai, *p;
	int ret, insock = 0;

	if ((ret = getaddrinfo(host, port, &hints, &ai))) {
		die("getaddrinfo: %s", gai_strerror(ret));
	}

	for (p = ai; p; p = p->ai_next) {
		if ((insock = socket(p->ai_family, p->ai_socktype,
		                     p->ai_protocol)) < 0) {
			continue;
		}
		if (setsockopt(insock, SOL_SOCKET, SO_REUSEADDR,
		               &(int){1}, sizeof(int)) < 0) {
			die("setsockopt:");
		}
		if (bind(insock, p->ai_addr, p->ai_addrlen) < 0) {
			/* bind failed, close the insock and retry */
			if (close(insock) < 0) {
				die("close:");
			}
			continue;
		}
		break;
	}
	freeaddrinfo(ai);
	if (!p) {
		/* we exhaustet the addrinfo-list and found no connection */
		if (errno == EACCES) {
			die("You need to run as root or have "
			    "CAP_NET_BIND_SERVICE set to bind to "
			    "privileged ports");
		} else {
			die("bind:");
		}
	}

	if (listen(insock, SOMAXCONN) < 0) {
		die("listen:");
	}

	return insock;
}

int
sock_get_uds(const char *udsname, uid_t uid, gid_t gid)
{
	struct sockaddr_un addr = {
		.sun_family = AF_UNIX,
	};
	size_t udsnamelen;
	int insock, sockmode = S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP |
	                       S_IROTH | S_IWOTH;

	if ((insock = socket(AF_UNIX, SOCK_STREAM, 0)) < 0) {
		die("socket:");
	}

	if ((udsnamelen = strlen(udsname)) > sizeof(addr.sun_path) - 1) {
		die("UNIX-domain socket name truncated");
	}
	memcpy(addr.sun_path, udsname, udsnamelen + 1);

	if (bind(insock, (const struct sockaddr *)&addr, sizeof(addr)) < 0) {
		die("bind '%s':", udsname);
	}

	if (listen(insock, SOMAXCONN) < 0) {
		sock_rem_uds(udsname);
		die("listen:");
	}

	if (chmod(udsname, sockmode) < 0) {
		sock_rem_uds(udsname);
		die("chmod '%s':", udsname);
	}

	if (chown(udsname, uid, gid) < 0) {
		sock_rem_uds(udsname);
		die("chown '%s':", udsname);
	}

	return insock;
}

void
sock_rem_uds(const char *udsname)
{
	if (unlink(udsname) < 0) {
		die("unlink '%s':", udsname);
	}
}

int
sock_set_timeout(int fd, int sec)
{
	struct timeval tv;

	tv.tv_sec = sec;
	tv.tv_usec = 0;

	if (setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv)) < 0 ||
	    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv)) < 0) {
		warn("setsockopt:");
		return 1;
	}

	return 0;
}

int
sock_set_nonblocking(int fd)
{
	int flags;

	if ((flags = fcntl(fd, F_GETFL, 0)) < 0) {
		warn("fcntl:");
		return 1;
	}

	flags |= O_NONBLOCK;

	if (fcntl(fd, F_SETFL, flags) < 0) {
		warn("fcntl:");
		return 1;
	}

	return 0;
}

int
sock_get_inaddr_str(const struct sockaddr_storage *in_sa, char *str,
                    size_t len)
{
	switch (in_sa->ss_family) {
	case AF_INET:
		if (!inet_ntop(AF_INET,
		               &(((struct sockaddr_in *)in_sa)->sin_addr),
		               str, len)) {
			warn("inet_ntop:");
			return 1;
		}
		break;
	case AF_INET6:
		if (!inet_ntop(AF_INET6,
		               &(((struct sockaddr_in6 *)in_sa)->sin6_addr),
		               str, len)) {
			warn("inet_ntop:");
			return 1;
		}
		break;
	case AF_UNIX:
		snprintf(str, len, "uds");
		break;
	default:
		snprintf(str, len, "-");
	}

	return 0;
}

int
sock_same_addr(const struct sockaddr_storage *sa1, const struct sockaddr_storage *sa2)
{
	/* return early if address-families don't match */
	if (sa1->ss_family != sa2->ss_family) {
		return 0;
	}

	switch (sa1->ss_family) {
	case AF_INET6:
		return memcmp(((struct sockaddr_in6 *)sa1)->sin6_addr.s6_addr,
		              ((struct sockaddr_in6 *)sa2)->sin6_addr.s6_addr,
		              sizeof(((struct sockaddr_in6 *)sa1)->sin6_addr.s6_addr));
	case AF_INET:
		return ntohl(((struct sockaddr_in *)sa1)->sin_addr.s_addr) ==
		       ntohl(((struct sockaddr_in *)sa2)->sin_addr.s_addr);
	default: /* AF_UNIX */
		return strcmp(((struct sockaddr_un *)sa1)->sun_path,
		              ((struct sockaddr_un *)sa2)->sun_path) == 0;
	}
}
