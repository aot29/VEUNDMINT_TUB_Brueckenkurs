<!DOCTYPE xsl:stylesheet [ <!ENTITY nbsp "&#160;"> ]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template name="navbar">
		<xsl:param name="disableLogin" select="0"/>
		<xsl:comment>top navbar</xsl:comment>
		<div class="navbar navbar-default navbar-fixed-top" role="navigation" id="navbarTop">
			<div class="container-fluid" id="navbarContainer">
				<div class="row-fluid" id="toolsRow">
					<ul class="nav navbar-nav">
						<li><a id="menuButton" type="button" data-toggle="offcanvas" class="visible-sm visible-xs"><span class="glyphicon glyphicon-menu-hamburger"></span></a></li>
						<li><a href="{@basePath}/{@lang}/index.html" data-toggle="tooltip" id="homebutton"><span class="glyphicon glyphicon-home"></span></a></li>
						<li><a data-toggle="tooltip" id="listebutton" href="{@basePath}/{@lang}/search.html"><span class="glyphicon glyphicon-book"></span></a></li>
						<li><a data-toggle="tooltip" id="databutton" href="{@basePath}/{@lang}/data.html"><span class="glyphicon glyphicon-dashboard"></span></a></li>
						<li><a data-toggle="tooltip" id="pdfbutton" href="{@basePath}/../pdf/veundmint_{@lang}.pdf"><span class="glyphicon glyphicon-save-file"></span></a></li>
					</ul>

					<ul class="nav navbar-nav navbar-right">
						<xsl:if test="$disableLogin=0">

							<!-- Show these when not logged in -->
							<li class="dropdown" id="logged_out_buttons" style="display: none;">
								<a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">Login <span class="caret"></span></a>
								<ul class="dropdown-menu">
									<li><a href="{@basePath}/{@lang}/login.html" id="loginButton">
											<span id="loginbutton_text" data-toggle="i18n" data-i18n="ui-loginbutton"></span>
										</a>
									</li>
									<li><a href="{@basePath}/{@lang}/signup.html">
										<span id="signup_text" data-toggle="i18n" data-i18n="ui-signupbutton"></span>
									</a></li>
							  </ul>
							</li>

							<!-- Show these when logged in -->
							<li class="dropdown" id="logged_in_buttons" style="display: none;">
								<a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false"><span class="glyphicon glyphicon-user"></span> Profil <span class="caret"></span></a>
								<ul class="dropdown-menu">
									<li id="li-course-data">
										<a href="{@basePath}/{@lang}/data.html">
											<span class="glyphicon glyphicon-dashboard"></span>&nbsp;<span id="databutton_text" data-toggle="i18n" data-i18n="ui-databutton"></span>
										</a>
									</li>
									<li id="li-profile">
										<a href="{@basePath}/{@lang}/signup.html">
											<span class="glyphicon glyphicon-list-alt"></span>&nbsp;<span id="ccount_text" data-toggle="i18n" data-i18n="msg-myaccount"></span>
										</a>
									</li>
									<li id="li-logout">
										<a href="{@basePath}/{@lang}/logout.html">
											<span class="glyphicon glyphicon-off"></span>&nbsp;<span id="logoutbutton_text" data-toggle="i18n" data-i18n="ui-logoutbutton"></span>
										</a>
									</li>
								</ul>
							</li>

						</xsl:if>
					</ul>

					<!-- rendered in js (veundmint.js) note: even though its later in dom its rendered first
							 which occurs when there are two elements with class="navbar-right" -->
					<div id="languageChooser"></div>

				</div>
			</div>
		</div>
		<xsl:comment>end top navbar</xsl:comment>
	</xsl:template>
</xsl:stylesheet>
