<xsl:stylesheet 
  version="2.0" 
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:s="http://www.gold-saucer.org/xmlns/structured-html"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="s html xs">

  <xsl:strip-space elements="html:link" />

  <!-- The "re-process" template mode is used when this stylesheet internally
       generates an intermediate result tree fragment that may contain a mix of 
       standard XHTML plus custom elements like those from the p: namespace.  
       The standard XHTML should be passed through verbatim while the custom 
       elements require the usual processing.  

       The "re-process" template mode deliberately avoids processing the XHTML
       "twice" which might not be an idempotent operation.  Otherwise it
       behaves the same as the default template mode. 
       
       The template rule immediately below catches all elements and applies
       the #default behavior.  It gets overridden by the rule immediately
       below which forces XHTML to be copied verbatim. 
       --> 
  <xsl:template match="*" mode="re-process">
    <xsl:apply-templates select="." />
  </xsl:template>

  <!-- Copy HTML elements from input to output, but force the XHTML namespace
       to be the default namespace to accomodate Web browsers. -->
  <xsl:template match="html:*" mode="re-process #default" name="process-html">
    <xsl:element name="{local-name()}" namespace="{namespace-uri()}">
      <xsl:apply-templates select="node()|@*" mode="#current" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="text()|@*" mode="re-process #default">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*" mode="#current" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@id">
    <!-- id attributes from the source XML are not copied to the output if strip-id is set -->
    <xsl:param name="strip-id" tunnel="yes" select="false()" />
    <xsl:if test="not($strip-id)">
      <xsl:apply-templates select="node()" />
    </xsl:if>
  </xsl:template>       

  <xsl:template match="s:term">
    <em class="term">
      <!-- Copy attriubtes ?? -->
      <xsl:apply-templates />
    </em>
  </xsl:template>

  <xsl:template match="s:section">
    <xsl:variable name="depth" select="count(ancestor-or-self::s:section)" />
    <div class="section section-{$depth}" id="sec-{s:make-section-number(.)}">
      <xsl:apply-templates select="node()|@*" />
    </div>
  </xsl:template>

  <xsl:template match="s:heading">
    <p class="heading">
      <xsl:value-of select="s:make-section-number(.)" />
      <xsl:text>. </xsl:text>
      <xsl:apply-templates select="node()" />
    </p>
  </xsl:template>

  <xsl:function name="s:make-section-number">
    <xsl:param name="target" as="element()" />
    <xsl:number level="multiple" select="$target" count="s:section" format="1.1" />
  </xsl:function>

  <!-- Formal wrapper surrounding tables and images.  
       Creates a "div" for styling purposes, plus possibly a generated index of figures -->
  <xsl:template match="s:figure">
    <div class="figure">
      <xsl:apply-templates />
    </div>
  </xsl:template>

  <!-- For convenience, a HTML table with a caption automatically creates a "figure" -->
  <xsl:template match="html:table[html:caption]">
    <div class="figure">
      <xsl:call-template name="process-html" />
    </div>
  </xsl:template>

  <!-- Wrapper element that falls away, for the purpose of grouping multiple elements
       to be referred to by s:copy-of -->
  <xsl:template match="s:fragment">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="s:fragment" mode="retain-outer-fragment">
    <xsl:copy>
      <xsl:apply-templates />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="node()" mode="retain-outer-fragment">
    <xsl:apply-templates select="." />
  </xsl:template>

  <!-- Repeat content in the source XML to avoid source-level duplication -->
  <xsl:template match="s:copy-of">
    <xsl:variable name="source" select="key('id', @idref)" />
    <xsl:if test="count($source) != 1">
      <xsl:message>warning: <xsl:value-of select="@idref" /> does not refer to a unique element in the source XML</xsl:message>
    </xsl:if>
    <xsl:apply-templates select="$source[position()=1]">
      <xsl:with-param name="strip-id" tunnel="yes" select="true()" />
    </xsl:apply-templates>
  </xsl:template>

  <!-- Create table of contents -->
  <xsl:template match="html:body">
    <xsl:call-template name="table-of-contents" />
    <div id="body">
      <xsl:apply-templates />
    </div>
  </xsl:template>

  <xsl:template name="table-of-contents">
    <div id="sidebar-button">
      <span class="icon">
        <a href="#toc" title="Table of contents">§</a>
      </span>
    </div>

    <div id="toc">
      <xsl:call-template name="table-of-contents-subtree" />
    </div>
  </xsl:template>

  <xsl:template name="table-of-contents-subtree">
    <xsl:param name="depth" as="xs:integer" select="1" />
    <ol class="toc toc-{$depth}">
      <xsl:for-each select="s:section">
        <li>
          <xsl:variable name="section-number" select="s:make-section-number(.)" />

          <a href="#sec-{$section-number}">
            <span class="section-number">
              <xsl:value-of select="$section-number" />
            </span>
  
            <!-- This <a> element is set to display as a block flexbox 
                 in CSS, so the following space is just for fallback
                 when CSS is disabled (or when rendering the document
                 to a non-visual medium). -->
            <xsl:text> </xsl:text>

            <span class="section-title">
              <xsl:apply-templates select="s:heading/node()|s:heading/@*" />
            </span>
          </a>

          <!-- Recursively generate entries at deeper levels. 
               But do not generate even the html:ol container if there
               are no entries at all. -->
          <xsl:if test="s:section">
            <xsl:call-template name="table-of-contents-subtree">
              <xsl:with-param name="depth" select="$depth + 1" />
            </xsl:call-template>
          </xsl:if>
        </li>
      </xsl:for-each>
    </ol>
  </xsl:template>

  <!-- HTML ruby syntax is really inconvenient to type by hand. 
       We adopt a special text-only syntax, assuming Japanese only:

        漢字+【ふりがな】

       that we translate to HTML ruby syntax. 
       
       The regular expression below is supposed to be:

       ([\p{IsBasicLatin}\p{IsCJKCompatibilityIdeographs}]+)【([\p{IsHiragana}\p{IsKatakana}]+)】

       but Saxon does not support this syntax despite it being part 
       of the XML Schema specification.  So we expand the blocks manually
       into Unicode character ranges.
       -->
  <xsl:template match="s:ruby">
    <xsl:analyze-string 
      select="string(.)" 
      regex="([&#x4E00;-&#x9FFF;&#x4E00;-&#x9FFF;]+)【([&#x3040;-&#x309F;&#x30A0;-&#x30FF;]+)】">
      <xsl:matching-substring>
        <ruby>
          <rb><xsl:value-of select="regex-group(1)" /></rb>
          <rt><xsl:value-of select="regex-group(2)" /></rt>
        </ruby>
      </xsl:matching-substring>
      <xsl:non-matching-substring><xsl:value-of select="." /></xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>

  <!-- Create a circled number with styling to make it visually distinct and appealing.
       Limited from 0 to 20. -->
  <xsl:template match="s:ordinal">
    <span class="ordinal">
      <span>
        <xsl:value-of select="number(@value)" />
      </span>
    </span>
  </xsl:template>

  <!-- Insert the current date/time, usually to inform the reader
       when the document was updated -->
  <xsl:template match="s:current-date-time">
    <xsl:variable name="lang" select="(ancestor-or-self::*/@xml:lang)[last()]" />
    <xsl:variable 
      name="content" 
      select="format-dateTime(current-dateTime(), @format, $lang, @calendar, @country)" />
    <xsl:choose>
      <xsl:when test="@attr">
        <xsl:attribute name="{@attr}"><xsl:value-of select="$content" /></xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$content" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>