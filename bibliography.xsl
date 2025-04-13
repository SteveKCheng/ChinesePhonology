<xsl:stylesheet 
  version="2.0" 
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:bib="http://www.gold-saucer.org/xmlns/bibliography"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="bib">

  <xsl:template match="bib:bibliography">
    <dl class="bibliography">
      <xsl:for-each select="bib:*">
        <dt>
          <xsl:call-template name="get-biblio-key" />
        </dt>
        <dd>
          <xsl:apply-templates mode="biblio" select="." />
        </dd>
      </xsl:for-each>
    </dl>
  </xsl:template>

  <xsl:template mode="biblio" match="bib:*">
  </xsl:template>

  <xsl:template mode="biblio" match="bib:book">
    <xsl:call-template name="display-biblio-author" />
    <xsl:call-template name="display-biblio-title" />
    <xsl:call-template name="display-biblio-publisher" />
  </xsl:template>

  <xsl:template mode="biblio" match="bib:article">
    <xsl:call-template name="display-biblio-author" />
    <xsl:call-template name="display-biblio-title" />
    <xsl:call-template name="display-biblio-journal" />
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
    <xsl:for-each select="bib:author">
      <xsl:if test="position()>1">
        <xsl:text>; </xsl:text>
      </xsl:if>
      <xsl:apply-templates />
      <xsl:call-template name="display-biblio-trans">
        <xsl:with-param name="original" select="." />
      </xsl:call-template>
      <xsl:if test="position()=last()">
        <xsl:text>. </xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="display-biblio-title">
    <xsl:for-each select="bib:title[1]">
      <xsl:apply-templates />
      <xsl:call-template name="display-biblio-trans">
        <xsl:with-param name="original" select="." />
      </xsl:call-template>

      <xsl:call-template name="display-biblio-part">
        <xsl:with-param name="part" select="../bib:edition" />
        <xsl:with-param name="delimiter">; </xsl:with-param>
      </xsl:call-template>

      <xsl:text>. </xsl:text>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="display-biblio-publisher">
    <xsl:for-each select="bib:publisher[1]">
      <xsl:apply-templates />
      <xsl:call-template name="display-biblio-trans">
        <xsl:with-param name="original" select="." />
      </xsl:call-template>

      <xsl:call-template name="display-biblio-part">
        <xsl:with-param name="part" select="../bib:year" />
        <xsl:with-param name="delimiter">, </xsl:with-param>
      </xsl:call-template>

      <xsl:text>. </xsl:text>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="display-biblio-journal">
    <xsl:for-each select="bib:journal[1]">
      <br />
      <xsl:apply-templates />
      <xsl:call-template name="display-biblio-trans">
        <xsl:with-param name="original" select="." />
      </xsl:call-template>

      <xsl:call-template name="display-biblio-part">
        <xsl:with-param name="part" select="../bib:volume" />
        <xsl:with-param name="delimiter">, volume </xsl:with-param>
      </xsl:call-template>

      <xsl:call-template name="display-biblio-part">
        <xsl:with-param name="part" select="../bib:issue" />
        <xsl:with-param name="delimiter">, issue </xsl:with-param>
      </xsl:call-template>

      <xsl:call-template name="display-biblio-year-month" />

      <xsl:call-template name="display-biblio-part">
        <xsl:with-param name="part" select="../bib:pages" />
        <xsl:with-param name="delimiter">, pages </xsl:with-param>
      </xsl:call-template>

      <xsl:text>. </xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- Display a part of a bibliographical entry that may be optional, preceded by a delimiter. -->
  <xsl:template name="display-biblio-part">
    <xsl:param name="part" required="yes" />
    <xsl:param name="delimiter" required="yes" />

    <xsl:for-each select="$part[1]">
      <xsl:value-of select="$delimiter" />
      <xsl:apply-templates />

      <xsl:call-template name="display-biblio-trans">
        <xsl:with-param name="original" select="." />
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <!-- Display an optional year and month (for a journal), preceded by a comma. 
       The month is spelled out in full in English. -->
  <xsl:template name="display-biblio-year-month">
    <xsl:param name="year" select="../bib:year[1]" />
    <xsl:param name="month" select="../bib:month[1]" />
    <xsl:if test="$year">
      <xsl:text>, </xsl:text>
      <xsl:choose>
        <xsl:when test="$month">
          <xsl:value-of select="format-date(xs:date(concat($year, '-', $month, '-01')), '[MNn] [Y]', 'en', (), ())" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$year" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template name="display-biblio-trans">
    <xsl:param name="original" required="yes" />

    <xsl:variable name="p" select="$original/position()" />
    <xsl:variable name="n" select="$original/local-name()" />
    <xsl:variable name="t" select="($original/../bib:trans/bib:*[local-name()=$n])[position()=$p]" />

    <xsl:if test="$t">
      <xsl:text> ⦅</xsl:text>
      <xsl:apply-templates select="$t/node()" />
      <xsl:text>⦆</xsl:text>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>