#ifndef QUEUE_H
#define QUEUE_H

#include <stddef.h>

#ifdef __linux__
	#include <sys/epoll.h>

	typedef struct epoll_event queue_event;
#else
	#include <sys/types.h>
	#include <sys/event.h>
	#include <sys/time.h>

	typedef struct kevent queue_event;
#endif

enum queue_event_type {
	QUEUE_EVENT_IN,
	QUEUE_EVENT_OUT,
};

int queue_create(void);
int queue_add_fd(int, int, enum queue_event_type, int, const void *);
int queue_mod_fd(int, int, enum queue_event_type, const void *);
int queue_rem_fd(int, int);
ssize_t queue_wait(int, queue_event *, size_t);

void *queue_event_get_data(const queue_event *);

int queue_event_is_error(const queue_event *e);

#endif /* QUEUE_H */
