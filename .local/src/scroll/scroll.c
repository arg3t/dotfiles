/*
 * Based on an example code from Roberto E. Vargas Caballero.
 *
 * See LICENSE file for copyright and license details.
 */

#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <sys/queue.h>
#include <sys/resource.h>

#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <pwd.h>
#include <signal.h>
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

#define LENGTH(X)	(sizeof (X) / sizeof ((X)[0]))

const char *argv0;

TAILQ_HEAD(tailhead, line) head;

struct line {
	TAILQ_ENTRY(line) entries;
	size_t size;
	size_t len;
	char *buf;
} *bottom;

pid_t child;
int mfd;
struct termios dfl;
struct winsize ws;
static bool altscreen = false;	/* is alternative screen active */
static bool doredraw = false;	/* redraw upon sigwinch */

struct rule {
	const char *seq;
	enum {SCROLL_UP, SCROLL_DOWN} event;
	short lines;
};

#include "config.h"

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
sigwinch(int sig)
{
	assert(sig == SIGWINCH);

	if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == -1)
		die("ioctl:");
	if (ioctl(mfd, TIOCSWINSZ, &ws) == -1) {
		if (errno == EBADF)	/* child already exited */
			return;
		die("ioctl:");
	}
	kill(-child, SIGWINCH);
	doredraw = true;
}

void
reset(void)
{
	if (tcsetattr(STDIN_FILENO, TCSANOW, &dfl) == -1)
		die("tcsetattr:");
}

/* error avoiding remalloc */
void *
earealloc(void *ptr, size_t size)
{
	void *mem;

	while ((mem = realloc(ptr, size)) == NULL) {
		struct line *line = TAILQ_LAST(&head, tailhead);

		if (line == NULL)
			die("realloc:");

		TAILQ_REMOVE(&head, line, entries);
		free(line->buf);
		free(line);
	}

	return mem;
}

/* Count string length w/o ansi esc sequences. */
size_t
strelen(const char *buf, size_t size)
{
	enum {CHAR, BREK, ESC} state = CHAR;
	size_t len = 0;

	for (size_t i = 0; i < size; i++) {
		char c = buf[i];

		switch (state) {
		case CHAR:
			if (c == '\033')
				state = BREK;
			else
				len++;
			break;
		case BREK:
			if (c == '[') {
				state = ESC;
			} else {
				state = CHAR;
				len++;
			}
			break;
		case ESC:
			if (c >= 64 && c <= 126)
				state = CHAR;
			break;
		}
	}

	return len;
}

/* detect alternative screen switching and clear screen */
bool
skipesc(char c)
{
	static enum {CHAR, BREK, ESC} state = CHAR;
	static char buf[BUFSIZ];
	static size_t i = 0;

	switch (state) {
	case CHAR:
		if (c == '\033')
			state = BREK;
		break;
	case BREK:
		if (c == '[')
			state = ESC;
		else
			state = CHAR;
		break;
	case ESC:
		buf[i++] = c;
		if (i == sizeof buf) {
			/* TODO: find a better way to handle this situation */
			state = CHAR;
			i = 0;
		} else if (c >= 64 && c <= 126) {
			state = CHAR;
			buf[i] = '\0';
			i = 0;

			/* esc seq. enable alternative screen */
			if (strcmp(buf, "?1049h") == 0 ||
			    strcmp(buf, "?1047h") == 0 ||
			    strcmp(buf, "?47h"  ) == 0)
				altscreen = true;

			/* esc seq. disable alternative screen */
			if (strcmp(buf, "?1049l") == 0 ||
			    strcmp(buf, "?1047l") == 0 ||
			    strcmp(buf, "?47l"  ) == 0)
				altscreen = false;

			/* don't save cursor move or clear screen */
			/* esc sequences to log */
			switch (c) {
			case 'A':
			case 'B':
			case 'C':
			case 'D':
			case 'H':
			case 'J':
			case 'K':
			case 'f':
				return true;
			}
		}
		break;
	}

	return altscreen;
}

void
getcursorposition(int *x, int *y)
{
	char input[BUFSIZ];
	ssize_t n;

	if (write(STDOUT_FILENO, "\033[6n", 4) == -1)
		die("requesting cursor position");

	do {
		if ((n = read(STDIN_FILENO, input, sizeof(input)-1)) == -1)
			die("reading cursor position");
		input[n] = '\0';
	} while (sscanf(input, "\033[%d;%dR", y, x) != 2);

	if (*x <= 0 || *y <= 0)
		die("invalid cursor position: x=%d y=%d", *x, *y);
}

void
addline(char *buf, size_t size)
{
	struct line *line = earealloc(NULL, sizeof *line);

	line->size = size;
	line->len = strelen(buf, size);
	line->buf = earealloc(NULL, size);
	memcpy(line->buf, buf, size);

	TAILQ_INSERT_HEAD(&head, line, entries);
}

void
redraw()
{
	int rows = 0, x, y;

	if (bottom == NULL)
		return;

	getcursorposition(&x, &y);

	if (y < ws.ws_row-1)
	  y--;

	/* wind back bottom pointer by shown history */
	for (; bottom != NULL && TAILQ_NEXT(bottom, entries) != NULL &&
	    rows < y - 1; rows++)
		bottom = TAILQ_NEXT(bottom, entries);

	/* clear screen */
	dprintf(STDOUT_FILENO, "\033[2J");
	/* set cursor position to upper left corner */
	write(STDOUT_FILENO, "\033[0;0H", 6);

	/* remove newline of first line as we are at 0,0 already */
	if (bottom->size > 0 && bottom->buf[0] == '\n')
		write(STDOUT_FILENO, bottom->buf + 1, bottom->size - 1);
	else
		write(STDOUT_FILENO, bottom->buf, bottom->size);

	for (rows = ws.ws_row; rows > 0 &&
	    TAILQ_PREV(bottom, tailhead, entries) != NULL; rows--) {
		bottom = TAILQ_PREV(bottom, tailhead, entries);
		write(STDOUT_FILENO, bottom->buf, bottom->size);
	}

	if (bottom == TAILQ_FIRST(&head)) {
		/* add new line in front of the shell prompt */
		write(STDOUT_FILENO, "\n", 1);
		write(STDOUT_FILENO, "\033[?25h", 6);	/* show cursor */
	} else
		bottom = TAILQ_NEXT(bottom, entries);
}

void
scrollup(int n)
{
	int rows = 2, x, y, extra = 0;
	struct line *scrollend = bottom;

	if (bottom == NULL)
		return;

	getcursorposition(&x, &y);

	if (n < 0) /* scroll by fraction of ws.ws_row, but at least one line */
		n = ws.ws_row > (-n) ? ws.ws_row / (-n) : 1;

	/* wind back scrollend pointer by the current screen */
	while (rows < y && TAILQ_NEXT(scrollend, entries) != NULL) {
		scrollend = TAILQ_NEXT(scrollend, entries);
		rows += (scrollend->len - 1) / ws.ws_col + 1;
	}

	if (rows <= 0)
		return;

	/* wind back scrollend pointer n lines */
	for (rows = 0; rows + extra < n &&
	    TAILQ_NEXT(scrollend, entries) != NULL; rows++) {
		scrollend = TAILQ_NEXT(scrollend, entries);
		extra += (scrollend->len - 1) / ws.ws_col;
	}

	/* move the text in terminal rows lines down */
	dprintf(STDOUT_FILENO, "\033[%dT", n);
	/* set cursor position to upper left corner */
	write(STDOUT_FILENO, "\033[0;0H", 6);
	/* hide cursor */
	write(STDOUT_FILENO, "\033[?25l", 6);

	/* remove newline of first line as we are at 0,0 already */
	if (scrollend->size > 0 && scrollend->buf[0] == '\n')
		write(STDOUT_FILENO, scrollend->buf + 1, scrollend->size - 1);
	else
		write(STDOUT_FILENO, scrollend->buf, scrollend->size);
	if (y + n >= ws.ws_row)
		bottom = TAILQ_NEXT(bottom, entries);

	/* print rows lines and move bottom forward to the new screen bottom */
	for (; rows > 1; rows--) {
		scrollend = TAILQ_PREV(scrollend, tailhead, entries);
		if (y + n >= ws.ws_row)
			bottom = TAILQ_NEXT(bottom, entries);
		write(STDOUT_FILENO, scrollend->buf, scrollend->size);
	}
	/* move cursor from line n to the old bottom position */
	if (y + n < ws.ws_row) {
		dprintf(STDOUT_FILENO, "\033[%d;%dH", y + n, x);
		write(STDOUT_FILENO, "\033[?25h", 6);	/* show cursor */
	} else
		dprintf(STDOUT_FILENO, "\033[%d;0H", ws.ws_row);
}

void
scrolldown(char *buf, size_t size, int n)
{
	if (bottom == NULL || bottom == TAILQ_FIRST(&head))
		return;

	if (n < 0) /* scroll by fraction of ws.ws_row, but at least one line */
		n = ws.ws_row > (-n) ? ws.ws_row / (-n) : 1;

	bottom = TAILQ_PREV(bottom, tailhead, entries);
	/* print n lines */
	while (n > 0 && bottom != NULL && bottom != TAILQ_FIRST(&head)) {
		bottom = TAILQ_PREV(bottom, tailhead, entries);
		write(STDOUT_FILENO, bottom->buf, bottom->size);
		n -= (bottom->len - 1) / ws.ws_col + 1;
	}
	if (n > 0 && bottom == TAILQ_FIRST(&head)) {
		write(STDOUT_FILENO, "\033[?25h", 6);	/* show cursor */
		write(STDOUT_FILENO, buf, size);
	} else if (bottom != NULL)
		bottom = TAILQ_NEXT(bottom, entries);
}

void
jumpdown(char *buf, size_t size)
{
	int rows = ws.ws_row;

	/* wind back by one page starting from the latest line */
	bottom = TAILQ_FIRST(&head);
	for (; TAILQ_NEXT(bottom, entries) != NULL && rows > 0; rows--)
		bottom = TAILQ_NEXT(bottom, entries);

	scrolldown(buf, size, ws.ws_row);
}

void
usage(void) {
	die("usage: %s [-Mvh] [-m mem] [program]", argv0);
}

int
main(int argc, char *argv[])
{
	int ch;
	struct rlimit rlimit;

	argv0 = argv[0];

	if (getrlimit(RLIMIT_DATA, &rlimit) == -1)
		die("getrlimit");

	const char *optstring = "Mm:vh";
	while ((ch = getopt(argc, argv, optstring)) != -1) {
		switch (ch) {
		case 'M':
			rlimit.rlim_cur = rlimit.rlim_max;
			break;
		case 'm':
			rlimit.rlim_cur = strtoull(optarg, NULL, 0);
			if (errno != 0)
				die("strtoull: %s", optarg);
			break;
		case 'v':
			die("%s " VERSION, argv0);
			break;
		case 'h':
		default:
			usage();
		}
	}
	argc -= optind;
	argv += optind;

	TAILQ_INIT(&head);

	if (isatty(STDIN_FILENO) == 0 || isatty(STDOUT_FILENO) == 0)
		die("parent it not a tty");

	/* save terminal settings for resetting after exit */
	if (tcgetattr(STDIN_FILENO, &dfl) == -1)
		die("tcgetattr:");
	if (atexit(reset))
		die("atexit:");

	/* get window size of the terminal */
	if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == -1)
		die("ioctl:");

	child = forkpty(&mfd, NULL, &dfl, &ws);
	if (child == -1)
		die("forkpty:");
	if (child == 0) {	/* child */
		if (argc >= 1) {
			execvp(argv[0], argv);
		} else {
			struct passwd *passwd = getpwuid(getuid());
			if (passwd == NULL)
				die("getpwid:");
			execlp(passwd->pw_shell, passwd->pw_shell, NULL);
		}

		perror("execvp");
		_exit(127);
	}

	/* set maximum memory size for scrollback buffer */
	if (setrlimit(RLIMIT_DATA, &rlimit) == -1)
		die("setrlimit:");

#ifdef __OpenBSD__
	if (pledge("stdio tty proc", NULL) == -1)
		die("pledge:");
#endif

	if (signal(SIGWINCH, sigwinch) == SIG_ERR)
		die("signal:");

	struct termios new = dfl;
	cfmakeraw(&new);
	new.c_cc[VMIN ] = 1;	/* return read if at least one byte in buffer */
	new.c_cc[VTIME] = 0;	/* no polling time for read from terminal */
	if (tcsetattr(STDIN_FILENO, TCSANOW, &new) == -1)
		die("tcsetattr:");

	size_t size = BUFSIZ, len = 0, pos = 0;
	char *buf = calloc(size, sizeof *buf);
	if (buf == NULL)
		die("calloc:");

	struct pollfd pfd[2] = {
		{STDIN_FILENO, POLLIN, 0},
		{mfd,          POLLIN, 0}
	};

	for (;;) {
		char input[BUFSIZ];

		if (poll(pfd, LENGTH(pfd), -1) == -1 && errno != EINTR)
			die("poll:");

		if (doredraw) {
			redraw();
			doredraw = false;
		}

		if (pfd[0].revents & POLLHUP || pfd[1].revents & POLLHUP)
			break;

		if (pfd[0].revents & POLLIN) {
			ssize_t n = read(STDIN_FILENO, input, sizeof(input)-1);

			if (n == -1 && errno != EINTR)
				die("read:");
			if (n == 0)
				break;

			input[n] = '\0';

			if (altscreen)
				goto noevent;

			for (size_t i = 0; i < LENGTH(rules); i++) {
				if (strncmp(rules[i].seq, input,
				    strlen(rules[i].seq)) == 0) {
					if (rules[i].event == SCROLL_UP)
						scrollup(rules[i].lines);
					if (rules[i].event == SCROLL_DOWN)
						scrolldown(buf, len,
						    rules[i].lines);
					goto out;
				}
			}
 noevent:
			if (write(mfd, input, n) == -1)
				die("write:");

			if (bottom != TAILQ_FIRST(&head))
				jumpdown(buf, len);
		}
 out:
		if (pfd[1].revents & POLLIN) {
			ssize_t n = read(mfd, input, sizeof(input)-1);

			if (n == -1 && errno != EINTR)
				die("read:");
			if (n == 0)	/* on exit of child we continue here */
				continue; /* let signal handler catch SIGCHLD */

			input[n] = '\0';

			/* don't print child output while scrolling */
			if (bottom == TAILQ_FIRST(&head))
				if (write(STDOUT_FILENO, input, n) == -1)
					die("write:");

			/* iterate over the input buffer */
			for (char *c = input; n-- > 0; c++) {
				/* don't save alternative screen and */
				/* clear screen esc sequences to scrollback */
				if (skipesc(*c))
					continue;

				if (*c == '\n') {
					addline(buf, len);
					/* only advance bottom if scroll is */
					/* at the end of the scroll back */
					if (bottom == NULL ||
					    TAILQ_PREV(bottom, tailhead,
					      entries) == TAILQ_FIRST(&head))
						bottom = TAILQ_FIRST(&head);

					memset(buf, 0, size);
					len = pos = 0;
					buf[pos++] = '\r';
				} else if (*c == '\r') {
					pos = 0;
					continue;
				}
				buf[pos++] = *c;
				if (pos > len)
					len = pos;
				if (len == size) {
					size *= 2;
					buf = earealloc(buf, size);
				}
			}
		}
	}

	if (close(mfd) == -1)
		die("close:");

	int status;
	if (waitpid(child, &status, 0) == -1)
		die("waitpid:");

	return WEXITSTATUS(status);
}
