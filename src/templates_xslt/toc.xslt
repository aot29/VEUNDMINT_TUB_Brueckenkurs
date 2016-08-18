<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:import href="socialMedia.xslt" />

	<xsl:template match="page" mode="toc">
		<xsl:comment>TOC side bar</xsl:comment>
		
		<div class="col-md-3 sidebar-offcanvas" id="sidebar" role="navigation" style="margin-top: 5px;">
			<div id="toc" class="panel-group"><br/>
				<!-- Add TOC title -->
				<h3>
					<span data-toggle="i18n" data-i18n="course-title"/>
				</h3>
				<xsl:apply-templates select="toc/entries/entry" />
				<xsl:call-template name="legend"/>
				<xsl:call-template name="socialMedia"/>
			</div>
		</div>
		<xsl:comment>End TOC side bar</xsl:comment>
	</xsl:template>


	<!-- Switch between selected and unselected entries -->
	<xsl:template match="entry">
		<xsl:choose>
		<xsl:when test="@selected = 'True'">
			<xsl:apply-templates select="." mode="selected" />
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="." mode="unselected" />
		</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<!-- Apply to unselected entries -->
	<xsl:template match="entry" mode="unselected">
		<div class="panel panel-default">
			<div class="panel-heading">
				<h4 class="panel-title">
					<a href="{@href}"><xsl:value-of select="caption"/></a>
				</h4>
			</div>
		</div>
	</xsl:template>

	<!-- Apply to selected entry -->
	<xsl:template match="entry" mode="selected">
		<div class="panel panel-primary">
			<div class="panel-heading">
				<h4 class="panel-title">
					<a href="{@href}"><xsl:value-of select="caption"/></a>
				</h4>
			</div>
			<div>
				<div class="panel-body">
					<xsl:apply-templates select="children" />
				</div>
			</div>
		</div>
	</xsl:template>


	<!-- entry children -->
	<xsl:template match="children">
		<ul>
			<xsl:apply-templates select="entry" mode="submenu" />
		</ul>
	</xsl:template>


	<xsl:template match="entry" mode="submenu">
		<!-- TOC entries of level 4 have icons -->
		<xsl:variable name="iconClass"><xsl:if test="@level = '4'">glyphicon glyphicon-file</xsl:if></xsl:variable>
		<xsl:variable name="highlightClass"><xsl:if test="@selected = 'True'">selectedEntry</xsl:if></xsl:variable>
		
		<!-- List entries recursively -->
		<li>
			<xsl:choose>
				<xsl:when test="@href">
					<a href="{@href}" class="{$iconClass} {@status}"><span class="entryText {$highlightClass}"><xsl:value-of select="caption"/></span></a>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="caption"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:apply-templates select="children" />
		</li>
	</xsl:template>

	
	<!-- TOC legend -->
	<xsl:template name="legend">
		<xsl:comment>Legend</xsl:comment>
		<div class="panel panel-default" id="legend">
			<div class="panel-body">
				<h4><span data-toggle="i18n" data-i18n="legend"/></h4>
				<ul class="panel">
					<li><span data-toggle="i18n" data-i18n="explanation_subsection"/></li>
					<li><div class="glyphicon glyphicon-file status1"></div><span data-toggle="i18n" data-i18n="explanation_xcontent"/></li>
					<li><div class="glyphicon glyphicon-file status2"></div><span data-toggle="i18n" data-i18n="explanation_exercises"/></li>
					<li><div class="glyphicon glyphicon-file status3"></div><span data-toggle="i18n" data-i18n="explanation_test"/></li>
				</ul>
			</div>
		</div>
	</xsl:template>
	
</xsl:stylesheet>