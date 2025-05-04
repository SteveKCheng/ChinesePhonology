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
args = parser.parse_args()

font = ttLib.TTFont(args.file, lazy=True)

outputFile = sys.stdout
if args.output is not None:
    outputFile = open(args.output, "w", encoding='utf-8')

glyphOrder = font.getGlyphOrder()
glyphSet = font.getGlyphSet()

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

def pf(text: str):
    print(text, file=outputFile)

pf("""<html xmlns="http://www.w3.org/1999/xhtml">""")
pf("""<head>""")
pf(f"""<title>Glyphs from {args.file}</title>""")
pf("""<style type="text/css">""")
pf("""
div.grid {
    display: grid;
    gap: 1rem;
    grid-template-columns: repeat(auto-fit, minmax(6em, 1fr));
}
div.cell {
    display: flex;
    flex-direction: column;
}
span.name {
    display: inline-box;
}
""")
pf(f"""
div.cell > svg {{
    width: {cssWidth};
    height: {cssHeight};
}}
""")   
pf("""</style>""")
pf("""</head>""")

pf("""<body>""")
pf("""<div class="grid">""")

emptyGlyphs = 0

for glyphName in glyphOrder:
    glyph = glyphSet[glyphName]

    # Ignore empty glyphs
    if glyph.width == 0 or glyph.height == 0:
        emptyGlyphs += 1
        continue

    pen = SVGPathPen(glyphSet)
    glyph.draw(pen)

    # Note: SVG's coordinate system has the positive y-axis pointing downwards.
    # So, invert the image, and then the lowest y-coordinate (in the SVG system)
    # becomes -fontYMax (rather than fontYMin originally).
    svgXml = [
        f"""<svg viewBox="{fontXMin} {-fontYMax} {fontWidth} {fontHeight}" xmlns="http://www.w3.org/2000/svg">""",
        """<g transform="scale(1 -1)">""",
        f"""<path d={xmlQuoteAttr(pen.getCommands())}>""",
        """</g>""",
        """</svg>"""
    ]
    
    pf("""<div class="cell">""")
    pf(f"""<span class="name">{xmlEscape(glyphName)}</span>""")
    pf("".join(svgXml))
    pf("""</div>""")

pf("""</div>""")
pf("""</body>""")
pf("""</html>""")
