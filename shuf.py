#!/usr/bin/python
import sys
import random
import os
import re


def main(args):
    last_arg = ""
    limit = None
    for arg in args:
        if last_arg == "-n":
            limit = int(arg)
        last_arg = ""
        if arg == "-n":
            last_arg = arg

    if not sys.stdin.isatty():
        all_lines = list(map(strip_newlines, sys.stdin.readlines()))
    else:
        all_lines = []
        for arg in args:
            if os.path.isfile(arg):
                fp = open(arg, "r")
                for line in fp.readlines():
                    all_lines.append(strip_newlines(line))
                fp.close()

    random.shuffle(all_lines)

    if limit is None:
        limit = len(all_lines)

    for i in range(0, limit):
        print(all_lines[i])


def strip_newlines(s):
    return re.sub(r"(\n|\r\n)$", "", s)


main(sys.argv[1:])
