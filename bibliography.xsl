<xsl:stylesheet 
  version="2.0" 
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:bib="http://www.gold-saucer.org/xmlns/bibliography"
  xmlns:s="http://www.gold-saucer.org/xmlns/structured-html"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="bib xs">

  <xsl:key 
    name="biblio"
    match="bib:*[@key]"
    use="@key" />

  <xsl:template match="s:cite">
    <xsl:text>[</xsl:text>
    <xsl:call-template name="cite-biblio" />
    <xsl:text>]</xsl:text>
  </xsl:template>

  <xsl:template name="cite-biblio">
    <a class="cite" href="#{key('biblio', @key)/generate-id()}">
      <xsl:value-of select="@key" />
    </a>
    <xsl:if test="@sec">
      <xsl:text>, §</xsl:text>
      <xsl:value-of select="@sec" />
    </xsl:if>
    <xsl:if test="@pages">
      <xsl:text>, p. </xsl:text>
      <xsl:value-of select="@pages" />
    </xsl:if>
  </xsl:template>

  <!-- Groups multiple s:cite children together so only one set
       of brackets surrounds all the items -->
  <xsl:template match="s:cite-group">
    <xsl:text>[</xsl:text>
    <xsl:for-each select="s:cite">
      <xsl:if test="position() > 1">
        <xsl:text>; </xsl:text>
      </xsl:if>
      <xsl:call-template name="cite-biblio" />
    </xsl:for-each>
    <xsl:text>]</xsl:text>
  </xsl:template>

  <!-- Copy xml:lang attribute as HTML lang attribute -->
  <xsl:template name="copy-xml-lang">
    <xsl:variable name="lang" select="(ancestor-or-self::*/@xml:lang)[last()]" />
    <xsl:if test="$lang">
      <xsl:attribute name="lang" select="$lang" />
    </xsl:if>
  </xsl:template>

  <xsl:template match="bib:bibliography">
    <dl class="bibliography">
      <xsl:for-each select="bib:*">
        <dt id="{generate-id()}">
          <xsl:call-template name="get-biblio-key" />
        </dt>
        <dd class="biblio-{local-name()}">
          <!-- Note: the language of the bibliographic entry is not propagated here
               as the generated formatting (e.g. the words "volume", "issue") 
               are in the language/style of the main text. -->
          <xsl:apply-templates mode="biblio" select="." />
        </dd>
      </xsl:for-each>
    </dl>
  </xsl:template>

  <xsl:template mode="biblio" match="bib:*">
  </xsl:template>

  <xsl:template mode="biblio" match="bib:book">
    <xsl:call-template name="display-biblio-author" />
    <xsl:call-template name="display-biblio-title">
      <xsl:with-param name="is-book" select="true()" />
    </xsl:call-template>
    <xsl:call-template name="display-biblio-series" />
    <xsl:call-template name="display-biblio-publisher" />
    <xsl:call-template name="display-biblio-contrib" />
    <xsl:call-template name="display-biblio-note" />
    <xsl:call-template name="display-biblio-link" />
  </xsl:template>

  <xsl:template mode="biblio" match="bib:article">
    <xsl:call-template name="display-biblio-author" />
    <xsl:call-template name="display-biblio-title" />
    <xsl:call-template name="display-biblio-journal" />
    <xsl:call-template name="display-biblio-series" />
    <xsl:call-template name="display-biblio-note" />
    <xsl:call-template name="display-biblio-link" />
  </xsl:template>

  <!-- Informally published articles -->
  <xsl:template mode="biblio" match="bib:misc">
    <xsl:call-template name="display-biblio-author" />
    <xsl:call-template name="display-biblio-title" />
    <xsl:call-template name="display-biblio-year-month">
      <xsl:with-param name="prefix">Last update: </xsl:with-param>
      <xsl:with-param name="suffix">. </xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="display-biblio-series" />
    <xsl:call-template name="display-biblio-note" />
    <xsl:call-template name="display-biblio-link" />
  </xsl:template>

  <xsl:template name="display-biblio-note">
    <xsl:for-each select="bib:note">
      <p class="biblio-note">
        <xsl:text>[</xsl:text>
        <xsl:choose>
          <xsl:when test="@category">
            <xsl:value-of select="@category" />
          </xsl:when>
          <xsl:otherwise>note</xsl:otherwise>
        </xsl:choose>
        <xsl:text>] </xsl:text>

        <xsl:apply-templates />
      </p>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="display-biblio-link">
    <xsl:param name="title" select="bib:title[1]" />
    
    <xsl:for-each select="bib:link">
      <p class="biblio-link">
        <xsl:variable name="class">
          <xsl:choose>
            <xsl:when test="@class = 'ad'">advertisement</xsl:when>
            <xsl:when test="@class = 'meta'">metadata</xsl:when>
            <xsl:when test="@class = 'doi'">DOI</xsl:when>
            <xsl:when test="@class = 'archive'">archive</xsl:when>
            <xsl:when test="@class = 'source'">source</xsl:when>
            <xsl:when test="@class = 'home'">home</xsl:when>
          </xsl:choose>
        </xsl:variable>

        <xsl:if test="$class != ''">
          <xsl:text>[</xsl:text>
          <xsl:value-of select="$class" />
          <xsl:text>] </xsl:text>
        </xsl:if>

        <xsl:variable name="url" select="@url" />

        <a href="{$url}">
          <xsl:attribute name="title">
            <xsl:value-of select="$title" />
            <xsl:if test="$class != ''">
              <xsl:text> [</xsl:text>
              <xsl:value-of select="$class" />
              <xsl:text>] </xsl:text>
            </xsl:if>
          </xsl:attribute>
          <xsl:choose>
            <xsl:when test="node()">
              <!-- Let source XML override the displayed text for the hyperlink.
                  Can replace long complicated URLs that are not useful to display
                  neither in print nor online. -->
              <xsl:apply-templates select="node()" />
            </xsl:when>
            <xsl:when test="@class = 'doi'">
              <!-- Parse out the DOI (Digital Object Identifier) -->
              <xsl:analyze-string select="$url" regex="^https://doi.org/([^/]+/[^/]+)$">
                <xsl:matching-substring>
                  <xsl:value-of select="regex-group(1)" />
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                  <xsl:message>warning: DOI identifier is incorrect</xsl:message>
                  <xsl:value-of select="$url" />
                </xsl:non-matching-substring>
              </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$url" />
            </xsl:otherwise>
          </xsl:choose>
        </a>
      </p>
    </xsl:for-each>

  </xsl:template>

  <xsl:template name="get-biblio-key">
    <xsl:choose>
      <xsl:when test="@key">
        <xsl:value-of select="@key" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>bib-entry-</xsl:text>
        <xsl:number level="any" 
                    from="/" 
                    count="bib:bibliography/bib:*" 
                    format="1" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="display-biblio-author">
    <p class="biblio-author">
      <xsl:call-template name="display-biblio-author-text" />
    </p>
  </xsl:template>

  <xsl:template name="display-biblio-author-text">
    <xsl:for-each select="bib:author|bib:editor">
      <xsl:if test="position()>1">
        <xsl:text>; </xsl:text>
      </xsl:if>

      <span>
        <xsl:call-template name="copy-xml-lang" />
        <xsl:apply-templates />
      </span>

      <xsl:call-template name="display-biblio-trans">
        <xsl:with-param name="original" select="." />
        <xsl:with-param name="position" select="position()" />
      </xsl:call-template>

      <xsl:if test="self::bib:editor">
        <xsl:text> [editor]</xsl:text>
      </xsl:if>

      <xsl:if test="position()=last()">
        <xsl:text>. </xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="display-biblio-title">
    <xsl:param name="is-book" as="xs:boolean" select="false()" />
    <p class="biblio-title">
      <xsl:call-template name="display-biblio-title-text">
        <xsl:with-param name="is-book" select="$is-book" />
      </xsl:call-template>
    </p>
  </xsl:template>

  <xsl:template name="display-biblio-title-text">
    <xsl:param name="is-book" as="xs:boolean" select="false()" />
    <xsl:for-each select="bib:title[1]">
      <span class="{if ($is-book) then 'biblio-book-name' else 'biblio-article-name'}">
        <xsl:call-template name="copy-xml-lang" />
        <xsl:apply-templates />
      </span>

      <xsl:call-template name="display-biblio-trans">
        <xsl:with-param name="original" select="." />
      </xsl:call-template>

      <xsl:call-template name="display-biblio-part">
        <xsl:with-param name="part" select="../bib:edition" />
        <xsl:with-param name="prefix">; </xsl:with-param>
        <xsl:with-param name="target-language" select="true()" />
      </xsl:call-template>

      <xsl:text>. </xsl:text>
    </xsl:for-each>
  </xsl:template>  

  <xsl:template name="display-biblio-series">
    <xsl:for-each select="bib:series[1]">
      <p class="biblio-series">
        <xsl:text>Series: </xsl:text>
        
        <span class="biblio-series">
          <xsl:call-template name="copy-xml-lang" />
          <xsl:apply-templates />
        </span>

        <xsl:call-template name="display-biblio-trans">
          <xsl:with-param name="original" select="." />
        </xsl:call-template>

        <xsl:text>. </xsl:text>
      </p>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="display-biblio-publisher">
    <xsl:for-each select="bib:publisher[1]">
      <p class="biblio-publisher">
        <span>
          <xsl:call-template name="copy-xml-lang" />
          <xsl:apply-templates />
        </span>
  
        <xsl:call-template name="display-biblio-trans">
          <xsl:with-param name="original" select="." />
        </xsl:call-template>

        <xsl:call-template name="display-biblio-year-month">
          <xsl:with-param name="context" select=".." />
        </xsl:call-template>

        <xsl:text>. </xsl:text>
      </p>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="display-biblio-journal">
    <xsl:for-each select="bib:journal[1]">
      <p class="biblio-journal">
        <span class="biblio-book-name">
          <xsl:call-template name="copy-xml-lang" />
          <xsl:apply-templates />
        </span>
  
        <xsl:call-template name="display-biblio-trans">
          <xsl:with-param name="original" select="." />
        </xsl:call-template>

        <xsl:call-template name="display-biblio-part">
          <xsl:with-param name="part" select="../bib:volume" />
          <xsl:with-param name="prefix">, volume </xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="display-biblio-part">
          <xsl:with-param name="part" select="../bib:issue" />
          <xsl:with-param name="prefix">, issue </xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="display-biblio-year-month">
          <xsl:with-param name="context" select=".." />
        </xsl:call-template>

        <xsl:call-template name="display-biblio-part">
          <xsl:with-param name="part" select="../bib:pages" />
          <xsl:with-param name="prefix">, pages </xsl:with-param>
        </xsl:call-template>

        <xsl:text>. </xsl:text>
      </p>
    </xsl:for-each>
  </xsl:template>

  <!-- Display a part of a bibliographical entry that may be optional, preceded by a prefix. -->
  <xsl:template name="display-biblio-part">
    <xsl:param name="part" required="yes" />
    <xsl:param name="prefix" required="yes" />
    <xsl:param name="suffix" select="''" />
    <xsl:param name="target-language" select="false()" as="xs:boolean" />

    <xsl:for-each select="$part[1]">
      <xsl:value-of select="$prefix" />

      <span>
        <xsl:if test="$target-language">
          <xsl:call-template name="copy-xml-lang" />
        </xsl:if>
        <xsl:apply-templates />
      </span>

      <xsl:call-template name="display-biblio-trans">
        <xsl:with-param name="original" select="." />
      </xsl:call-template>

      <xsl:value-of select="$suffix" />
    </xsl:for-each>
  </xsl:template>

  <!-- Display an optional year and month (for a journal), preceded by a comma. 
       The month is spelled out in full in English. -->
  <xsl:template name="display-biblio-year-month">
    <xsl:param name="prefix" select="', '" />
    <xsl:param name="suffix" select="''" />
    <xsl:param name="context" select="." />
    <xsl:variable name="year" select="$context/bib:year[1]" />
    <xsl:variable name="month" select="$context/bib:month[1]" />
    <xsl:if test="$year">
      <xsl:copy-of select="$prefix" />
      <xsl:choose>
        <xsl:when test="$month">
          <xsl:value-of select="format-date(xs:date(concat($year, '-', $month, '-01')), '[MNn] [Y]', 'en', (), ())" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$year" />
        </xsl:otherwise>
      </xsl:choose>

      <!-- Used to record the date of the original work if 
           bibliography entry refers to re-printing or new edition.
           Sometimes the reader may want to know if the work is "too old".
           We use a <original> container element to allow for future
           extension to add more information. -->
      <xsl:variable name="orig-year" select="$context/bib:original/bib:year[1]" />
      <xsl:if test="$orig-year">
        <xsl:text> (originally from </xsl:text>
        <xsl:value-of select="$orig-year" />
        <xsl:text>)</xsl:text>
      </xsl:if>

      <xsl:copy-of select="$suffix" />
    </xsl:if>
  </xsl:template>

  <xsl:template name="display-biblio-trans">
    <xsl:param name="original" required="yes" />
    <xsl:param name="position" select="1" />

    <xsl:variable name="n" select="$original/local-name()" />
    <xsl:variable name="c" select="$original/../bib:trans" />
    <xsl:variable name="t" select="($c/bib:*[local-name()=$n])[position()=$position]" />

    <xsl:for-each select="$t">
      <span class="biblio-translation">
        <xsl:call-template name="copy-xml-lang" />
        <xsl:text> ⦅</xsl:text>
        <xsl:apply-templates />
        <xsl:text>⦆</xsl:text>
      </span>
    </xsl:for-each>
  </xsl:template>

  <!-- Call out independent sections or articles when collected in a book -->
  <xsl:template name="display-biblio-contrib">
    <xsl:if test="bib:contrib">
      <ul class="biblio-contrib">
        <xsl:for-each select="bib:contrib">
          <li>
            <xsl:call-template name="display-biblio-part">
              <xsl:with-param name="part" select="bib:section" />
              <xsl:with-param name="prefix" select="'§'" />
              <xsl:with-param name="suffix" select="'. '" />
            </xsl:call-template>

            <xsl:call-template name="display-biblio-author-text" />
            <xsl:call-template name="display-biblio-title-text" />
          </li>
        </xsl:for-each>
      </ul>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>