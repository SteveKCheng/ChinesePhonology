<xsl:stylesheet 
  version="2.0" 
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:bib="http://www.gold-saucer.org/xmlns/bibliography"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="bib">

  <xsl:template match="bib:bibliography">
    <xsl:apply-templates mode="biblio" />
  </xsl:template>

  <xsl:template mode="biblio" match="bib:*">
  </xsl:template>

  <xsl:template mode="biblio" match="bib:book">
    <p class="bibliography book">
    <xsl:call-template name="display-biblio-author" />
    <xsl:call-template name="display-biblio-title" />
    <xsl:call-template name="display-biblio-publisher" />
    </p>
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
      <xsl:variable name="edition" select="../bib:edition[1]" />
      <xsl:if test="$edition">
        <xsl:text>; </xsl:text>
        <xsl:apply-templates select="$edition/node()" />
        <xsl:call-template name="display-biblio-trans">
          <xsl:with-param name="original" select="$edition" />
        </xsl:call-template>
      </xsl:if>
      <xsl:text>. </xsl:text>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="display-biblio-publisher">
    <xsl:for-each select="bib:publisher[1]">
      <xsl:apply-templates />
      <xsl:call-template name="display-biblio-trans">
        <xsl:with-param name="original" select="." />
      </xsl:call-template>
      <xsl:variable name="year" select="../bib:year[1]" />
      <xsl:if test="$year">
        <xsl:text>, </xsl:text>
        <xsl:apply-templates select="$year/node()" />
      </xsl:if>
      <xsl:text>. </xsl:text>
    </xsl:for-each>
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