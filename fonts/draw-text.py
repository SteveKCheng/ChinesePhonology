#!/usr/bin/env python
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.misc.transform import Offset
from xml.sax.saxutils import escape as xmlEscape
from xml.sax.saxutils import quoteattr as xmlQuoteAttr
from typing import NamedTuple, Optional
import contextlib
import uharfbuzz as hb
import argparse
import re
import sys
import logging

class CssLength(NamedTuple):
    number: float
    units: str
    def __str__(self):
        return f"{self.number}{self.units}"

def parseCssLength(text: str) -> CssLength:
    # https://www.w3.org/TR/SVG11/types.html#DataTypeLength
    # https://www.w3.org/TR/2008/REC-CSS2-20080411/syndata.html#length-units
    # FIXME support "ex" unit and "%"
    m = re.match("^([0-9]+|[0-9]*\.[0-9]+)\s*(em|px|in|cm|mm|pt|pc)?$", text)
    if m is None:
         raise argparse.ArgumentTypeError("invalid CSS/SVG length specifier: %s" % text)
    return CssLength(float(m.group(1)), m.group(2))

parser = argparse.ArgumentParser(
      description="Render text in an TrueType/OpenType font to SVG")
parser.add_argument("font", metavar="font-file", help="path to TrueType/OpenType font file")
parser.add_argument("-o", "--output", metavar="file", help="path to SVG output file")
parser.add_argument("-t", "--text", default="Hello, world!", metavar="str", help="the text to show")
parser.add_argument("-d", "--direction", default='ltr', choices=('ltr', 'rtl', 'ttb', 'btt'), help="text direction")
parser.add_argument("-s", "--scale", type=parseCssLength, default=None, metavar="length", 
                    help="size of font in CSS/SVG syntax")
parser.add_argument("--log", action='store_true', help="enable debugging logs")
args = parser.parse_args()

if args.log:
    logging.basicConfig(level=logging.INFO)
else:
    logging.basicConfig(handlers=[logging.NullHandler()])

logger = logging.getLogger(__name__)

def shapeText(fontPath: str, 
              direction: str, 
              scale: Optional[CssLength],
              svgPath: Optional[str], 
              text: str):

    blob = hb.Blob.from_file_path(fontPath)

    face = hb.Face(blob)
    fontUnitsPerEm = face.upem

    font = hb.Font(face)

    buf = hb.Buffer()
    buf.direction = direction
    buf.add_str(text)
    buf.guess_segment_properties()

    features = {}
    hb.shape(font, buf, features)

    # Current pen position after drawing each glyph.
    #
    # Note that the positive y direction is up, same as Postscript
    # (and standard math convention) while being inverted from SVG 
    # (and most image formats).
    #
    # So when HarffBuzz lays out text top-to-bottom, penY becomes
    # increasingly negative.
    #
    # The coordinates are measured in font design units.
    penX, penY = 0, 0

    # Separate the path commands for each cluster.
    # The commands are all generated under the same PostScript coordinate system.
    clusterCommands = []
    clusterPen = None
    prevCluster = None

    # Flush commands for preceding cluster if any, and prepare to render a new cluster
    def commitCluster():
        nonlocal clusterPen, clusterCommands
        if clusterPen is not None:
            clusterCommands.append(clusterPen.getCommands())
        clusterPen = SVGPathPen(glyphSet=None)

    for glyphInfo, pos in zip(buf.glyph_infos, buf.glyph_positions):
        glyphId = glyphInfo.codepoint

        # uharfbuzz does not allow manually setting the values/indices associated 
        # with each "cluster" in the source string.  Depending on how Python
        # is currently representing the (Unicode) string text, HarfBuzz may
        # have cluster values set to the UTF-8, UTF-16 or UTF-32 indices from
        # the string.  All we know is that they should be monotonically increasing
        # (resp. decreasing if the visual text direction is reverse) as we move
        # from cluster to cluster.
        cluster = glyphInfo.cluster

        logger.info(f"gid={glyphId} cluster={cluster}")
        logger.info(f"xAdv={pos.x_advance} yAdv={pos.y_advance} xOff={pos.x_offset} yOff={pos.y_offset}")

        if cluster != prevCluster:
            commitCluster()

        # The origin of the glyph is essentially arbitrary and decided by the font. 
        # We must translate so that the current pen position is at the origin.
        glyphPen = TransformPen(clusterPen, Offset(penX + pos.x_offset, penY + pos.y_offset))

        # HarfBuzz interprets the font outlines and calls back into the methods
        # of the Python code implementing currentPen, which in turn generates
        # the SVG commands. 
        font.draw_glyph_with_pen(glyphId, glyphPen)

        penX += pos.x_advance
        penY += pos.y_advance
        prevCluster = cluster

    commitCluster()

    fontExtents = font.get_font_extents(buf.direction)
    lineHeight = fontExtents.ascender - fontExtents.descender + fontExtents.line_gap

    # Horizontal writing direction
    if buf.direction in ('ltr', 'rtl'):
        imageWidth = penX
        imageHeight = lineHeight
        # Shift lowest point of descender to y=0
        imageOffsetX = 0
        imageOffsetY = -fontExtents.descender
    # Vertical writing direction
    else:
        imageWidth = lineHeight
        imageHeight = -penY
        # Shift leftmost point of descender to x=0,
        # and the whole image up so y=0 is the ending boundary for the text.
        imageOffsetX = -fontExtents.descender
        imageOffsetY = -penY

    logger.info(f"ascender={fontExtents.ascender} descender={fontExtents.descender} lineGap={fontExtents.line_gap}" )
    logger.info(f"imageWidth={imageWidth} imageHeight={imageHeight} fontUnitsPerEm={fontUnitsPerEm}")

    if scale is not None:
        # Note: imageHeight (wrt. imageWidth for vertical writing) is not necessarily equal to fontUnitsPerEm.
        # It may be bigger or smaller.  But fontUnitsPerEm is conventionally used to measure font sizes,
        # e.g. a font at a 72pt means its em square is 72pt (= 1 inch). 
        # See https://www.thomasphinney.com/2011/03/point-size/
        scaledWidth = CssLength(scale.number * imageWidth / fontUnitsPerEm, scale.units)
        scaledHeight = CssLength(scale.number * imageHeight / fontUnitsPerEm, scale.units)
    else:
        scaledWidth = imageWidth
        scaledHeight = imageHeight

    outputFileHolder = open(svgPath, "w", encoding="utf8") if svgPath is not None \
                        else contextlib.nullcontext(sys.stdout)
    with outputFileHolder as outputFile:
        def pf(s: str):
            print(s, file=outputFile)

#        pf(f"""<svg width="{imageWidth}" height="{imageHeight}" xmlns="http://www.w3.org/2000/svg">""")
#        pf(f"""<g transform="translate(0 {imageHeight}) scale(1 -1) translate({imageOffsetX} {imageOffsetY})">""")

        minY = -imageHeight + imageOffsetY
        
        pf("""<?xml version="1.0" encoding="utf-8" standalone="yes" ?>""")
        pf("""<svg xmlns="http://www.w3.org/2000/svg" """)
        pf(f"""  width="{scaledWidth}" height="{scaledHeight}" """)
        pf(f"""  viewBox="{-imageOffsetX} {minY} {imageWidth} {imageHeight}">""")

        # Invert vertical axis so the fonts are "upright" according to the SVG coordinate system.
        # The ascender part of the font (for horizontal writing) will have negative SVG y coordinates
        # however, which is accommodated in the viewBox specification above. 
        pf("""<g transform="scale(1 -1)">""")

        for command in clusterCommands:
            pf(f"""<path d={xmlQuoteAttr(command)} />""")

        pf("""</g>""")
        pf("""</svg>""")

shapeText(args.font, 
          args.direction,
          args.scale,
          svgPath = args.output,
          text = args.text)
