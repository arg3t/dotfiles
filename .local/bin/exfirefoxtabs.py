#! /usr/bin/python

"""
List all Firefox tabs with title and URL

Supported input: json or jsonlz4 recovery files
Default output: title (URL)
Output format can be specified as argument
"""

import sys
import os
import pathlib
import lz4.block
import json

path = pathlib.Path.home().joinpath('.mozilla/firefox')
files = path.glob(os.environ['FIREFOX_PROFILE'] + '/sessionstore-backups/recovery.js*')

for f in files:
    b = f.read_bytes()
    if b[:8] == b'mozLz40\0':
        b = lz4.block.decompress(b[8:])
    j = json.loads(b)
    for w in j['windows']:
        for t in w['tabs']:
            i = t['index'] - 1
            print(t['entries'][i]['url'])
