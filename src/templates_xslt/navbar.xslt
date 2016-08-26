<!DOCTYPE xsl:stylesheet [ <!ENTITY nbsp "&#160;"> ]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template name="navbar">
		<xsl:comment>top navbar</xsl:comment>
		<div class="navbar navbar-default navbar-fixed-top" role="navigation" id="navbarTop">
			<div class="container-fluid ">
				<div class="row" style="margin-left: 0;margin-top: 10px; margin-right: 1em;">
					<div class="col-sm-6 navbar-left" id="toggle_sidebar" role="navigation">
						<div id="tools" class="btn-group pull-left">
							<button id="menuButton" type="button" data-toggle="offcanvas" class="btn btn-link glyphicon glyphicon-menu-hamburger visible-sm visible-xs">
							</button>
							
							<a data-toggle="tooltip" id="homebutton" href="{@basePath}/{@lang}/index.html" class="btn btn-link glyphicon glyphicon-home"></a>
							<a data-toggle="tooltip" id="listebutton" href="{@basePath}/{@lang}/search.html" class="btn btn-link glyphicon glyphicon-book"></a>
							<a data-toggle="tooltip" id="databutton" href="{@basePath}/{@lang}/data.html" class="btn btn-link glyphicon glyphicon-dashboard"></a>
							<!-- Needs more attention, how does it work? -->
							<!-- a data-toggle="tooltip" id="favoritesbutton" onclick="starClick();" class="btn btn-link glyphicon glyphicon-star-empty"/ -->
		
						</div>
					</div>
		
					<div class="col-sm-6 navbar-right" id="login_col" role="navigation">
					
						<!-- Show these when not logged in -->
						<div class="btn-group pull-right" id="logged_out_buttons" style="display: none;">
							<a type="button" href="signup.html" class="btn btn-default">
								<span class="glyphicon glyphicon-user"></span> <span id="signup_text" data-toggle="i18n" data-i18n="ui-signupbutton"></span>
							</a>
							<a type="button" href="login.html" class="btn btn-default">
								<span id="loginbutton_text" data-toggle="i18n" data-i18n="ui-loginbutton"></span>
							</a>
						</div>

						<!-- Show these when logged in -->
						<div class="btn-group pull-right" id="logged_in_buttons" style="display: none;">
							<a type="button" href="signup.html" class="btn btn-default">
								<span class="glyphicon glyphicon-user"></span> <span id="account_text" data-toggle="i18n" data-i18n="msg-myaccount"></span>
							</a>
							<a type="button" href="logout.html" class="btn btn-default">
								<span id="logoutbutton_text" data-toggle="i18n" data-i18n="ui-logoutbutton"></span>
							</a>
						</div>
						
					</div>

				</div>
			</div>
		</div>
		<xsl:comment>end top navbar</xsl:comment>
	</xsl:template>
</xsl:stylesheet>
