<xsl:stylesheet 
  version="1.0" 
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:p="http://www.gold-saucer.org/chinese-phonology"
  xmlns:s="http://www.gold-saucer.org/structured-html"
  xmlns:data="http://www.gold-saucer.org/chinese-phonology-data"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:re="http://exslt.org/regular-expressions"
  xmlns:set="http://exslt.org/sets"
  xmlns:str="http://exslt.org/strings"
  xmlns:math="http://exslt.org/math"
  exclude-result-prefixes="p s exsl math re set str data">

  <xsl:output omit-xml-declaration="yes" indent="no" />

  <xsl:key 
    name="link-groups" 
    match="p:link-item"
    use="concat(parent::p:link-group/@id, ':', @key)" />

  <xsl:key
    name="id"
    match="html:*[@id]"
    use="@id" />

  <xsl:key
    name="fn"
    match="p:fn"
    use="@idref" />

  <xsl:key
    name="finals-by-rgudj"
    match="data:middle-chinese-final"
    use="concat(@rg, @u, @d, @j)" />

  <xsl:key
    name="finals-by-rgu"
    match="data:middle-chinese-final"
    use="concat(@rg, @u)" />

  <xsl:template match="html:*|text()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*" />
    </xsl:copy>
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

  <!-- Phonetic description in the standard International Phonetic Alphabet -->
  <xsl:template match="p:i">
    <span class="ipa">
      <xsl:text>/</xsl:text>
      <xsl:apply-templates select="node()|@*" />
      <xsl:text>/</xsl:text>
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
    <ol>
      <xsl:apply-templates select="node()|@*" />
    </ol>
  </xsl:template>

  <xsl:template match="p:notes-list/html:li/html:p[position()=1]">
    <p>
      <xsl:apply-templates select="@*" />
      <xsl:variable name="referrer" select="key('fn', ../@id)" />
      <xsl:if test="count($referrer) = 1">
        <xsl:for-each select="$referrer">
          <a href="#{generate-id()}">^</a>
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
            <sup>
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
      <xsl:apply-templates select="node()" />
    </p>
  </xsl:template>

  <xsl:template match="p:middle-chinese-finals-table">
    <table>
      <thead>
        <tr>
          <th colspan="2"><p:ac>等</p:ac> Division</th>
          <th>1</th>
          <th>2</th>
          <th>3A</th>
          <th>3B</th>
          <th>3C</th>
          <th>3D</th>
          <th>4</th>
        </tr>
        <tr>
          <th colspan="2">Has high front medial?</th>
          <th colspan="2">No</th>
          <th colspan="4">Yes</th>
          <th>Develops later</th>
        </tr>
        <tr>
          <th><p:ac>攝</p:ac></th>
          <th><p:ac>呼</p:ac></th>
        </tr>
      </thead>
      <tbody>
        <xsl:variable name="finals-rtf">
          <xsl:call-template name="retrieve-middle-chinese-finals">
            <xsl:with-param name="coda" select="@coda" />
            <xsl:with-param name="tone" select="@tone" />
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="finals" select="exsl:node-set($finals-rtf)" />

<!--
        <xsl:for-each select="$finals/*">
          <tr>
            <td><xsl:value-of select="@rg" /></td>
            <td><xsl:value-of select="@u" /></td>
            <xsl:variable name="item" select="." />
            <xsl:for-each select="str:tokenize('1 2 3A 3B 3C 3D 4', ' ')">
              <td>
                <xsl:if test="$item/@d = .">
                  <span lang="zh-tw">
                    <xsl:value-of select="$item/@c" />
                  </span>
                  <xsl:text> </xsl:text>
                  <span class="ipa">
                    <xsl:value-of select="$item/@p" />
                  </span>
                </xsl:if>
              </td>
            </xsl:for-each>
          </tr>
        </xsl:for-each>
-->

<!--
        <xsl:for-each select="set:distinct($finals/@rgu)">
          <xsl:for-each select="$finals[@rgu = current()]">
            <tr>
              <xsl:if test="position() = 1">
                <xsl:if test="generate-id($finals[@rg = current()/@rg]) = generate-id(.)">
                  <td rowspan="{count($finals[@rg = current()/@rg])}">
                    <xsl:value-of select="@rg" />
                  </td>
                </xsl:if>
                <td rowspan="{last()}">
                  <xsl:value-of select="@u" />
                </td>
              </xsl:if>

            </tr>
          </xsl:for-each>
        </xsl:for-each>
-->

        <!-- Loop over each rhyme group -->
        <xsl:for-each select="set:distinct($finals/*/@rg)">
          <xsl:variable name="rg" select="." />

          <!-- Compute row span for column in first cell -->
          <xsl:variable name="items-count">
            <xsl:call-template name="count-rows-in-rhyme-subgroup">
              <xsl:with-param name="rgu" select="$rg" />
              <xsl:with-param name="items-root" select="$finals" />
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="items-count-open">
            <xsl:call-template name="count-rows-in-rhyme-subgroup">
              <xsl:with-param name="rgu" select="concat($rg, '開')" />
              <xsl:with-param name="items-root" select="$finals" />
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="items-count-closed">
            <xsl:call-template name="count-rows-in-rhyme-subgroup">
              <xsl:with-param name="rgu" select="concat($rg, '合')" />
              <xsl:with-param name="items-root" select="$finals" />
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="items-count-all"
            select="number($items-count-open) + number($items-count-closed) + number($items-count)" />
            
          <!-- Loop over possible values of @u -->
          <xsl:for-each select="set:distinct($finals/*[@rg=$rg]/@u)">

            <!-- Collect rows with same (rg, u) and display together in table -->
            <xsl:call-template name="display-rhyme-subgroup">
              <xsl:with-param name="rgu" select="concat($rg, string(.))" />
              <xsl:with-param name="items-root" select="$finals" />
              <xsl:with-param name="head">
                <xsl:if test="position() = 1">
                  <td rowspan="{$items-count-all}">
                    <xsl:value-of select="$rg" />
                  </td>
                </xsl:if>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:for-each>

<!--
        <xsl:call-template name="display-rhyme-subgroup">
          <xsl:with-param name="rgu" select="'止開'" />
          <xsl:with-param name="items-root" select="$finals" />
        </xsl:call-template>
-->
      </tbody>
    </table>
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

      <xsl:variable name="last-letter" select="substring($pronunciation, string-length($pronunciation))" />


      <xsl:variable name="item-has-coda" select="re:test($pronunciation, '[mnŋptk]ˋ?$')" />

<!--
      <xsl:variable name="item-has-coda" select="$last-letter = 'm' or $last-letter = 'n' or $last-letter = 'ŋ' 
      or $last-letter = 'p' or $last-letter = 't' or $last-letter = 'k'" />
-->

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
      <xsl:message>processing item</xsl:message>
      <xsl:if test="$rhyme-char != '' and $item-has-coda = boolean($coda)">
        <data:middle-chinese-final
          rg="{@rg}" u="{@u}" d="{@d}" j="{@j}"
          c="{$rhyme-char}" p="{$pronunciation}" />
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="count-rows-in-rhyme-subgroup">
    <xsl:param name="rgu" />
    <xsl:param name="items-root" />
    <xsl:for-each select="$items-root[position()=1]">
      <xsl:value-of select="count(set:distinct(key('finals-by-rgu', $rgu)/@j))" />
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="display-rhyme-subgroup">
    <xsl:param name="rgu" />
    <xsl:param name="items-root" /><!-- Points to node-set from retrieve-middle-chinese-finals -->
    <xsl:param name="head" /><!-- html:td for head cell of rows, if any -->
    
    <xsl:variable name="items-count-rtf">
      <xsl:call-template name="count-rows-in-rhyme-subgroup">
        <xsl:with-param name="rgu" select="$rgu" />
        <xsl:with-param name="items-root" select="$items-root" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="items-count" select="number($items-count-rtf)" />

    <!-- Dummy for-each to target temporary data for XPath key function -->
    <xsl:for-each select="$items-root[position()=1]">

      <!-- Loop over distinct @j values -->
      <xsl:for-each select="set:distinct(key('finals-by-rgu', $rgu)/@j)">
        <xsl:variable name="j" select="." />

        <tr>
          <xsl:if test="position() = 1">
            <xsl:copy-of select="$head" />
            <td rowspan="{$items-count}"><xsl:value-of select="substring($rgu, 2)" /></td>
          </xsl:if>

          <!-- Loop over divisions (horizontal axis of table)-->
          <xsl:for-each select="str:tokenize('1 2 3A 3B 3C 3D 4', ' ')">
            <xsl:variable name="d" select="." />

            <xsl:for-each select="$items-root[position()=1]">

              <xsl:variable name="cell" select="key('finals-by-rgudj', concat($rgu, $d, $j))" />
              <xsl:if test="count($cell) > 1">
                <xsl:message>
                  <xsl:text>warning: more than one Middle Chinese final for the combination: </xsl:text>
                  <xsl:value-of select="concat($rgu, $d, $j)" />
                </xsl:message>
              </xsl:if>

              <td>
                <xsl:if test="count($cell) > 0">
                  <xsl:value-of select="$cell[position()=1]/@c" />
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="$cell[position()=1]/@p" />
                </xsl:if>
              </td>
            </xsl:for-each>

          </xsl:for-each><!-- loop over divisions -->
        </tr>
      </xsl:for-each><!-- loop over @j -->

    </xsl:for-each>
  </xsl:template>
  
</xsl:stylesheet>
