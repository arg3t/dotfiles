/* See LICENSE file for copyright and license details. */
#ifndef HTTP_H
#define HTTP_H

#include <limits.h>
#include <sys/socket.h>

#include "config.h"
#include "server.h"
#include "util.h"

enum req_field {
	REQ_HOST,
	REQ_RANGE,
	REQ_IF_MODIFIED_SINCE,
	NUM_REQ_FIELDS,
};

extern const char *req_field_str[];

enum req_method {
	M_GET,
	M_HEAD,
	NUM_REQ_METHODS,
};

extern const char *req_method_str[];

struct request {
	enum req_method method;
	char path[PATH_MAX];
	char query[FIELD_MAX];
	char fragment[FIELD_MAX];
	char field[NUM_REQ_FIELDS][FIELD_MAX];
};

enum status {
	S_OK                    = 200,
	S_PARTIAL_CONTENT       = 206,
	S_MOVED_PERMANENTLY     = 301,
	S_NOT_MODIFIED          = 304,
	S_BAD_REQUEST           = 400,
	S_FORBIDDEN             = 403,
	S_NOT_FOUND             = 404,
	S_METHOD_NOT_ALLOWED    = 405,
	S_REQUEST_TIMEOUT       = 408,
	S_RANGE_NOT_SATISFIABLE = 416,
	S_REQUEST_TOO_LARGE     = 431,
	S_INTERNAL_SERVER_ERROR = 500,
	S_VERSION_NOT_SUPPORTED = 505,
};

extern const char *status_str[];

enum res_field {
	RES_ACCEPT_RANGES,
	RES_ALLOW,
	RES_LOCATION,
	RES_LAST_MODIFIED,
	RES_CONTENT_LENGTH,
	RES_CONTENT_RANGE,
	RES_CONTENT_TYPE,
	NUM_RES_FIELDS,
};

extern const char *res_field_str[];

enum res_type {
	RESTYPE_DIRLISTING,
	RESTYPE_ERROR,
	RESTYPE_FILE,
	NUM_RES_TYPES,
};

struct response {
	enum res_type type;
	enum status status;
	char field[NUM_RES_FIELDS][FIELD_MAX];
	char path[PATH_MAX];
	char internal_path[PATH_MAX];
	struct vhost *vhost;
	struct {
		size_t lower;
		size_t upper;
	} file;
};

enum status http_prepare_header_buf(const struct response *, struct buffer *);
enum status http_send_buf(int, struct buffer *);
enum status http_recv_header(int, struct buffer *, int *);
enum status http_parse_header(const char *, struct request *);
void http_prepare_response(const struct request *, struct response *,
                           const struct server *);
void http_prepare_error_response(const struct request *,
                                 struct response *, enum status);

#endif /* HTTP_H */
