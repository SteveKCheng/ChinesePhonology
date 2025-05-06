<xsl:stylesheet 
  version="2.0" 
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:p="http://www.gold-saucer.org/xmlns/chinese-phonology"
  xmlns:s="http://www.gold-saucer.org/xmlns/structured-html"
  xmlns:data="http://www.gold-saucer.org/xmlns/chinese-phonology-data"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="p s data html xs">

  <!-- Output a DOCTYPE declaration to avoid certain Web browsers
       going into "quirks" mode. XSLT requires us to specify a DTD,
       so use XHTML 1.1, even that is supposedly "superseded" by HTML 5
       (which treats XML as a second-class citizen and gives it no DTD).
       Since we use ruby (Japanese furigana), we cannot use XHTML 1.0. 
  -->
  <xsl:output method="xhtml" 
              omit-xml-declaration="no" 
              encoding="utf-8"
              standalone="yes"
              indent="no"
              doctype-public="-//W3C//DTD XHTML 1.1//EN"
              doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" />

  <xsl:include href="structure.xsl" />
  <xsl:include href="bibliography.xsl" />
  <xsl:include href="phonology.xsl" />

  <xsl:variable name="term-links-xml" select="document('../term-links.xml')" />

  <xsl:key 
    name="link-items" 
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

  <xsl:key
    name="section-number"
    match="s:section"
    use="s:make-section-number(.)" />

  <xsl:template name="look-up-link">
    <xsl:choose>
      <!-- "h" stands for hypertext link -->
      <xsl:when test="@h">
        <xsl:variable name="key" select="text()" />
        <xsl:variable name="item" select="key('link-items', concat(@h, ':', $key), $term-links-xml)" />
        <xsl:variable name="group" select="key('id', @h, $term-links-xml)/self::p:link-group" />
        <xsl:choose>
          <xsl:when test="count($item) = 1">
            <a href="{$item/@href}">
              <xsl:apply-templates select="node()|@*" />
            </a>
          </xsl:when>
          <xsl:when test="count($group/@prefix) = 1">
            <a href="{$group/@prefix}{$key}">
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

  <!-- Footnote reference.

       This template is also explicitly callable so that 
       other templates can generate footnotes without re-processing
       intermediate output trees.  Note: this functionality is broken
       right now because the generation of the footnote content
       cannot see where it is referenced.
       -->
  <xsl:template match="p:fn" name="make-footnote">
    <xsl:param name="here" select="generate-id()" as="xs:string" />
    <xsl:param name="idref" select="@idref" as="xs:string" />
    <xsl:variable name="target" select="key('id', $idref)" />
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

    <xsl:for-each select="document('../rhyme-groups.xml')/data/item">
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

  <!-- In our flavor of HTML, we allow paragraphs to contain inline content and
       block-level content mixed together.  In official HTML that is not allowed.
       This template flattens the content.  Text that occurs in between blocks
       inside a paragraph or after the last block in the paragraph will be 
       separated out into p elements in the HTML output with the "continuation"
       class.  
  -->
  <xsl:template name="flatten-html-paragraph" match="html:p">
    <xsl:variable name="blocks" select="html:div|html:ul|html:ol|html:dl|html:pre|html:hr|html:blockquote|html:address|html:table" />
    <xsl:variable name="only-inline-content" select="empty($blocks)" />
    <p>
      <xsl:apply-templates select="@*" />
      <xsl:apply-templates select="node()[$only-inline-content or . &lt;&lt; $blocks[1]]" />
    </p>

    <!-- Flatten any embedded block-level content inside this paragraph -->
    <xsl:if test="not($only-inline-content)">
      <xsl:call-template name="flatten-html-paragraph-part">
        <xsl:with-param name="blocks" select="$blocks" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Recursive template invoked internally by flatten-html-paragraph. 
       Each invocation processes one block and the inline content following it (if any). -->
  <xsl:template name="flatten-html-paragraph-part">
    <xsl:param name="blocks" required="yes" />
    <xsl:variable name="this-block" select="$blocks[1]" />
    <xsl:variable name="next-blocks" select="$blocks[position() > 1]" />
    <xsl:variable name="is-last-block" select="empty($next-blocks)" />

    <!-- Output the block-level element that is inside the parent paragraph. -->
    <xsl:apply-templates select="$this-block" />

    <!-- Output immediately-following inline content unless it is only whitespace -->
    <xsl:variable 
      name="inline-content" 
      select="$this-block/following-sibling::node()[$is-last-block or .&lt;&lt; $next-blocks[1]]" />
    <xsl:variable
      name="inline-content-is-whitespace"
      select="every $t in $inline-content satisfies ($t/self::text() and $t/normalize-space() = '')" />
    <xsl:if test="not($inline-content-is-whitespace)">
      <xsl:variable name="parent" select="$this-block/ancestor::*[1]" />
      <p class="continuation">
        <xsl:apply-templates select="$parent/@*" />
        <xsl:apply-templates select="$inline-content" />
      </p>
    </xsl:if>

    <!-- Continue on to process any following blocks -->
    <xsl:if test="not($is-last-block)">
      <xsl:call-template name="flatten-html-paragraph-part">
        <xsl:with-param name="blocks" select="$next-blocks" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>  

  <!-- Helper to let parts of an HTML table be written independent as sub-blocks.
       The content inside s:merge-table-rows is evaluated and is expected to result
       in zero or more s:fragment elements. 

       Each s:fragment is expected to contain a sequence of html:tr elements.
       The result transformation from s:merge-table-rows will be html:tr elements,
       where each row consists of cells from the html:tr at the corresponding 
       position from each s:fragment, concatenated together to form bigger rows.  -->
  <xsl:template match="s:merge-table-rows">
    <xsl:variable name="fragments">
      <xsl:apply-templates mode="retain-outer-fragment" />
    </xsl:variable>
    <xsl:variable 
      name="is-valid"
      select="(every $t in $fragments/text() satisfies $t/normalize-space() = '') and 
              not($fragments/* except $fragments/s:fragment)" />
    <xsl:if test="not($is-valid)">
      <xsl:message>s:merge-table-rows must only contain s:fragment children but does not</xsl:message>
    </xsl:if>

    <!-- Count max number of rows across all fragments -->
    <xsl:variable name="count-rows" select="max(for $f in $fragments/s:fragment return count($f/html:tr))" />

    <xsl:for-each select="1 to $count-rows">
      <xsl:variable name="row-index" select="." />
      <tr>
        <xsl:for-each select="$fragments/s:fragment">
          <xsl:copy-of select="html:tr[$row-index]/node()" copy-namespaces="no" />
        </xsl:for-each>
      </tr>
    </xsl:for-each>
  </xsl:template>

  <!-- 
       Generate a block of information about a character for a table incorporating 
       sound comparisons between our three languages.  It looks like:

       ┌───────────┬────────┬──────┬─────┐
       │ @char     │        │ @p   │ @g  │
       │           │ @gloss ├──────┼─────┤
       │ (@char-j) │        │ @c   │ @k  │
       └───────────┴────────┴──────┴─────┘
       
       with appropriate inline markup for the attribute text.  The cells for
       @g and @k may be combined in a row span if @k is missing.

       @p: 普通話拼音
       @c: 粤語拼音
       @g: 音読み・呉音
       @k: 音読み・漢音

  -->
  <xsl:template match="p:pcgk-comparison-table-block">
    <xsl:variable name="content">
      <tr>
        <th rowspan="2">
          <p:mc><xsl:value-of select="@char" /></p:mc>
          <xsl:if test="@char-j">
            <xsl:text> </xsl:text>
            <p:j>(<xsl:value-of select="@char-j" />)</p:j>
          </xsl:if>
        </th>
        <td rowspan="2"><xsl:value-of select="@gloss" /></td>
        <td><p:py><xsl:value-of select="@p" /></p:py></td><!-- pinyin -->
        <td>
          <xsl:if test="not(@k)">
            <xsl:attribute name="rowspan" select="'2'" />
          </xsl:if>
          <p:jr><xsl:value-of select="@g" /></p:jr><!-- go-on -->
        </td>
      </tr>
      <tr>
        <td><p:yp><xsl:value-of select="@c" /></p:yp></td><!-- jyutping -->
        <xsl:if test="@k != ''">
          <td>
            <p:jr><xsl:value-of select="@k" /></p:jr><!-- kan-on -->
          </td>
        </xsl:if>
      </tr>
    </xsl:variable>

    <s:fragment>
      <!-- Need to transform the literal p:* elements above -->
      <xsl:apply-templates select="$content" mode="re-process" />
    </s:fragment>
  </xsl:template>

  <xsl:template match="p:all-comparison-table-row">
    <xsl:variable name="content">
      <tr>
        <th><p:ac h="wikihan"><xsl:value-of select="@char" /></p:ac></th>
        <td><p:ac><xsl:value-of select="@fq" /></p:ac></td>
        <td>
          <p:ac><xsl:value-of select="@if" /></p:ac>
          <span class="division"><xsl:value-of select="@d" /></span>
          <xsl:if test="@u">
            <p:ac><xsl:value-of select="@u" /></p:ac>
          </xsl:if>
        </td>
        <td><p:i><xsl:value-of select="@m" /></p:i></td>
        <td><p:py><xsl:value-of select="@p" /></p:py></td>
        <td><p:yp><xsl:value-of select="@c" /></p:yp></td>
        <td><p:jr><xsl:value-of select="@g" /></p:jr></td>
        <td><p:jr><xsl:value-of select="@k" /></p:jr></td>
        <td><xsl:value-of select="@comment" /></td>
      </tr>
    </xsl:variable>

    <xsl:apply-templates select="$content" mode="re-process" />
  </xsl:template>

  <xsl:template match="p:english-analogy">
    <div class="sound-word">
      <span class="ipa">
        <xsl:value-of select="@head-ipa" />
      </span>

      <span class="english-analogy">
        <em class="word">
          <a href="{@def}">
            <xsl:call-template name="emphasize-underlined">
              <xsl:with-param name="text" select="@word" />
            </xsl:call-template>
          </a>
        </em>
        <br />
        <span class="ipa-narrow">
          <xsl:variable name="ipa">
            <xsl:call-template name="emphasize-underlined">
              <xsl:with-param name="text" select="@word-ipa" />
            </xsl:call-template>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="@audio">
              <a class="audio" href="{@audio}"><xsl:value-of select="$ipa" /></a>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$ipa" />
            </xsl:otherwise>
          </xsl:choose>
        </span>
      </span>

      <!-- any additional note or comment -->
      <xsl:if test="node()">
        <span>
          <xsl:apply-templates />
        </span>
      </xsl:if>

    </div>
  </xsl:template>

  <!-- Display plain text, but with words like _this_ replaced by <strong> emphasis -->
  <xsl:template name="emphasize-underlined">
    <xsl:param name="text" as="xs:string" select="string(.)" />
    <xsl:analyze-string select="$text" regex="_([^_]+)_">
      <xsl:matching-substring>
        <strong>
          <xsl:value-of select="regex-group(1)" />
        </strong>
      </xsl:matching-substring>
      <xsl:non-matching-substring><xsl:value-of select="." /></xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>

</xsl:stylesheet>
