<xsl:stylesheet 
  version="2.0" 
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:p="http://www.gold-saucer.org/xmlns/chinese-phonology"
  xmlns:s="http://www.gold-saucer.org/xmlns/structured-html"
  xmlns:data="http://www.gold-saucer.org/xmlns/chinese-phonology-data"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="p s data html">

  <xsl:output method="xhtml" 
              omit-xml-declaration="no" 
              encoding="utf-8"
              indent="no" />

  <xsl:include href="bibliography.xsl" />

  <xsl:key 
    name="link-groups" 
    match="p:link-item"
    use="concat(parent::p:link-group/@id, ':', @key)" />

  <xsl:key
    name="id"
    match="*[@id]"
    use="@id" />

  <xsl:key
    name="fn"
    match="p:fn"
    use="@idref" />

  <xsl:template match="html:*|text()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@id">
    <!-- id attributes from the source XML are not copied to the output if strip-id is set -->
    <xsl:param name="strip-id" tunnel="yes" select="false()" />
    <xsl:if test="not($strip-id)">
      <xsl:apply-templates select="node()" />
    </xsl:if>
  </xsl:template>       

  <!-- "mc" stands for terminology in Modern Chinese -->
  <xsl:template match="p:mc">
    <span lang="zh-tw">
      <xsl:apply-templates select="node()|@*" />
    </span>
  </xsl:template>

  <!-- "ac" stands for terminology in Chinese from 'ancient' times -->
  <xsl:template match="p:ac">
    <span lang="zh-tw">
      <xsl:call-template name="look-up-link" />
    </span>
  </xsl:template>

  <!-- Mark up 聲母, 韻母 given in Chinese characters. 
       This template is called when generating tables of Middle Chinese 
       phonological data.  The effect is as if the text is written
       inside a p:ac element. -->
  <xsl:template name="display-ac-phono-element">
    <xsl:param name="content" />
    <span lang="zh-tw">
      <xsl:copy-of select="$content" />
    </span>
  </xsl:template>

  <!-- Phonetic description in the standard International Phonetic Alphabet -->
  <xsl:template match="p:i">
    <span class="ipa">
      <xsl:text>/</xsl:text>
      <xsl:apply-templates select="node()|@*" />
      <xsl:text>/</xsl:text>
    </span>
  </xsl:template>

  <xsl:template name="display-ipa">
    <xsl:param name="content" />
    <span class="ipa">
      <xsl:copy-of select="$content" />
    </span>
  </xsl:template>

  <xsl:template name="look-up-link">
    <xsl:choose>
      <!-- "lg" stands for link group -->
      <xsl:when test="@p:lg">
        <xsl:variable name="result" select="key('link-groups', concat(@p:lg, ':', text()))" />
        <xsl:choose>
          <xsl:when test="count($result) = 1">
            <a href="{$result/@href}">
              <xsl:apply-templates select="node()|@*" />
            </a>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="node()|@*" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="node()|@*" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Phonetic description in the standard IPA with explanatory "note" -->
  <xsl:template match="p:in">
    <span class="ipa">
      <xsl:choose>
        <xsl:when test="@href">
          <a href="@href">
            <xsl:apply-templates select="node()|@*" />
          </a>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="node()|@*" />
        </xsl:otherwise>
      </xsl:choose>
    </span>
  </xsl:template>

  <!-- Pinyin transcription -->
  <xsl:template match="p:py">
    <xsl:text>‹ </xsl:text>
    <span class="pinyin">
      <xsl:apply-templates select="node()|@*" />
    </span>
    <xsl:text> ›</xsl:text>
  </xsl:template>

  <!-- Japanese romaji transcription -->
  <xsl:template match="p:jr">
    <xsl:text>‹ </xsl:text>
    <span class="romaji">
      <xsl:apply-templates select="node()|@*" />
    </span>
    <xsl:text> ›</xsl:text>
  </xsl:template>

  <xsl:template match="html:head/p:*">
  </xsl:template>

  <xsl:template match="p:notes-list">
    <ol class="footnotes">
      <xsl:apply-templates select="node()|@*" />
    </ol>
  </xsl:template>

  <xsl:template match="p:notes-list/html:li/html:p[position()=1]">
    <p>
      <xsl:apply-templates select="@*" />
      <xsl:variable name="referrer" select="key('fn', ../@id)" />
      <xsl:if test="count($referrer) = 1">
        <xsl:for-each select="$referrer">
          <a href="#{generate-id()}" class="footnote-return">▲</a>
          <xsl:text> </xsl:text>
        </xsl:for-each>
      </xsl:if>
      <xsl:apply-templates select="node()" />
    </p>
  </xsl:template>

  <!-- Footnote reference -->
  <xsl:template match="p:fn">
    <xsl:variable name="idref" select="@idref" />
    <xsl:variable name="target" select="key('id', $idref)" />
    <xsl:variable name="here" select="generate-id()" />
    <xsl:choose>
      <xsl:when test="$target">
        <xsl:for-each select="$target">
          <a href="#{$idref}" id="{$here}">
            <sup class="footnote">
              <xsl:text>▼</xsl:text>
              <xsl:number format="1" />
            </sup>
          </a>
        </xsl:for-each>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="s:section">
    <xsl:variable name="depth" select="count(ancestor-or-self::s:section)" />
    <div class="section section-{$depth}">
      <xsl:apply-templates select="node()|@*" />
    </div>
  </xsl:template>

  <xsl:template match="s:heading">
    <p class="heading">
      <xsl:number level="multiple" count="s:section" format="1. " />
      <xsl:apply-templates select="node()" />
    </p>
  </xsl:template>

  <!-- Wrapper element that falls away, for the purpose of grouping multiple elements
       to be referred to by s:copy-of -->
  <xsl:template match="s:fragment">
    <xsl:apply-templates />
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

  <xsl:template match="p:middle-chinese-finals-rows">
    <xsl:variable name="finals">
      <xsl:call-template name="retrieve-middle-chinese-finals">
        <xsl:with-param name="coda" select="xs:boolean(@coda)" />
        <xsl:with-param name="tone" select="xs:integer(@tone)" />
      </xsl:call-template>
    </xsl:variable>

    <!-- Loop over each rhyme group -->
    <xsl:for-each-group select="$finals/*" group-by="@rg">
      <!-- Process in the hinted order given by the input phonological data -->
      <xsl:sort select="xs:integer(@n)" stable="yes" order="ascending" />

      <xsl:variable name="rows">
        <!-- Loop over possible values of @u -->
        <xsl:for-each-group select="current-group()" group-by="@u">

          <!-- Process in the order 開,合 
                (exploiting that 開 occurs later than 合 in Unicode) -->
          <xsl:sort select="@u" stable="yes" order="descending" 
                    collation="http://www.w3.org/2005/xpath-functions/collation/codepoint" />

          <!-- Collect rows with same (rg, u) and display together in table -->
          <xsl:call-template name="display-rhyme-subgroup">
            <xsl:with-param name="items" select="current-group()" />
            <xsl:with-param name="head">
              <td class="u-medial">
                <xsl:call-template name="display-ac-phono-element">
                  <xsl:with-param name="content" select="current-grouping-key()" />
                </xsl:call-template>
              </td>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:for-each-group>
      </xsl:variable>

      <xsl:apply-templates select="$rows" mode="prepend-head-cell-to-table-rows">
        <xsl:with-param name="head">
          <td class="rhyme-group">
            <xsl:call-template name="display-ac-phono-element">
              <xsl:with-param name="content" select="current-grouping-key()" />
            </xsl:call-template>
          </td>
        </xsl:with-param>
      </xsl:apply-templates>
      
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template name="retrieve-middle-chinese-finals">
    <xsl:param name="coda" select="@coda" />
    <xsl:param name="tone" select="@tone" />

    <xsl:for-each select="document('rhyme-groups.xml')/data/item">
      <!-- Explicitly sort so the order of rows in the HTML output is independent
           of the order in the input TSV/XML data -->
      <xsl:sort select="@n" data-type="number" /><!-- more logical order of 攝韻 used in 《切韻研究》 by 邵榮芬 -->
      <xsl:sort select="@j" /><!-- order within a single 攝韻+呼+等 combination -->

      <xsl:variable name="pronunciation">
        <xsl:choose>
          <xsl:when test="$tone = 4"><xsl:value-of select="@p4" /></xsl:when>
          <xsl:otherwise><xsl:value-of select="@p" /></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:variable name="item-has-coda" select="matches($pronunciation, '[mnŋptk]ˋ?$')" />

      <xsl:variable name="rhyme-char">
        <!-- 韻目 -->
        <xsl:choose>
          <xsl:when test="$tone = 1"><xsl:value-of select="@c1" /></xsl:when>
          <xsl:when test="$tone = 2"><xsl:value-of select="@c2" /></xsl:when>
          <xsl:when test="$tone = 3"><xsl:value-of select="@c3" /></xsl:when>
          <xsl:when test="$tone = 4"><xsl:value-of select="@c4" /></xsl:when>
          <xsl:otherwise>
            <!-- 舒聲 -->
            <xsl:choose>
              <xsl:when test="@c1 != ''"><xsl:value-of select="@c1" /></xsl:when>
              <xsl:when test="@c2 != ''"><xsl:value-of select="@c2" /></xsl:when>
              <xsl:when test="@c3 != ''"><xsl:value-of select="@c3" /></xsl:when>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:if test="$rhyme-char != '' and $item-has-coda = boolean($coda)">
        <data:middle-chinese-final
          rg="{@rg}" u="{@u}" d="{@d}" j="{@j}"
          c="{$rhyme-char}" p="{$pronunciation}" />
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="display-rhyme-subgroup">
    <xsl:param name="items" />
    <xsl:param name="head" />
    
    <xsl:variable name="rows">
      <!-- Loop over distinct @j values -->
      <xsl:for-each-group select="$items" group-by="@j">
        <xsl:sort select="@j" stable="yes" order="ascending"
                  collation="http://www.w3.org/2005/xpath-functions/collation/codepoint" />

        <tr>
          <!-- Loop over divisions (horizontal axis of table)-->
          <xsl:for-each select="'1', '2', '3A', '3B', '3C', '3D', '4'">
            <xsl:variable name="d" select="." />

            <xsl:variable name="cell" select="current-group()[@d=$d]" />
            <xsl:if test="count($cell) > 1">
              <xsl:message>
                <xsl:text>warning: more than one Middle Chinese final for the combination: </xsl:text>
                <xsl:value-of select="concat($cell/@rg, $d, $cell/@j)" />
              </xsl:message>
            </xsl:if>

            <td>
              <xsl:if test="count($cell) > 0">
                <xsl:attribute name="class">sound</xsl:attribute>
                <xsl:call-template name="display-ac-phono-element">
                  <xsl:with-param name="content" select="string($cell[position()=1]/@c)" />
                </xsl:call-template>
                <xsl:text> </xsl:text>
                <xsl:call-template name="display-ipa">
                  <xsl:with-param name="content" select="string($cell[position()=1]/@p)" />
                </xsl:call-template>
              </xsl:if>
            </td>
          </xsl:for-each>
        </tr>

      </xsl:for-each-group>
    </xsl:variable>

    <xsl:apply-templates select="$rows" mode="prepend-head-cell-to-table-rows">
      <xsl:with-param name="head" select="$head" />
    </xsl:apply-templates>

  </xsl:template>
  
  <xsl:template mode="prepend-head-cell-to-table-rows" match="html:tr[position()=1]">
    <xsl:param name="head" />

    <xsl:variable name="row-count" select="count(../html:tr)" />

    <!-- Replicate html:tr and its existing attributes -->
    <xsl:copy>
      <xsl:copy-of select="@*" />

      <!-- Copy $head which is assumed to be html:td or html:th element,
           setting its row span to the number of html:tr instances found. -->
      <xsl:for-each select="$head/node()">
        <xsl:copy>
          <xsl:copy-of select="@*" />
          <xsl:if test="self::html:td or self::html:th">
            <xsl:attribute name="rowspan">
              <xsl:value-of select="$row-count" />
            </xsl:attribute>
          </xsl:if>
          <xsl:copy-of select="node()" />
        </xsl:copy>
      </xsl:for-each>
    
      <!-- Copy in the original contents of the html:tr element -->
      <xsl:copy-of select="node()" />
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="prepend-head-cell-to-table-rows" match="@*|node()">
    <xsl:copy-of select="." />
  </xsl:template>

</xsl:stylesheet>
