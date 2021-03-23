/* See LICENSE file for copyright and license details. */
#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#include "data.h"
#include "http.h"
#include "util.h"

enum status (* const data_fct[])(const struct response *,
                                 struct buffer *, size_t *) = {
	[RESTYPE_DIRLISTING] = data_prepare_dirlisting_buf,
	[RESTYPE_ERROR]      = data_prepare_error_buf,
	[RESTYPE_FILE]       = data_prepare_file_buf,
};

static int
compareent(const struct dirent **d1, const struct dirent **d2)
{
	int v;

	v = ((*d2)->d_type == DT_DIR ? 1 : -1) -
	    ((*d1)->d_type == DT_DIR ? 1 : -1);
	if (v) {
		return v;
	}

	return strcmp((*d1)->d_name, (*d2)->d_name);
}

static char *
suffix(int t)
{
	switch (t) {
	case DT_FIFO: return "|";
	case DT_DIR:  return "/";
	case DT_LNK:  return "@";
	case DT_SOCK: return "=";
	}

	return "";
}

static void
html_escape(const char *src, char *dst, size_t dst_siz)
{
	const struct {
		char c;
		char *s;
	} escape[] = {
		{ '&',  "&amp;"  },
		{ '<',  "&lt;"   },
		{ '>',  "&gt;"   },
		{ '"',  "&quot;" },
		{ '\'', "&#x27;" },
	};
	size_t i, j, k, esclen;

	for (i = 0, j = 0; src[i] != '\0'; i++) {
		for (k = 0; k < LEN(escape); k++) {
			if (src[i] == escape[k].c) {
				break;
			}
		}
		if (k == LEN(escape)) {
			/* no escape char at src[i] */
			if (j == dst_siz - 1) {
				/* silent truncation */
				break;
			} else {
				dst[j++] = src[i];
			}
		} else {
			/* escape char at src[i] */
			esclen = strlen(escape[k].s);

			if (j >= dst_siz - esclen) {
				/* silent truncation */
				break;
			} else {
				memcpy(&dst[j], escape[k].s, esclen);
				j += esclen;
			}
		}
	}
	dst[j] = '\0';
}

enum status
data_prepare_dirlisting_buf(const struct response *res,
                            struct buffer *buf, size_t *progress)
{
	enum status s = 0;
	struct dirent **e;
	size_t i;
	int dirlen;
	char esc[PATH_MAX /* > NAME_MAX */ * 6]; /* strlen("&...;") <= 6 */

	/* reset buffer */
	memset(buf, 0, sizeof(*buf));

	/* read directory */
	if ((dirlen = scandir(res->internal_path, &e, NULL, compareent)) < 0) {
		return S_FORBIDDEN;
	}

	if (*progress == 0) {
		/* write listing header (sizeof(esc) >= PATH_MAX) */
		html_escape(res->path, esc, MIN(PATH_MAX, sizeof(esc)));
		if (buffer_appendf(buf,
		                   "<!DOCTYPE html>\n<html>\n\t<head>"
		                   "<title>Index of %s</title></head>\n"
		                   "\t<body>\n\t\t<a href=\"..\">..</a>",
		                   esc) < 0) {
			s = S_REQUEST_TIMEOUT;
			goto cleanup;
		}
	}

	/* listing entries */
	for (i = *progress; i < (size_t)dirlen; i++) {
		/* skip hidden files, "." and ".." */
		if (e[i]->d_name[0] == '.') {
			continue;
		}

		/* entry line */
		html_escape(e[i]->d_name, esc, sizeof(esc));
		if (buffer_appendf(buf,
		                   "<br />\n\t\t<a href=\"%s%s\">%s%s</a>",
		                   esc,
		                   (e[i]->d_type == DT_DIR) ? "/" : "",
		                   esc,
		                   suffix(e[i]->d_type))) {
			/* buffer full */
			break;
		}
	}
	*progress = i;

	if (*progress == (size_t)dirlen) {
		/* listing footer */
		if (buffer_appendf(buf, "\n\t</body>\n</html>\n") < 0) {
			s = S_REQUEST_TIMEOUT;
			goto cleanup;
		}
		(*progress)++;
	}

cleanup:
	while (dirlen--) {
		free(e[dirlen]);
	}
	free(e);

	return s;
}

enum status
data_prepare_error_buf(const struct response *res, struct buffer *buf,
                   size_t *progress)
{
	/* reset buffer */
	memset(buf, 0, sizeof(*buf));

	if (*progress == 0) {
		/* write error body */
		if (buffer_appendf(buf,
		                   "<!DOCTYPE html>\n<html>\n\t<head>\n"
		                   "\t\t<title>%d %s</title>\n\t</head>\n"
		                   "\t<body>\n\t\t<h1>%d %s</h1>\n"
		                   "\t</body>\n</html>\n",
		                   res->status, status_str[res->status],
			           res->status, status_str[res->status])) {
			return S_INTERNAL_SERVER_ERROR;
		}
		(*progress)++;
	}

	return 0;
}

enum status
data_prepare_file_buf(const struct response *res, struct buffer *buf,
                  size_t *progress)
{
	FILE *fp;
	enum status s = 0;
	ssize_t r;
	size_t remaining;

	/* reset buffer */
	memset(buf, 0, sizeof(*buf));

	/* open file */
	if (!(fp = fopen(res->internal_path, "r"))) {
		s = S_FORBIDDEN;
		goto cleanup;
	}

	/* seek to lower bound + progress */
	if (fseek(fp, res->file.lower + *progress, SEEK_SET)) {
		s = S_INTERNAL_SERVER_ERROR;
		goto cleanup;
	}

	/* read data into buf */
	remaining = res->file.upper - res->file.lower + 1 - *progress;
	while ((r = fread(buf->data + buf->len, 1,
	                  MIN(sizeof(buf->data) - buf->len,
			  remaining), fp))) {
		if (r < 0) {
			s = S_INTERNAL_SERVER_ERROR;
			goto cleanup;
		}
		buf->len += r;
		*progress += r;
		remaining -= r;
	}

cleanup:
	if (fp) {
		fclose(fp);
	}

	return s;
}
