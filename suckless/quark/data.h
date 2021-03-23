/* See LICENSE file for copyright and license details. */
#ifndef DATA_H
#define DATA_H

#include "http.h"
#include "util.h"

extern enum status (* const data_fct[])(const struct response *,
                                        struct buffer *, size_t *);

enum status data_prepare_dirlisting_buf(const struct response *,
                                    struct buffer *, size_t *);
enum status data_prepare_error_buf(const struct response *,
                                   struct buffer *, size_t *);
enum status data_prepare_file_buf(const struct response *,
                              struct buffer *, size_t *);

#endif /* DATA_H */
