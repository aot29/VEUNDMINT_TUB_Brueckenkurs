<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:import href="css.xslt" />
	<xsl:import href="js.xslt" />
	<xsl:import href="mathJax.xslt" />
	<xsl:import href="i18n.xslt" />
	<xsl:import href="jsFooter.xslt" />

	<xsl:template match="/page">
		<html lang="{@lang}">
		    <head>
			    <meta charset="utf-8"/>			    
			    <title><xsl:value-of select="title" /></title>
	    		<meta name="viewport" content="width=device-width, initial-scale=1" />
	    		<xsl:call-template name="css"/>
	    		<xsl:call-template name="js"/>
	    		<xsl:call-template name="mathJax"/>
	    		<xsl:call-template name="i18n">
	    			 <xsl:with-param name="lang" select="@lang" />
	    		</xsl:call-template>
	    		
		    </head>
		    <body>
		    	<xsl:value-of select="content"/>
	    		<xsl:call-template name="jsFooter"/>
		    </body>
		</html>
	</xsl:template>
	
</xsl:stylesheet>