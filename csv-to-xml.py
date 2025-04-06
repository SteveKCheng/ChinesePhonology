import csv
import sys
import argparse
from xml.sax.saxutils import quoteattr

parser = argparse.ArgumentParser()
parser.add_argument("file", help="input CSV file")
parser.add_argument("-d", "--dialect", default='excel', help="dialect of CSV")
parser.add_argument("-o", "--output", default=None, help="output XML file")
args = parser.parse_args()

inputFile = open(args.file, "r", encoding='utf-8')
outputFile = sys.stdout
if args.output is not None:
    outputFile = open(args.output, "w", encoding='utf-8')

csvFile = csv.reader(inputFile, dialect=args.dialect)

print('<?xml version="1.0" encoding="utf-8" standalone="yes"?>', file=outputFile)
print("<data>", file=outputFile)

headers = None
for line in csvFile:
    if len(line) == 0 or line[0].startswith("#"):
        continue
 
    if headers is None:
        headers = line
    else:
        attrs = zip(headers, line)
        outputFile.write("  <item ")
        for k, v in attrs:
            if k != "" and v != "":
                outputFile.write(f"{k}={quoteattr(v)} ")
        outputFile.write("/>\n")

print("</data>", file=outputFile)
