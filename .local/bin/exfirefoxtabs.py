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

class Node:
    def __init__(self, url, lastAccessed):
        self.url = url
        self.lastAccessed = lastAccessed
        self.left = None
        self.right = None
        self.parent = None

    def insert(self, node):
        if node.lastAccessed > self.lastAccessed:
            if self.right:
                self.right.insert(node)
            else:
                self.right = node
                node.parent = self
        else:
            if self.left:
                self.left.insert(node)
            else:
                self.left = node
                node.parent = self

    def print(self):
        if self.right: # Print from high to low
            self.right.print()
        print(self.url)
        if self.left:
            self.left.print()

def main():
    path = pathlib.Path('/dev/shm/firefox-' + os.environ['FIREFOX_PROFILE'] + "-" + os.environ['USER'] + '/sessionstore-backups')
    files = path.glob('recovery.js*')
    tree = None

    for f in files:
        b = f.read_bytes()
        if b[:8] == b'mozLz40\0':
            b = lz4.block.decompress(b[8:])
        j = json.loads(b)
        for w in j['windows']:
            for t in w['tabs']:
                i = t['index'] - 1
                node = Node(t['entries'][i]['url'], t['lastAccessed'])
                if tree:
                    tree.insert(node)
                else:
                    tree = node

    if tree:
        tree.print()

if __name__ == "__main__":
    main()


