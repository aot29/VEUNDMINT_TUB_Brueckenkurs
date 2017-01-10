<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:import href="mathJax.xslt" />

	<xsl:template match="page" mode="headers">
		
		<!-- MathJax -->
		<xsl:call-template name="mathJax">
			<xsl:with-param name="basePath" select="@basePath" />
		</xsl:call-template>


		<xsl:comment>
			inject:css
		</xsl:comment>
		<xsl:comment>
			endinject
		</xsl:comment>


	</xsl:template>

</xsl:stylesheet>
