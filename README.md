Sources for the web site [The Etymology of Modern Prounciations of Chinese Characters 現代漢字音的來源](https://github.gold-saucer.org/ChinesePhonology/).  Very much a work in progress, and I don't work on it often.  It's just an intellectual curiosity of mine.

## Build requirements

  1. [Recent version of Python 3.x](https://www.python.org/)
  2. [Saxon-HE](https://github.com/Saxonica/Saxon-HE/releases) (open-source version of the Java XSLT processor) 
  3. [Ninja build system](https://ninja-build.org/)

## Build instructions

Extract the Java archive files from the Saxon-HE distribution:

  - ``saxon-he-VERSION.jar``
  - ``lib/xmlresolver-VERSION-data.jar``
  - ``lib/xmlresolver-VERSION.jar``

Create ``config.ini`` with the following contents:

```
[paths]
saxon = «path to saxon-he-VERSION.jar file»
```

Run:

  - ``python generate-build.py -o build.ninja``.
  - ``ninja``

