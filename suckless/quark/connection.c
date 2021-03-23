/* See LICENSE file for copyright and license details. */
#include <errno.h>
#include <netinet/in.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#include "connection.h"
#include "data.h"
#include "http.h"
#include "server.h"
#include "sock.h"
#include "util.h"

struct worker_data {
	int insock;
	size_t nslots;
	const struct server *srv;
};

void
connection_log(const struct connection *c)
{
	char inaddr_str[INET6_ADDRSTRLEN /* > INET_ADDRSTRLEN */];
	char tstmp[21];

	/* create timestamp */
	if (!strftime(tstmp, sizeof(tstmp), "%Y-%m-%dT%H:%M:%SZ",
	              gmtime(&(time_t){time(NULL)}))) {
		warn("strftime: Exceeded buffer capacity");
		/* continue anyway (we accept the truncation) */
	}

	/* generate address-string */
	if (sock_get_inaddr_str(&c->ia, inaddr_str, LEN(inaddr_str))) {
		warn("sock_get_inaddr_str: Couldn't generate adress-string");
		inaddr_str[0] = '\0';
	}

	printf("%s\t%s\t%s%.*d\t%s\t%s%s%s%s%s\n",
	       tstmp,
	       inaddr_str,
	       (c->res.status == 0) ? "dropped" : "",
	       (c->res.status == 0) ? 0 : 3,
	       c->res.status,
	       c->req.field[REQ_HOST][0] ? c->req.field[REQ_HOST] : "-",
	       c->req.path[0] ? c->req.path : "-",
	       c->req.query[0] ? "?" : "",
	       c->req.query,
	       c->req.fragment[0] ? "#" : "",
	       c->req.fragment);
}

void
connection_reset(struct connection *c)
{
	if (c != NULL) {
		shutdown(c->fd, SHUT_RDWR);
		close(c->fd);
		memset(c, 0, sizeof(*c));
	}
}

void
connection_serve(struct connection *c, const struct server *srv)
{
	enum status s;
	int done;

	switch (c->state) {
	case C_VACANT:
		/*
		 * we were passed a "fresh" connection which should now
		 * try to receive the header, reset buf beforehand
		 */
		memset(&c->buf, 0, sizeof(c->buf));

		c->state = C_RECV_HEADER;
		/* fallthrough */
	case C_RECV_HEADER:
		/* receive header */
		done = 0;
		if ((s = http_recv_header(c->fd, &c->buf, &done))) {
			http_prepare_error_response(&c->req, &c->res, s);
			goto response;
		}
		if (!done) {
			/* not done yet */
			return;
		}

		/* parse header */
		if ((s = http_parse_header(c->buf.data, &c->req))) {
			http_prepare_error_response(&c->req, &c->res, s);
			goto response;
		}

		/* prepare response struct */
		http_prepare_response(&c->req, &c->res, srv);
response:
		/* generate response header */
		if ((s = http_prepare_header_buf(&c->res, &c->buf))) {
			http_prepare_error_response(&c->req, &c->res, s);
			if ((s = http_prepare_header_buf(&c->res, &c->buf))) {
				/* couldn't generate the header, we failed for good */
				c->res.status = s;
				goto err;
			}
		}

		c->state = C_SEND_HEADER;
		/* fallthrough */
	case C_SEND_HEADER:
		if ((s = http_send_buf(c->fd, &c->buf))) {
			c->res.status = s;
			goto err;
		}
		if (c->buf.len > 0) {
			/* not done yet */
			return;
		}

		c->state = C_SEND_BODY;
		/* fallthrough */
	case C_SEND_BODY:
		if (c->req.method == M_GET) {
			if (c->buf.len == 0) {
				/* fill buffer with body data */
				if ((s = data_fct[c->res.type](&c->res, &c->buf,
				                               &c->progress))) {
					/* too late to do any real error handling */
					c->res.status = s;
					goto err;
				}

				/* if the buffer remains empty, we are done */
				if (c->buf.len == 0) {
					break;
				}
			} else {
				/* send buffer */
				if ((s = http_send_buf(c->fd, &c->buf))) {
					/* too late to do any real error handling */
					c->res.status = s;
					goto err;
				}
			}
			return;
		}
		break;
	default:
		warn("serve: invalid connection state");
		return;
	}
err:
	connection_log(c);
	connection_reset(c);
}

static struct connection *
connection_get_drop_candidate(struct connection *connection, size_t nslots)
{
	struct connection *c, *minc;
	size_t i, j, maxcnt, cnt;

	/*
	 * determine the most-unimportant connection 'minc' of the in-address
	 * with most connections; this algorithm has a complexity of O(n²)
	 * in time but is O(1) in space; there are algorithms with O(n) in
	 * time and space, but this would require memory allocation,
	 * which we avoid. Given the simplicity of the inner loop and
	 * relatively small number of slots per thread, this is fine.
	 */
	for (i = 0, minc = NULL, maxcnt = 0; i < nslots; i++) {
		/*
		 * we determine how many connections have the same
		 * in-address as connection[i], but also minimize over
		 * that set with other criteria, yielding a general
		 * minimizer c. We first set it to connection[i] and
		 * update it, if a better candidate shows up, in the inner
		 * loop
		 */
		c = &connection[i];

		for (j = 0, cnt = 0; j < nslots; j++) {
			if (!sock_same_addr(&connection[i].ia,
			                    &connection[j].ia)) {
				continue;
			}
			cnt++;

			/* minimize over state */
			if (connection[j].state < c->state) {
				c = &connection[j];
			} else if (connection[j].state == c->state) {
				/* minimize over progress */
				if (c->state == C_SEND_BODY &&
				    connection[i].res.type != c->res.type) {
					/*
					 * mixed response types; progress
					 * is not comparable
					 *
					 * the res-type-enum is ordered as
					 * DIRLISTING, ERROR, FILE, i.e.
					 * in rising priority, because a
					 * file transfer is most important,
					 * followed by error-messages.
					 * Dirlistings as an "interactive"
					 * feature (that take up lots of
					 * resources) have the lowest
					 * priority
					 */
					if (connection[i].res.type <
					    c->res.type) {
						c = &connection[j];
					}
				} else if (connection[j].progress <
				           c->progress) {
					/*
					 * for C_SEND_BODY with same response
					 * type, C_RECV_HEADER and C_SEND_BODY
					 * it is sufficient to compare the
					 * raw progress
					 */
					c = &connection[j];
				}
			}
		}

		if (cnt > maxcnt) {
			/* this run yielded an even greedier in-address */
			minc = c;
			maxcnt = cnt;
		}
	}

	return minc;
}

struct connection *
connection_accept(int insock, struct connection *connection, size_t nslots)
{
	struct connection *c = NULL;
	size_t i;

	/* find vacant connection (i.e. one with no fd assigned to it) */
	for (i = 0; i < nslots; i++) {
		if (connection[i].fd == 0) {
			c = &connection[i];
			break;
		}
	}
	if (i == nslots) {
		/*
		 * all our connection-slots are occupied and the only
		 * way out is to drop another connection, because not
		 * accepting this connection just kicks this can further
		 * down the road (to the next queue_wait()) without
		 * solving anything.
		 *
		 * This may sound bad, but this case can only be hit
		 * either when there's a (D)DoS-attack or a massive
		 * influx of requests. The latter is impossible to solve
		 * at this moment without expanding resources, but the
		 * former has certain characteristics allowing us to
		 * handle this gracefully.
		 *
		 * During an attack (e.g. Slowloris, R-U-Dead-Yet, Slow
		 * Read or just plain flooding) we can not see who is
		 * waiting to be accept()ed.
		 * However, an attacker usually already has many
		 * connections open (while well-behaved clients could
		 * do everything with just one connection using
		 * keep-alive). Inferring a likely attacker-connection
		 * is an educated guess based on which in-address is
		 * occupying the most connection slots. Among those,
		 * connections in early stages (receiving or sending
		 * headers) are preferred over connections in late
		 * stages (sending body).
		 *
		 * This quantitative approach effectively drops malicious
		 * connections while preserving even long-running
		 * benevolent connections like downloads.
		 */
		c = connection_get_drop_candidate(connection, nslots);
		c->res.status = 0;
		connection_log(c);
		connection_reset(c);
	}

	/* accept connection */
	if ((c->fd = accept(insock, (struct sockaddr *)&c->ia,
	                    &(socklen_t){sizeof(c->ia)})) < 0) {
		if (errno != EAGAIN && errno != EWOULDBLOCK) {
			/*
			 * this should not happen, as we received the
			 * event that there are pending connections here
			 */
			warn("accept:");
		}
		return NULL;
	}

	/* set socket to non-blocking mode */
	if (sock_set_nonblocking(c->fd)) {
		/* we can't allow blocking sockets */
		return NULL;
	}

	return c;
}
