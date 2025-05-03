#!/usr/bin/env python
import sys
import unicodedata
import argparse

parser = argparse.ArgumentParser(
    description="Tabulate Unicode characters (codepoints) used in input files")
parser.add_argument("files", nargs='*', help="input files in UTF-8 encoding")
parser.add_argument("-o", "--output", default=None, help="output listing of characters")
args = parser.parse_args()

charTable = {}

for path in args.files:
    inputFile = open(path, "r", encoding='utf-8')

    for line in inputFile:
        for c in line:
            charTable[c] = charTable.get(c, 0) + 1

outputFile = sys.stdout
if args.output is not None:
    outputFile = open(args.output, "w", encoding='utf-8')

for k in sorted(charTable.keys()):
    count = charTable[k]
    cat = unicodedata.category(k)
    char = k if cat != "Cc" else "(Cc)"
    print(f"{ord(k):04X} # {char} {count} {unicodedata.name(k, '')}", file=outputFile)
