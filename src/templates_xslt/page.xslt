<!DOCTYPE xsl:stylesheet [ <!ENTITY nbsp "&#160;"> ]>

<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:import href="css.xslt" />
	<xsl:import href="js.xslt" />
	<xsl:import href="mathJax.xslt" />
	<xsl:import href="i18n.xslt" />
	<xsl:import href="jsFooter.xslt" />
	<xsl:import href="navbar.xslt" />
	<xsl:import href="toc.xslt" />
	
	<xsl:template match="/page">
		<!-- Path to root directory for .css and .js hrefs -->
		<xsl:variable name="basePath">..</xsl:variable>
	
		<html lang="{@lang}">
			<head>
				<meta charset="utf-8" />
				<title><xsl:value-of select="title" /></title>
				<meta name="viewport" content="width=device-width, initial-scale=1" />
				
				<!-- Stylesheets -->
				<xsl:call-template name="css">
					<xsl:with-param name="basePath" select="$basePath" />
				</xsl:call-template>
				
				<!-- External JS -->
				<xsl:call-template name="js" >
					<xsl:with-param name="basePath" select="$basePath" />
				</xsl:call-template>
				
				<!-- MathJax -->
				<xsl:call-template name="mathJax" />
				
				<!-- i18n -->
				<xsl:call-template name="i18n">
					<xsl:with-param name="lang" select="@lang" />
				</xsl:call-template>
			</head>
			<body>
				<!-- Navigation bar at the top of the page -->
				<xsl:call-template name="navbar" />
				
				<!-- Page contents and toc -->
				<div id="pageContainer">
					<div class="col-xs-12">
						<div class="row row-offcanvas row-offcanvas-left">
							<xsl:apply-templates select="toc">
								<xsl:with-param name="basePath" select="$basePath" />
							</xsl:apply-templates>
							<xsl:copy-of select="content" />
						</div>
					</div>
				</div>
				
				<!-- Footer -->
				<xsl:call-template name="jsFooter" />
			</body>
		</html>
	</xsl:template>

</xsl:stylesheet>