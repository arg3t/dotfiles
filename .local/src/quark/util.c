/* See LICENSE file for copyright and license details. */
#include <errno.h>
#include <limits.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <time.h>

#ifdef __OpenBSD__
#include <unistd.h>
#endif /* __OpenBSD__ */

#include "util.h"

char *argv0;

static void
verr(const char *fmt, va_list ap)
{
	if (argv0 && strncmp(fmt, "usage", sizeof("usage") - 1)) {
		fprintf(stderr, "%s: ", argv0);
	}

	vfprintf(stderr, fmt, ap);

	if (fmt[0] && fmt[strlen(fmt) - 1] == ':') {
		fputc(' ', stderr);
		perror(NULL);
	} else {
		fputc('\n', stderr);
	}
}

void
warn(const char *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
	verr(fmt, ap);
	va_end(ap);
}

void
die(const char *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
	verr(fmt, ap);
	va_end(ap);

	exit(1);
}

void
epledge(const char *promises, const char *execpromises)
{
	(void)promises;
	(void)execpromises;

#ifdef __OpenBSD__
	if (pledge(promises, execpromises) == -1) {
		die("pledge:");
	}
#endif /* __OpenBSD__ */
}

void
eunveil(const char *path, const char *permissions)
{
	(void)path;
	(void)permissions;

#ifdef __OpenBSD__
	if (unveil(path, permissions) == -1) {
		die("unveil:");
	}
#endif /* __OpenBSD__ */
}

int
timestamp(char *buf, size_t len, time_t t)
{
	struct tm tm;

	if (gmtime_r(&t, &tm) == NULL ||
	    strftime(buf, len, "%a, %d %b %Y %T GMT", &tm) == 0) {
		return 1;
	}

	return 0;
}

int
esnprintf(char *str, size_t size, const char *fmt, ...)
{
	va_list ap;
	int ret;

	va_start(ap, fmt);
	ret = vsnprintf(str, size, fmt, ap);
	va_end(ap);

	return (ret < 0 || (size_t)ret >= size);
}

int
prepend(char *str, size_t size, const char *prefix)
{
	size_t len = strlen(str), prefixlen = strlen(prefix);

	if (len + prefixlen + 1 > size) {
		return 1;
	}

	memmove(str + prefixlen, str, len + 1);
	memcpy(str, prefix, prefixlen);

	return 0;
}

int
spacetok(const char *s, char **t, size_t tlen)
{
	const char *tok;
	size_t i, j, toki, spaces;

	/* fill token-array with NULL-pointers */
	for (i = 0; i < tlen; i++) {
		t[i] = NULL;
	}
	toki = 0;

	/* don't allow NULL string or leading spaces */
	if (!s || *s == ' ') {
		return 1;
	}
start:
	/* skip spaces */
	for (; *s == ' '; s++)
		;

	/* don't allow trailing spaces */
	if (*s == '\0') {
		goto err;
	}

	/* consume token */
	for (tok = s, spaces = 0; ; s++) {
		if (*s == '\\' && *(s + 1) == ' ') {
			spaces++;
			s++;
			continue;
		} else if (*s == ' ') {
			/* end of token */
			goto token;
		} else if (*s == '\0') {
			/* end of string */
			goto token;
		}
	}
token:
	if (toki >= tlen) {
		goto err;
	}
	if (!(t[toki] = malloc(s - tok - spaces + 1))) {
		die("malloc:");
	}
	for (i = 0, j = 0; j < s - tok - spaces + 1; i++, j++) {
		if (tok[i] == '\\' && tok[i + 1] == ' ') {
			i++;
		}
		t[toki][j] = tok[i];
	}
	t[toki][s - tok - spaces] = '\0';
	toki++;

	if (*s == ' ') {
		s++;
		goto start;
	}

	return 0;
err:
	for (i = 0; i < tlen; i++) {
		free(t[i]);
		t[i] = NULL;
	}

	return 1;
}



#define	INVALID  1
#define	TOOSMALL 2
#define	TOOLARGE 3

long long
strtonum(const char *numstr, long long minval, long long maxval,
         const char **errstrp)
{
	long long ll = 0;
	int error = 0;
	char *ep;
	struct errval {
		const char *errstr;
		int err;
	} ev[4] = {
		{ NULL,		0 },
		{ "invalid",	EINVAL },
		{ "too small",	ERANGE },
		{ "too large",	ERANGE },
	};

	ev[0].err = errno;
	errno = 0;
	if (minval > maxval) {
		error = INVALID;
	} else {
		ll = strtoll(numstr, &ep, 10);
		if (numstr == ep || *ep != '\0')
			error = INVALID;
		else if ((ll == LLONG_MIN && errno == ERANGE) || ll < minval)
			error = TOOSMALL;
		else if ((ll == LLONG_MAX && errno == ERANGE) || ll > maxval)
			error = TOOLARGE;
	}
	if (errstrp != NULL)
		*errstrp = ev[error].errstr;
	errno = ev[error].err;
	if (error)
		ll = 0;

	return ll;
}

/*
 * This is sqrt(SIZE_MAX+1), as s1*s2 <= SIZE_MAX
 * if both s1 < MUL_NO_OVERFLOW and s2 < MUL_NO_OVERFLOW
 */
#define MUL_NO_OVERFLOW	((size_t)1 << (sizeof(size_t) * 4))

void *
reallocarray(void *optr, size_t nmemb, size_t size)
{
	if ((nmemb >= MUL_NO_OVERFLOW || size >= MUL_NO_OVERFLOW) &&
	    nmemb > 0 && SIZE_MAX / nmemb < size) {
		errno = ENOMEM;
		return NULL;
	}
	return realloc(optr, size * nmemb);
}

int
buffer_appendf(struct buffer *buf, const char *suffixfmt, ...)
{
	va_list ap;
	int ret;

	va_start(ap, suffixfmt);
	ret = vsnprintf(buf->data + buf->len,
	                sizeof(buf->data) - buf->len, suffixfmt, ap);
	va_end(ap);

	if (ret < 0 || (size_t)ret >= (sizeof(buf->data) - buf->len)) {
		/* truncation occured, discard and error out */
		memset(buf->data + buf->len, 0,
		       sizeof(buf->data) - buf->len);
		return 1;
	}

	/* increase buffer length by number of bytes written */
	buf->len += ret;

	return 0;
}
