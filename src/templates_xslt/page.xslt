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
				<xsl:call-template name="navbar" />
				
				<!-- Page contents, tabs, TOC and footer -->
				<div id="pageContainer" >		          
					<div class="row" style="margin: 0 15px 0 15px;">
				        <div class="col-xs-12">
				            <div class="row row-offcanvas row-offcanvas-left">
	
								<!-- TOC -->
								<xsl:apply-templates select="toc" />
								<div class="col-xs-12 col-sm-12 col-md-9" id="courseContent">
	
									<!-- Page tabs -->
									<xsl:apply-templates select="." mode="tabs" />

									<!-- Page contents-->
									<xsl:apply-templates select="." mode="content" />
														                
									<!-- Footer -->
									<xsl:call-template name="pageFooter">
										<xsl:with-param name="basePath" select="@basePath" />
									</xsl:call-template>

								</div>	
							</div>
						</div>
					</div>
				</div>
				
				<!-- JS in footer -->
				<xsl:call-template name="jsFooter" />

			</body>
		</html>
	</xsl:template>

</xsl:stylesheet>