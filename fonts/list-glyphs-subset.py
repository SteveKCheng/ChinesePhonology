import fontTools.ttLib as ttLib
import unicodedata
import argparse
import sys
import re

parser = argparse.ArgumentParser(
    description="List names of glyphs from a TrueType/OpenType font to retain for subsetting")
parser.add_argument("font", help="path to TrueType/OpenType font file")
parser.add_argument("-o", "--output", default=None, help="output listing of desired glyphs")
parser.add_argument("-c", "--codepoints", default=None, help="listing of Unicode codepoints to be included")
parser.add_argument("--bare", action='store_true', 
                    help="output should be bare listing of font's glyph names")
args = parser.parse_args()

font = ttLib.TTFont(args.font, lazy=True)
glyphSet = font.getGlyphSet()
glyphOrder = font.getGlyphOrder()

cmap = font["cmap"]
glyphToUnicode = cmap.buildReversed()

# https://github.com/fonttools/fonttools/blob/d5aec1b9dbcbaa3f97d0d553fe85a92927b48faa/Tests/ttLib/ttFont_test.py#L120

def getGlyphSubstitutions(font, lookupTableIndices: list[int]):
    gsub = font['GSUB']
    allLookupTables = gsub.table.LookupList.Lookup

    glyphSubst = {}

    for i in lookupTableIndices:
        lookupTable = allLookupTables[i]

        for st in lookupTable.SubTable:
            st1 = getattr(st, 'ExtSubTable', st)
            for sourceGlyph, targetGlyph in st1.mapping.items():
                glyphSubst[sourceGlyph] = targetGlyph
    
    return glyphSubst

def findLoclLookupTables(font: ttLib.TTFont, script: str, lang: str) -> list[int]:
    """
    Get the indices of the look-up subtables within the GSUB table
    of the OpenType font that implement the "locl" feature
    for the given script and language combination.

    :param font: The OpenType font object
    :param script: The script tag in the syntax of OpenType
    :param lang: The language tag in the syntax of OpenType
    """

    gsub = font['GSUB']
    allFeatureRecords = gsub.table.FeatureList.FeatureRecord

    lookupIndices = []

    script = script.rstrip(" ")
    lang = lang.rstrip(" ")

    for sr in gsub.table.ScriptList.ScriptRecord:
        # Process only the selected script
        if sr.ScriptTag.rstrip(" ") != script:
            continue

        for ls in sr.Script.LangSysRecord:
            # Process only the selected language
            if ls.LangSysTag.rstrip(" ") != lang:
                continue

            # Loop over all features for this script/language combination
            for i in ls.LangSys.FeatureIndex:
                f = allFeatureRecords[i]

                # Consider only look-up tables for the "locl" feature
                if f.FeatureTag != "locl":
                    continue

                lookupIndices += f.Feature.LookupListIndex

    return lookupIndices

def isUnihan(codepoint: int) -> bool:
    """
    
    Includes the following Unicode blocks:

      * 2E80-2EFF    CJK Radicals Supplement
      * 2F00-2FDF    Kangxi Radicals
      * 31C0-31EF    CJK Strokes
      * 3200-32FF    Enclosed CJK Letters and Months
      * 3300-33FF    CJK Compatibility
      * 3400-4DBF    CJK Unified Ideographs Extension A
      * 4E00-9FFF    CJK Unified Ideographs
      * F900-FAFF    CJK Compatibility Ideographs
      * 20000-2A6DF  CJK Unified Ideographs Extension B
      * 2A700-2B73F  CJK Unified Ideographs Extension C
      * 2B740-2B81F  CJK Unified Ideographs Extension D
      * 2B820-2CEAF  CJK Unified Ideographs Extension E
      * 2CEB0-2EBEF  CJK Unified Ideographs Extension F
      * 2EBF0-2EE5F  CJK Unified Ideographs Extension I
      * 2F800-2FA1F  CJK Compatibility Ideographs Supplement
      * 30000-3134F  CJK Unified Ideographs Extension G
      * 31350-323AF  CJK Unified Ideographs Extension H
    """

    return (0x2E80 <= codepoint < 0x2FE0) or \
           (0x31C0 <= codepoint < 0x31F0) or \
           (0x3200 <= codepoint < 0x4DC0) or \
           (0x4E00 <= codepoint < 0xA000) or \
           (0xF900 <= codepoint < 0xFB00) or \
           (0x20000 <= codepoint < 0x323B0)

def getHanVariantGlyphs(font, glyphToUnicode, lang: str):
    glyphSubst = getGlyphSubstitutions(font, findLoclLookupTables(font, "hani", lang))

    glyphSet = set()

    for sourceGlyph, targetGlyph in glyphSubst.items():
        if sourceGlyph == targetGlyph:
            continue

        codepointSet = glyphToUnicode.get(sourceGlyph, None)
        if codepointSet is None:
            continue

        if all(isUnihan(codepoint) for codepoint in codepointSet):
            glyphSet.add(targetGlyph)

    return glyphSet

if args.codepoints:
    from fontTools.subset import parse_unicodes, Subsetter

    desiredCodepoints = set()

    with open(args.codepoints, encoding='utf-8') as inputFile:
        for line in inputFile:
            line = line.rstrip("\n")
            line = line.split("#", 2)[0]
            codepoints = parse_unicodes(line)
            desiredCodepoints.update(codepoints)

    # Find glyphs that are connected to the selected Unicode characters
    # directly (through cmap) or indirectly (e.g. ligatures).
    #
    # Note that a font may have glyphs that are just sitting there
    # wasting space, not connected to anything --- because
    # it had been created from some master font but was not subset completely.
    #
    # Re-use the "glyph closure" algorithm from the "subset" tool 
    # from fontTools.
    subsetter = Subsetter()
    subsetter.populate(unicodes=desiredCodepoints)
    subsetter._closure_glyphs(font)
    desiredGlyphs = set(subsetter.glyphs_retained)

else:
    desiredGlyphs = set(glyph for glyph in glyphSet)

variantGlyphs = set()
variantGlyphs.update(getHanVariantGlyphs(font, glyphToUnicode, "JAN"))
variantGlyphs.update(getHanVariantGlyphs(font, glyphToUnicode, "KOR"))
variantGlyphs.update(getHanVariantGlyphs(font, glyphToUnicode, "ZHS"))
variantGlyphs.update(getHanVariantGlyphs(font, glyphToUnicode, "ZHT"))
desiredGlyphs.difference_update(variantGlyphs)

outputFile = sys.stdout
if args.output is not None:
    outputFile = open(args.output, "w", encoding='utf-8')

for glyph in desiredGlyphs:
    if args.bare:
        print(glyph, file=outputFile)
    else:        
        codepointSet = glyphToUnicode.get(glyph, None)
        codepointList = sorted(codepointSet) if codepointSet is not None else [ 0 ]

        for i in range(len(codepointList)):
            codepoint = codepointList[i]
            glyphDisplay = glyph if i == 0 else ""

            if codepoint != 0:
                char = chr(codepoint)
                name = unicodedata.name(char, "")
                category = unicodedata.category(char)
                charDisplay = char if category != "Cc" else f"({category})"
                print(f"{glyph:16} # {charDisplay} U+{codepoint:5X} {name}", file=outputFile)
            else:
                print(f"{glyph:16} # no Unicode codepoint associated", file=outputFile)
