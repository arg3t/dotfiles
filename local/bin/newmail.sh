#!/bin/sh
mbsync $1
notmuch new
notmuch tag --batch --input=/home/yigit/.notmuch_tag
