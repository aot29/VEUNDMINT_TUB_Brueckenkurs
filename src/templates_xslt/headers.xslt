<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:import href="css.xslt" />
	<xsl:import href="js.xslt" />
	<xsl:import href="mathJax.xslt" />
	<xsl:import href="i18n.xslt" />

	<xsl:template match="page" mode="headers">
		
		<!-- Stylesheets -->
		<xsl:call-template name="css">
			<xsl:with-param name="basePath" select="@basePath" />
		</xsl:call-template>
		
		<!-- External JS -->
		<xsl:call-template name="js" >
			<xsl:with-param name="basePath" select="@basePath" />
		</xsl:call-template>
		
		<!-- MathJax -->
		<xsl:call-template name="mathJax" />
		
		<!-- i18n -->
		<xsl:call-template name="i18n">
			<xsl:with-param name="lang" select="@lang" />
		</xsl:call-template>
		
	</xsl:template>

</xsl:stylesheet>