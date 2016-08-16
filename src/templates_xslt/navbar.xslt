<!DOCTYPE xsl:stylesheet [ <!ENTITY nbsp "&#160;"> ]>
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
							<a data-toggle="tooltip-navbar" id="loginbutton" href="../../config.html" class="btn btn-default btn-sm disabled" >
								<span class="glyphicon glyphicon-user"></span>&nbsp;<span data-toggle="i18n" data-i18n="ui-loginbutton"/>
							</a>
						</div>
					</div>
					<div class="col-sm-6" id="toolsSidebar">
					
						<xsl:comment>tools</xsl:comment>
						<div class="dropdown pull-right">
						    <a href="#" data-toggle="dropdown" class="dropdown-toggle"><span class=" glyphicon glyphicon-cog" /><b class="caret"></b></a>
						    <ul class="dropdown-menu">
								<li><a data-toggle="tooltip" id="zoomoutbutton" onclick="changeFontSize(-5);" class="btn btn-link glyphicon glyphicon-zoom-out"></a></li>
								<li><a data-toggle="tooltip" id="zoominbutton" onclick="changeFontSize(5);" class="btn btn-link glyphicon glyphicon-zoom-in"></a></li>
							</ul>
				        </div>
						<xsl:comment>end tools</xsl:comment>
					</div>				
				</div>
			</div>
		</div>
		<xsl:comment>end top navbar</xsl:comment>
	</xsl:template>    
</xsl:stylesheet>