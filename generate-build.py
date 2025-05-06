import ninja
import sys
import os.path
import configparser
import argparse
import io
import shutil

parser = argparse.ArgumentParser(
    description="Generate build instructions for Ninja build system of the Chinese Phonology project")
parser.add_argument("-o", "--output", default=None, help="output file for Ninja build instructions")
args = parser.parse_args()

# Do not overwrite file yet if this script executes with an error
tempFile = io.StringIO()

writer = ninja.Writer(tempFile, width=78)

configParser = configparser.ConfigParser()
with open("config.ini", encoding='utf-8') as configFile:
    configParser.read_file(configFile)
config = configParser["paths"] 

cvJava = config.get("java", "java")
cvPython = config.get("python", "python")
cvSaxon = config["saxon"]

def quoteCommand(*args):
    if sys.platform == 'win32':
        import subprocess
        text = subprocess.list2cmdline(args)
    else:
        import shlex
        text = shlex.join(args)

    text = text.replace("$", "$$")    
    text = text.replace("§", "$")
    return text

stylesheets = [ "table.xsl", "structure.xsl", "phonology.xsl", "bibliography.xsl" ]
stylesheets = [ os.path.join("xsl", p) for p in stylesheets ]

writer.rule(
    "generate_build",
    command=quoteCommand(cvPython, "generate-build.py", "-o", "§out"),
    description="Re-generating build instructions"
)

writer.build(
    rule="generate_build",
    outputs="build.ninja",
    inputs="generate-build.py",
    implicit="config.ini"
)

writer.rule(
    "xslt", 
    command=quoteCommand(cvJava, "-jar", cvSaxon, "-s:§in", "-xsl:§stylesheet", "-o:§out"),
    description="Saxon"
)

writer.build(
    outputs=["table.html"],
    rule="xslt",
    inputs="table.xml",
    implicit=["reflexes.xml", 
            "syllable.xml",
            "bibliography.xml",
            "rhyme-groups.xml",
            "term-links.xml"] + stylesheets,
    variables={ "stylesheet": stylesheets[0] }
)

writer.default("table.html")

if sys.platform == 'win32':
    copyCommand = quoteCommand("cmd", "/c", "copy", "/y", "§in", "§out")
else:
    copyCommand = quoteCommand("cp", "§in", "§out")

writer.rule(
    "copy",
    command=copyCommand
)

webOutputs = [ "index.html", "table.css", "main.js",
               "resources/logo-portable.svg" ]
webOutputs = [ os.path.normpath(f) for f in webOutputs ]

for f in webOutputs[1:]:
    writer.build(
        outputs=os.path.join("publish", f),
        rule="copy",
        inputs=f
    )
writer.build(
    outputs=os.path.join("publish", "index.html"),
    rule="copy",
    inputs="table.html"
)

writer.build(
    "publish", 
    rule="phony", 
    inputs=[ os.path.join("publish", f) for f in webOutputs ]
)

outputFile = sys.stdout
if args.output is not None:
    outputFile = open(args.output, "w", encoding='utf-8')

tempFile.seek(0)
shutil.copyfileobj(tempFile, outputFile)
