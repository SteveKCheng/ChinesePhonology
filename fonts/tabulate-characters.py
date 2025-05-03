#!/usr/bin/env python
import sys
import unicodedata
import argparse
from typing import Optional

parser = argparse.ArgumentParser(
    description="Tabulate Unicode characters (codepoints) used in input files")
parser.add_argument("files", nargs='*', help="input files")
parser.add_argument("-o", "--output", default=None, help="output listing of characters")

formatGroup = parser.add_mutually_exclusive_group()
formatGroup.add_argument("--text", dest='format', const=None, action='store_const', 
                         help="input is plain text in UTF-8")
formatGroup.add_argument("--xml", dest='format', const='xml', action='store_const',
                         help="input is XML")
formatGroup.add_argument("--xhtml", dest='format', const='xhtml', action='store_const',
                         help="input is XHTML")

parser.add_argument("--lang", dest='langs', action='append', 
                    help="restrict tabulation to given language (XML input only)")

args = parser.parse_args()

charTable = {}

def processPlainText(inputFile, charTable: dict):
    for line in inputFile:
        for c in line:
            charTable[c] = charTable.get(c, 0) + 1

def processXml(inputFilePath, isHtml: bool, charTable: dict):
    import xml.sax
    import xml.sax.handler
    xmlNs = "http://www.w3.org/XML/1998/namespace"

    class SaxHandler(xml.sax.handler.ContentHandler):
        def __init__(self, langs:Optional[set], isHtml: bool, charTable: dict):
            self._langsStack = [ None ]
            self._charTable = charTable
            self._admissibleLangs = langs
            self._isHtml = isHtml

        def startElementNS(self, name, qname, attrs):
            oldLang = self._langsStack[-1]
            if isHtml: oldLang = attrs.get((None, "lang"), oldLang)
            newLang = attrs.get((xmlNs, "lang"), oldLang)
            self._langsStack.append(newLang)

        def characters(self, text):
            if self._admissibleLangs is None or self._langsStack[-1] in self._admissibleLangs:
                for c in text:
                    self._charTable[c] = charTable.get(c, 0) + 1

        def endElementNS(self, name, qname):
            self._langsStack.pop()

    langs = set(args.langs) if args.langs is not None else None

    parser = xml.sax.make_parser()
    parser.setFeature(xml.sax.handler.feature_namespaces, True)
    parser.setContentHandler(SaxHandler(langs, isHtml, charTable))
    parser.parse(inputFilePath)

for path in args.files:
    if args.format == 'xhtml' or args.format == 'xml':
        processXml(path, args.format == 'xhtml', charTable)
    else:
        with open(path, "r", encoding='utf-8') as inputFile:
            processPlainText(inputFile, charTable)

outputFile = sys.stdout
if args.output is not None:
    outputFile = open(args.output, "w", encoding='utf-8')

for k in sorted(charTable.keys()):
    count = charTable[k]
    cat = unicodedata.category(k)
    char = k if cat != "Cc" else "(Cc)"
    print(f"{ord(k):04X} # {char} {count} {unicodedata.name(k, '')}", file=outputFile)
