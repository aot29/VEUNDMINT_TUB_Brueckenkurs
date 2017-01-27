<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [ <!ENTITY nbsp "&#160;"> ]>

<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:import href="headers.xslt" />
	<xsl:import href="jsFooter.xslt" />
	<xsl:import href="navbar.xslt" />
	<xsl:import href="toc.xslt" />
	<xsl:import href="tabs.xslt" />
	<xsl:import href="content.xslt" />
	<xsl:import href="pageFooter.xslt" />

	<!-- There is no doctype html5, use legacy-compat instead -->
	<xsl:output method="html" doctype-system="about:legacy-compat" encoding="UTF-8" indent="yes" />

	<xsl:template match="/page">

		<html lang="{@lang}">
			<head>
				<meta charset="utf-8" />
				<title><xsl:value-of select="title" /></title>
				<meta name="viewport" content="width=device-width, initial-scale=1" />

				<!-- Stylesheets, External JS, MathJax, i18n -->
				<xsl:apply-templates select="." mode="headers" />
			</head>

			<body>
				<!-- Navigation bar at the top of the page -->
				<xsl:call-template name="navbar">
					<xsl:with-param name="disableLogin" select="@disableLogin" />
				</xsl:call-template>
				<div class="row-offcanvas row-offcanvas-left">
					<div id="sidebar" class="sidebar-offcanvas">
						<div class="col-md-12">
							<!-- TOC -->
							<xsl:apply-templates select="." mode="toc" />
						</div>
					</div>
					<div id="main">
						<div class="col-md-12">

							<!-- Page tabs -->
							<xsl:apply-templates select="." mode="tabs" />
							<!-- Page contents-->
							<xsl:apply-templates select="." mode="content" />
							<!-- Page tabs -->
							<xsl:apply-templates select="." mode="tabs-bottom" />
							<!-- Footer -->
							<xsl:apply-templates mode="pageFooter" select="." />
						</div>
					</div>
				</div><!--/row-offcanvas -->


				<!-- JS in footer -->
				<xsl:call-template name="jsFooter" />

			</body>
		</html>
	</xsl:template>

</xsl:stylesheet>
