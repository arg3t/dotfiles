#!/bin/sh

set -eu
export POSIXLY_CORRECT=1

i=1
while test "$i" -lt 50; do
	echo "$i"
	i=$((i + 1))
done > tmp.log

(sleep 1; printf '\033[5;2~'; sleep 1; ) \
	| ./ptty ./scroll tail -fn 50 tmp.log > out.log

cmp out.log up.log
