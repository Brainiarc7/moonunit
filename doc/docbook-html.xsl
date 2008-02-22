<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:html="http://www.w3.org/1999/xhtml"
		version="1.0">
  <xsl:import href="/usr/share/xml/docbook/stylesheet/nwalsh/xhtml/profile-chunk.xsl"/>
  <xsl:template name="generate.citerefentry.link">
    <xsl:value-of select="refentrytitle"/>.<xsl:value-of select="manvolnum"/>.html
  </xsl:template>
</xsl:stylesheet>
