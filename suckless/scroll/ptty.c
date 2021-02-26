#include <sys/wait.h>

#include <errno.h>
#include <inttypes.h>
#include <limits.h>
#include <poll.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>

#if   defined(__linux)
 #include <pty.h>
#elif defined(__OpenBSD__) || defined(__NetBSD__) || defined(__APPLE__)
 #include <util.h>
#elif defined(__FreeBSD__) || defined(__DragonFly__)
 #include <libutil.h>
#endif

void
die(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);

	if (fmt[0] && fmt[strlen(fmt)-1] == ':') {
		fputc(' ', stderr);
		perror(NULL);
	} else {
		fputc('\n', stderr);
	}

	exit(EXIT_FAILURE);
}

void
usage(void)
{
	fputs("ptty [-C] [-c cols] [-r rows] cmd\n", stderr);
	exit(EXIT_FAILURE);
}

int
main(int argc, char *argv[])
{
	struct winsize ws = {.ws_row = 25, .ws_col = 80, 0, 0};
	int ch;
	bool closeflag = false;

	while ((ch = getopt(argc, argv, "c:r:Ch")) != -1) {
		switch (ch) {
		case 'c':	/* cols */
			ws.ws_col = strtoimax(optarg, NULL, 10);
			if (errno != 0)
				die("strtoimax: %s", optarg);
			break;
		case 'r':	/* lines */
			ws.ws_row = strtoimax(optarg, NULL, 10);
			if (errno != 0)
				die("strtoimax: %s", optarg);
			break;
		case 'C':
			closeflag = true;
			break;
		case 'h':
		default:
			usage();
		}
	}
	argc -= optind;
	argv += optind;

	if (argc < 1)
		usage();

	int mfd;
	pid_t child = forkpty(&mfd, NULL, NULL, &ws);
	switch (child) {
	case -1:
		die("forkpty");
	case  0: /* child */
		execvp(argv[0], argv);
		die("exec");
	}

	/* parent */

	if (closeflag && close(mfd) == -1)
		die("close:");

	int pfds = 2;
	struct pollfd pfd[2] = {
		{ STDIN_FILENO, POLLIN, 0},
		{ mfd,          POLLIN, 0}
	};

	for (;;) {
		char buf[BUFSIZ];
		ssize_t n;
		int r;

		if ((r = poll(pfd, pfds, -1)) == -1)
			die("poll:");

		if (pfd[0].revents & POLLIN) {
			if ((n = read(STDIN_FILENO, buf, sizeof buf)) == -1)
				die("read:");
			if (n == 0) {
				pfd[0].fd = -1;
				if (close(mfd) == -1)
					die("close:");
				break;
			}
			if (write(mfd, buf, n) == -1)
				die("write:");
		}

		if (pfd[1].revents & POLLIN) {
			if ((n = read(mfd, buf, sizeof(buf)-1)) == -1)
				die("read:");

			if (n == 0) break;

			buf[n] = '\0';

			/* handle cursor position request */
			if (strcmp("\033[6n", buf) == 0) {
				dprintf(mfd, "\033[25;1R");
				continue;
			}

			if (write(STDOUT_FILENO, buf, n) == -1)
				die("write:");
		}

		if (pfd[0].revents & POLLHUP) {
			pfd[0].fd = -1;
			if (close(mfd) == -1)
				die("close:");
			break;
		}
		if (pfd[1].revents & POLLHUP)
			break;
	}

	int status;
	if (waitpid(child, &status, 0) != child)
		die("waitpid:");

	return WEXITSTATUS(status);
}
