/* See LICENSE file for copyright and license details. */
#include <errno.h>
#include <grp.h>
#include <limits.h>
#include <pwd.h>
#include <regex.h>
#include <signal.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include "arg.h"
#include "server.h"
#include "sock.h"
#include "util.h"

static char *udsname;

static void
cleanup(void)
{
	if (udsname) {
		sock_rem_uds(udsname);
	}
}

static void
sigcleanup(int sig)
{
	cleanup();
	kill(0, sig);
	_exit(1);
}

static void
handlesignals(void(*hdl)(int))
{
	struct sigaction sa = {
		.sa_handler = hdl,
	};

	sigemptyset(&sa.sa_mask);
	sigaction(SIGTERM, &sa, NULL);
	sigaction(SIGHUP, &sa, NULL);
	sigaction(SIGINT, &sa, NULL);
	sigaction(SIGQUIT, &sa, NULL);
}

static void
usage(void)
{
	const char *opts = "[-u user] [-g group] [-n num] [-d dir] [-l] "
	                   "[-i file] [-v vhost] ... [-m map] ...";

	die("usage: %s -p port [-h host] %s\n"
	    "       %s -U file [-p port] %s", argv0,
	    opts, argv0, opts);
}

int
main(int argc, char *argv[])
{
	struct group *grp = NULL;
	struct passwd *pwd = NULL;
	struct rlimit rlim;
	struct server srv = {
		.docindex = "index.html",
	};
	size_t i;
	int insock, status = 0;
	const char *err;
	char *tok[4];

	/* defaults */
	size_t nthreads = 4;
	size_t nslots = 64;
	char *servedir = ".";
	char *user = "nobody";
	char *group = "nogroup";

	ARGBEGIN {
	case 'd':
		servedir = EARGF(usage());
		break;
	case 'g':
		group = EARGF(usage());
		break;
	case 'h':
		srv.host = EARGF(usage());
		break;
	case 'i':
		srv.docindex = EARGF(usage());
		if (strchr(srv.docindex, '/')) {
			die("The document index must not contain '/'");
		}
		break;
	case 'l':
		srv.listdirs = 1;
		break;
	case 'm':
		if (spacetok(EARGF(usage()), tok, 3) || !tok[0] || !tok[1]) {
			usage();
		}
		if (!(srv.map = reallocarray(srv.map, ++srv.map_len,
		                             sizeof(struct map)))) {
			die("reallocarray:");
		}
		srv.map[srv.map_len - 1].from  = tok[0];
		srv.map[srv.map_len - 1].to    = tok[1];
		srv.map[srv.map_len - 1].chost = tok[2];
		break;
	case 's':
		err = NULL;
		nslots = strtonum(EARGF(usage()), 1, INT_MAX, &err);
		if (err) {
			die("strtonum '%s': %s", EARGF(usage()), err);
		}
		break;
	case 't':
		err = NULL;
		nthreads = strtonum(EARGF(usage()), 1, INT_MAX, &err);
		if (err) {
			die("strtonum '%s': %s", EARGF(usage()), err);
		}
		break;
	case 'p':
		srv.port = EARGF(usage());
		break;
	case 'U':
		udsname = EARGF(usage());
		break;
	case 'u':
		user = EARGF(usage());
		break;
	case 'v':
		if (spacetok(EARGF(usage()), tok, 4) || !tok[0] || !tok[1] ||
		    !tok[2]) {
			usage();
		}
		if (!(srv.vhost = reallocarray(srv.vhost, ++srv.vhost_len,
		                               sizeof(*srv.vhost)))) {
			die("reallocarray:");
		}
		srv.vhost[srv.vhost_len - 1].chost  = tok[0];
		srv.vhost[srv.vhost_len - 1].regex  = tok[1];
		srv.vhost[srv.vhost_len - 1].dir    = tok[2];
		srv.vhost[srv.vhost_len - 1].prefix = tok[3];
		break;
	default:
		usage();
	} ARGEND

	if (argc) {
		usage();
	}

	/* can't have both host and UDS but must have one of port or UDS*/
	if ((srv.host && udsname) || !(srv.port || udsname)) {
		usage();
	}

	if (udsname && (!access(udsname, F_OK) || errno != ENOENT)) {
		die("UNIX-domain socket '%s': %s", udsname, errno ?
		    strerror(errno) : "File exists");
	}

	/* compile and check the supplied vhost regexes */
	for (i = 0; i < srv.vhost_len; i++) {
		if (regcomp(&srv.vhost[i].re, srv.vhost[i].regex,
		            REG_EXTENDED | REG_ICASE | REG_NOSUB)) {
			die("regcomp '%s': invalid regex",
			    srv.vhost[i].regex);
		}
	}

	/* validate user and group */
	errno = 0;
	if (!user || !(pwd = getpwnam(user))) {
		die("getpwnam '%s': %s", user ? user : "null",
		    errno ? strerror(errno) : "Entry not found");
	}
	errno = 0;
	if (!group || !(grp = getgrnam(group))) {
		die("getgrnam '%s': %s", group ? group : "null",
		    errno ? strerror(errno) : "Entry not found");
	}

	/* open a new process group */
	setpgid(0, 0);

	handlesignals(sigcleanup);

	/*
	 * set the maximum number of open file descriptors as needed
	 *  - 3 initial fd's
	 *  - nthreads fd's for the listening socket
	 *  - (nthreads * nslots) fd's for the connection-fd
	 *  - (5 * nthreads) fd's for general purpose thread-use
	 */
	rlim.rlim_cur = rlim.rlim_max = 3 + nthreads + nthreads * nslots +
	                                5 * nthreads;
	if (setrlimit(RLIMIT_NOFILE, &rlim) < 0) {
		if (errno == EPERM) {
			die("You need to run as root or have "
			    "CAP_SYS_RESOURCE set, or are asking for more "
			    "file descriptors than the system can offer");
		} else {
			die("setrlimit:");
		}
	}

	/*
	 * create the (non-blocking) listening socket
	 *
	 * we could use SO_REUSEPORT and create a listening socket for
	 * each thread (for better load-balancing, given each thread
	 * would get his own kernel-queue), but this increases latency
	 * (as a thread might get stuck on a larger request, making all
	 * other request wait in line behind it).
	 *
	 * socket contention with a single listening socket is a
	 * non-issue and thread-load-balancing is better fixed in the
	 * kernel by changing epoll-sheduling from a FIFO- to a
	 * LIFO-model, especially as it doesn't affect performance
	 */
	insock = udsname ? sock_get_uds(udsname, pwd->pw_uid, grp->gr_gid) :
	                   sock_get_ips(srv.host, srv.port);
	if (sock_set_nonblocking(insock)) {
		return 1;
	}

	/*
	 * before dropping privileges, we fork, as we need to remove
	 * the UNIX-domain socket when we shut down, which we need
	 * privileges for
	 */
	switch (fork()) {
	case -1:
		warn("fork:");
		break;
	case 0:
		/* restore default handlers */
		handlesignals(SIG_DFL);

		/* reap children automatically */
		if (signal(SIGCHLD, SIG_IGN) == SIG_ERR) {
			die("signal: Failed to set SIG_IGN on SIGCHLD");
		}
		if (signal(SIGPIPE, SIG_IGN) == SIG_ERR) {
			die("signal: Failed to set SIG_IGN on SIGPIPE");
		}

		/*
		 * try increasing the thread-limit by the number
		 * of threads we need (which is the only reliable
		 * workaround I know given the thread-limit is per user
		 * rather than per process), but ignore EPERM errors,
		 * because this most probably means the user has already
		 * set the value to the kernel's limit, and there's not
		 * much we can do in any other case.
		 * There's also no danger of overflow as the value
		 * returned by getrlimit() is way below the limits of the
		 * rlim_t datatype.
		 */
		if (getrlimit(RLIMIT_NPROC, &rlim) < 0) {
			die("getrlimit:");
		}
		if (rlim.rlim_max == RLIM_INFINITY) {
			if (rlim.rlim_cur != RLIM_INFINITY) {
				/* try increasing current limit by nthreads */
				rlim.rlim_cur += nthreads;
			}
		} else {
			/* try increasing current and hard limit by nthreads */
			rlim.rlim_cur = rlim.rlim_max += nthreads;
		}
		if (setrlimit(RLIMIT_NPROC, &rlim) < 0 && errno != EPERM) {
			die("setrlimit()");
		}

		/* limit ourselves to reading the servedir and block further unveils */
		eunveil(servedir, "r");
		eunveil(NULL, NULL);

		/* chroot */
		if (chdir(servedir) < 0) {
			die("chdir '%s':", servedir);
		}
		if (chroot(".") < 0) {
			if (errno == EPERM) {
				die("You need to run as root or have "
				    "CAP_SYS_CHROOT set");
			} else {
				die("chroot:");
			}
		}

		/* drop root */
		if (pwd->pw_uid == 0 || grp->gr_gid == 0) {
			die("Won't run under root %s for hopefully obvious reasons",
			    (pwd->pw_uid == 0) ? (grp->gr_gid == 0) ?
			    "user and group" : "user" : "group");
		}

		if (setgroups(1, &(grp->gr_gid)) < 0) {
			if (errno == EPERM) {
				die("You need to run as root or have "
				    "CAP_SETGID set");
			} else {
				die("setgroups:");
			}
		}
		if (setgid(grp->gr_gid) < 0) {
			if (errno == EPERM) {
				die("You need to run as root or have "
				    "CAP_SETGID set");
			} else {
				die("setgid:");
			}

		}
		if (setuid(pwd->pw_uid) < 0) {
			if (errno == EPERM) {
				die("You need to run as root or have "
				    "CAP_SETUID set");
			} else {
				die("setuid:");
			}
		}

		if (udsname) {
			epledge("stdio rpath proc unix", NULL);
		} else {
			epledge("stdio rpath proc inet", NULL);
		}

		/* accept incoming connections */
		server_init_thread_pool(insock, nthreads, nslots, &srv);

		exit(0);
	default:
		/* limit ourselves even further while we are waiting */
		if (udsname) {
			eunveil(udsname, "c");
			eunveil(NULL, NULL);
			epledge("stdio cpath", NULL);
		} else {
			eunveil("/", "");
			eunveil(NULL, NULL);
			epledge("stdio", NULL);
		}

		while (wait(&status) > 0)
			;
	}

	cleanup();
	return status;
}
