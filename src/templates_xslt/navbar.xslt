<!DOCTYPE xsl:stylesheet [ <!ENTITY nbsp "&#160;"> ]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template name="navbar">
		<xsl:comment>top navbar</xsl:comment>
		<div class="navbar navbar-default navbar-fixed-top" role="navigation" id="navbarTop">
			<div class="container-fluid ">
				<div class="row" style="margin-left: 0;margin-top: 10px; ">
				    <div class="col-sm-3 navbar-left" id="toggle_sidebar" role="navigation" >
				     	<div id="tools">
							<button id="menuButton" type="button" data-toggle="offcanvas" class="btn btn-link glyphicon glyphicon-menu-hamburger" style="float:left">
							</button>
							<a data-toggle="tooltip-navbar" id="loginbutton" href="{@basePath}/{@lang}/config.html" class="btn btn-default btn-sm" >
								<span class="glyphicon glyphicon-user"></span>&nbsp;<span data-toggle="i18n" data-i18n="ui-loginbutton"/>
							</a>
							<a data-toggle="tooltip" id="homebutton" href="{@basePath}/{@lang}/index.html" class="btn btn-link glyphicon glyphicon-home"></a>
							<a data-toggle="tooltip" id="listebutton" href="{@basePath}/{@lang}/search.html" class="btn btn-link glyphicon glyphicon-book"></a>
							<a data-toggle="tooltip" id="databutton" href="{@basePath}/{@lang}/data.html" class="btn btn-link glyphicon glyphicon-dashboard"></a>
							<!-- Needs more attention, how does it work? -->
							<!-- a data-toggle="tooltip" id="favoritesbutton" onclick="starClick();" class="btn btn-link glyphicon glyphicon-star-empty"/ -->
						</div>
					</div>
					<div class="col-sm-9">
					</div>				
				</div>
			</div>
		</div>
		<xsl:comment>end top navbar</xsl:comment>
	</xsl:template>    
</xsl:stylesheet>