/* See LICENSE file for copyright and license details. */
#include <errno.h>
#include <pthread.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#include "connection.h"
#include "queue.h"
#include "server.h"
#include "util.h"

struct worker_data {
	int insock;
	size_t nslots;
	const struct server *srv;
};

static void *
server_worker(void *data)
{
	queue_event *event = NULL;
	struct connection *connection, *c, *newc;
	struct worker_data *d = (struct worker_data *)data;
	int qfd;
	ssize_t nready;
	size_t i;

	/* allocate connections */
	if (!(connection = calloc(d->nslots, sizeof(*connection)))) {
		die("calloc:");
	}

	/* create event queue */
	if ((qfd = queue_create()) < 0) {
		exit(1);
	}

	/* add insock to the interest list (with data=NULL) */
	if (queue_add_fd(qfd, d->insock, QUEUE_EVENT_IN, 1, NULL) < 0) {
		exit(1);
	}

	/* allocate event array */
	if (!(event = reallocarray(event, d->nslots, sizeof(*event)))) {
		die("reallocarray:");
	}

	for (;;) {
		/* wait for new activity */
		if ((nready = queue_wait(qfd, event, d->nslots)) < 0) {
			exit(1);
		}

		/* handle events */
		for (i = 0; i < (size_t)nready; i++) {
			c = queue_event_get_data(&event[i]);

			if (queue_event_is_error(&event[i])) {
				if (c != NULL) {
					queue_rem_fd(qfd, c->fd);
					c->res.status = 0;
					connection_log(c);
					connection_reset(c);
				}

				continue;
			}

			if (c == NULL) {
				/* add new connection to the interest list */
				if (!(newc = connection_accept(d->insock,
				                               connection,
				                               d->nslots))) {
					/*
					 * the socket is either blocking
					 * or something failed.
					 * In both cases, we just carry on
					 */
					continue;
				}

				/*
				 * add event to the interest list
				 * (we want IN, because we start
				 * with receiving the header)
				 */
				if (queue_add_fd(qfd, newc->fd,
				                 QUEUE_EVENT_IN,
						 0, newc) < 0) {
					/* not much we can do here */
					continue;
				}
			} else {
				/* serve existing connection */
				connection_serve(c, d->srv);

				if (c->fd == 0) {
					/* we are done */
					memset(c, 0, sizeof(struct connection));
					continue;
				}

				/*
				 * rearm the event based on the state
				 * we are "stuck" at
				 */
				switch(c->state) {
				case C_RECV_HEADER:
					if (queue_mod_fd(qfd, c->fd,
					                 QUEUE_EVENT_IN,
					                 c) < 0) {
						connection_reset(c);
						break;
					}
					break;
				case C_SEND_HEADER:
				case C_SEND_BODY:
					if (queue_mod_fd(qfd, c->fd,
					                 QUEUE_EVENT_OUT,
					                 c) < 0) {
						connection_reset(c);
						break;
					}
					break;
				default:
					break;
				}
			}
		}
	}

	return NULL;
}

void
server_init_thread_pool(int insock, size_t nthreads, size_t nslots,
                        const struct server *srv)
{
	pthread_t *thread = NULL;
	struct worker_data *d = NULL;
	size_t i;

	/* allocate worker_data structs */
	if (!(d = reallocarray(d, nthreads, sizeof(*d)))) {
		die("reallocarray:");
	}
	for (i = 0; i < nthreads; i++) {
		d[i].insock = insock;
		d[i].nslots = nslots;
		d[i].srv = srv;
	}

	/* allocate and initialize thread pool */
	if (!(thread = reallocarray(thread, nthreads, sizeof(*thread)))) {
		die("reallocarray:");
	}
	for (i = 0; i < nthreads; i++) {
		if (pthread_create(&thread[i], NULL, server_worker, &d[i]) != 0) {
			if (errno == EAGAIN) {
				die("You need to run as root or have "
				    "CAP_SYS_RESOURCE set, or are trying "
				    "to create more threads than the "
				    "system can offer");
			} else {
				die("pthread_create:");
			}
		}
	}

	/* wait for threads */
	for (i = 0; i < nthreads; i++) {
		if ((errno = pthread_join(thread[i], NULL))) {
			warn("pthread_join:");
		}
	}
}
