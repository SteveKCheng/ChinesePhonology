<xsl:stylesheet 
  version="2.0" 
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:p="http://www.gold-saucer.org/xmlns/chinese-phonology"
  xmlns:data="http://www.gold-saucer.org/xmlns/chinese-phonology-data"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="p data html xs">

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

  <!-- "mc" stands for terminology in Modern Chinese -->
  <xsl:template match="p:mc">
    <span lang="zh">
      <xsl:apply-templates select="node()|@*" />
    </span>
  </xsl:template>

  <!-- "ac" stands for terminology in Chinese from 'ancient' times -->
  <xsl:template match="p:ac">
    <span lang="zh">
      <xsl:call-template name="look-up-link" />
    </span>
  </xsl:template>

  <!-- Japanese term.  Could also be used to display 
       Japanese variant of kanji in case the reader might not be familiar
       with the traditional form. -->
  <xsl:template match="p:j">
    <span lang="ja">
      <xsl:apply-templates select="node()|@*" />
    </span>
  </xsl:template>

  <!-- Mark up 聲母, 韻母 given in Chinese characters. 
       This template is called when generating tables of Middle Chinese 
       phonological data.  The effect is as if the text is written
       inside a p:ac element. -->
  <xsl:template name="display-ac-phono-element">
    <xsl:param name="content" />
    <span lang="zh">
      <xsl:copy-of select="$content" />
    </span>
  </xsl:template>

  <!-- Phonetic description in the standard International Phonetic Alphabet -->
  <xsl:template match="p:i">
    <span class="ipa">
      <xsl:apply-templates select="node()|@*" />
    </span>
  </xsl:template>

  <xsl:template match="p:i-narrow">
    <span class="ipa-narrow">
      <xsl:apply-templates select="node()|@*" />
    </span>
  </xsl:template>

  <xsl:template name="display-ipa">
    <xsl:param name="content" />
    <span class="ipa">
      <xsl:copy-of select="$content" />
    </span>
  </xsl:template>

  <!-- Pinyin transcription -->
  <xsl:template match="p:py">
    <span class="pinyin">
      <xsl:apply-templates select="node()|@*" />
    </span>
  </xsl:template>

  <!-- Japanese romaji transcription -->
  <xsl:template match="p:jr">
    <span class="romaji">
      <xsl:apply-templates select="node()|@*" />
    </span>
  </xsl:template>

  <!-- Jyutping transcription -->
  <xsl:template match="p:yp">
    <span class="jyutping">
      <xsl:apply-templates select="node()|@*" />
    </span>
  </xsl:template>

  <!-- Make tone numbers expressed as ASCII digits into superscripts -->
  <xsl:template match="p:yp/text()">
    <xsl:analyze-string select="." regex="[0-9]+">
      <xsl:matching-substring><sup><xsl:value-of select="." /></sup></xsl:matching-substring>
      <xsl:non-matching-substring><xsl:value-of select="." /></xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>

</xsl:stylesheet>