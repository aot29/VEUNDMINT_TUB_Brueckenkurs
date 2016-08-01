<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template name="navbar">
		<xsl:comment>top navbar</xsl:comment>
		<div class="navbar navbar-default navbar-fixed-top" role="navigation" id="navbarTop">
			<div class="container-fluid ">
				<div class="row" style="margin-left: 0;margin-top: 10px; ">
				    <div class="col-sm-6 navbar-left" id="toggle_sidebar" role="navigation" >
				     	<div>
							<button id="menuButton" type="button" data-toggle="offcanvas" class="btn btn-link glyphicon glyphicon-menu-hamburger" style="float:left">
							</button>
							<a data-toggle="tooltip-navbar" id="loginbutton" href="../../config.html" class="btn btn-default btn-sm" >
								<span class="glyphicon glyphicon-user"></span> <span data-toggle="i18n" data-i18n="ui-loginbutton"/>
							</a>
						</div>
					</div>
					<div class="col-sm-6" id="toolsSidebar">
					
						<xsl:comment>tools</xsl:comment>
						<div class="navbar-right">
				          <a data-toggle="tooltip" id="databutton" href="../../data.html" class="btn btn-link glyphicon glyphicon-dashboard"></a>
				          <a data-toggle="tooltip" id="listebutton" href="../../search.html" class="btn btn-link glyphicon glyphicon-book"></a>
				          <a data-toggle="tooltip" id="homebutton" href="../../index.html" class="btn btn-link glyphicon glyphicon-home"></a>
				          <a data-toggle="tooltip" id="favoritesbutton" onclick="starClick();" class="btn btn-link glyphicon glyphicon-star-empty"></a>
				          <a data-toggle="tooltip" id="zoomoutbutton" onclick="changeFontSize(-5);" class="btn btn-link glyphicon glyphicon-zoom-out"></a>
				          <a data-toggle="tooltip" id="zoominbutton" onclick="changeFontSize(5);" class="btn btn-link glyphicon glyphicon-zoom-in"></a>
				          <a data-toggle="tooltip" id="sharebutton" onclick="shareClick();" class="btn btn-link glyphicon glyphicon-share-alt"></a>
				          <a data-toggle="tooltip" id="settingsbutton" onclick="toggle_settings();" class="btn btn-link glyphicon glyphicon-cog"></a>
				        </div>
						<xsl:comment>end tools</xsl:comment>
					</div>				
				</div>
			</div>
		</div>
		<xsl:comment>end top navbar</xsl:comment>
	</xsl:template>    
</xsl:stylesheet>