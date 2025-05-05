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

    devicePen = SVGPathPen(None)

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

    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        glyphId = info.codepoint

        logger.info(f"gid={glyphId} xAdv={pos.x_advance} yAdv={pos.y_advance} xOff={pos.x_offset} yOff={pos.y_offset}")

        # currentPen = TransformPen(devicePen, 
        #                           baseTransform.transform(
        #                               Offset(penX + pos.x_offset, penY + pos.y_offset)))
        currentPen = TransformPen(devicePen, Offset(penX + pos.x_offset, penY + pos.y_offset))
        font.draw_glyph_with_pen(glyphId, currentPen)

        penX += pos.x_advance
        penY += pos.y_advance

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
        pf(f"""<svg width="{scaledWidth}" height="{scaledHeight}" viewBox="{-imageOffsetX} {minY} {imageWidth} {imageHeight}" xmlns="http://www.w3.org/2000/svg">""")
        pf(f"""<path transform="scale(1 -1)" d={xmlQuoteAttr(devicePen.getCommands())} />""")
        pf("""</svg>""")

shapeText(args.font, 
          args.direction,
          args.scale,
          svgPath = args.output,
          text = args.text)
