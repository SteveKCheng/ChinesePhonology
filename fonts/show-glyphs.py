#!/usr/bin/env python
import fontTools.ttLib as ttLib
from fontTools.pens.svgPathPen import SVGPathPen
from xml.sax.saxutils import escape as xmlEscape
from xml.sax.saxutils import quoteattr as xmlQuoteAttr
import unicodedata
import argparse
import sys
import re

parser = argparse.ArgumentParser(
    description="Show the glyphs of an TrueType/OpenType font in an HTML page")
parser.add_argument("file", metavar="font-file", help="path to TrueType/OpenType font file")
parser.add_argument("-o", "--output", metavar="file", help="path to HTML output file")
parser.add_argument("-c", "--columns", metavar="n", type=int, default=10, help="number of columns in output table")
args = parser.parse_args()

font = ttLib.TTFont(args.file, lazy=True)

outputFile = sys.stdout
if args.output is not None:
    outputFile = open(args.output, "w", encoding='utf-8')

def pf(text: str):
    print(text, file=outputFile)

pf("""<html xmlns="http://www.w3.org/1999/xhtml">""")
pf("""<head>""")
pf(f"""<title>Glyphs from {args.file}</title>""")
pf("""</head>""")
pf("""<body>""")
pf("""<table>""")

glyphOrder = font.getGlyphOrder()
glyphSet = font.getGlyphSet()

numColumns = args.columns
numRows = (len(glyphOrder) + (numColumns-1)) // numColumns

# Number of font design units per em
fontHead = font['head']
fduScale = fontHead.unitsPerEm

fontXMin = fontHead.xMin
fontYMax = fontHead.xMax
fontYMin = fontHead.yMin
fontYMax = fontHead.yMax

# Compute dimensions of output image, while maintaining the same aspect ratio
fontHeight = fontHead.yMax - fontHead.yMin
fontWidth = fontHead.xMax - fontHead.xMin
cssScale = 2.0
cssHeight = f"{(fontHeight / fduScale * cssScale):.2f}em"
cssWidth = f"{(fontWidth / fduScale * cssScale):.2f}em"

for i in range(numRows):
    rowGlyphNames = []
    rowGlyphGraphics = []

    # Render glyphs to SVG
    for j in range(numColumns):
        glyphIndex = i*numColumns + j
        if glyphIndex >= len(glyphOrder):
            break

        glyphName = glyphOrder[glyphIndex]
        glyph = glyphSet[glyphName]
        pen = SVGPathPen(glyphSet)
        glyph.draw(pen)

        # Note: SVG's coordinate system has the positive y-axis pointing downwards.
        # So, invert the image, and then the lowest y-coordinate (in the SVG system)
        # becomes -fontYMax (rather than fontYMin originally).
        svgXml = [
            f"""<svg width="{cssWidth}" height="{cssHeight}" viewBox="{fontXMin} {-fontYMax} {fontWidth} {fontHeight}" xmlns="http://www.w3.org/2000/svg">""",
            """<g transform="scale(1 -1)">""",
            f"""<path d={xmlQuoteAttr(pen.getCommands())}>""",
            """</g>""",
            """</svg>"""
        ]
        
        rowGlyphNames.append(glyphName)
        rowGlyphGraphics.append("".join(svgXml))

    # Output associated row of glyph names
    pf("""<tr>""")
    for j in range(numColumns):
        pf("""<td>""")
        if j < len(rowGlyphNames):
            pf(xmlEscape(rowGlyphNames[j]))
        pf("""</td>""")
    pf("""</tr>""")

    # Output row of glyph graphics
    pf("""<tr>""")
    for j in range(numColumns):
        pf("""<td>""")
        if j < len(rowGlyphGraphics):
            pf(rowGlyphGraphics[j])
        pf("""</svg>""")        
        pf("""</td>""")
    pf("""</tr>""")

pf("""</table>""")
pf("""</body>""")
pf("""</html>""")
