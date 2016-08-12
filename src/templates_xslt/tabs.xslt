<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	
	<!-- Tabs bar -->
	<xsl:template match="page" mode="tabs">
		<!-- The currently selected page -->
		<xsl:variable name="selectedPage" select="toc/entries/entry[@selected='True']/children/entry/children/entry[@selected='True']" />
		
		<xsl:comment>Sub TOC (Tabs or launch button)</xsl:comment>
		<div class="row" id="subtoc" >

			<!-- If selected entry is a subsection (level 4), render tab bar with siblings -->
			<xsl:if test="$selectedPage/@level = 4">

				<div class="col-sm-1 ffrwButton">
					<xsl:if test="@isCoursePage = 'True'"><xsl:apply-templates select="navPrev" /></xsl:if>
				</div>
				
				<div class="col-xs-12 col-sm-10" style="padding: 0;">
					<ul class="nav nav-tabs nav-justified">
						<xsl:apply-templates select="$selectedPage/../*" mode="tab" />
					</ul>
				</div>
				
				<div class="col-sm-1 ffrwButton">
					<xsl:if test="@isCoursePage = 'True'"><xsl:apply-templates select="navNext" /></xsl:if>
				</div>

			</xsl:if>

		</div>
		<xsl:comment>End start tabs</xsl:comment>

	</xsl:template>
	

	<!-- RW and FF Buttons -->
	<xsl:template match="navPrev">
		<a href="{@href}"><div class="glyphicon glyphicon-chevron-left pull-left"></div></a>
	</xsl:template>
	
	<xsl:template match="navNext">
		<a href="{@href}"><div class="glyphicon glyphicon-chevron-right pull-right"></div></a>
	</xsl:template>
	

	<!-- Single tab -->
	<xsl:template match="entry" mode="tab">
		<xsl:variable name="cssClass"><xsl:if test="@selected = 'True'">active</xsl:if></xsl:variable>
		<li class="{$cssClass}">
			<a href="{@href}"><xsl:value-of select="caption"/></a>
		</li>
	</xsl:template>

</xsl:stylesheet>