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
				<div class="col-md-12">
					<ul class="nav nav-pills">
						<li class="pill-prev"><xsl:if test="@isCoursePage = 'True'"><xsl:apply-templates select="navPrev" /></xsl:if></li>
						<xsl:apply-templates select="$selectedPage/../*" mode="tab" />
						<li class="pill-next pull-right"><xsl:if test="@isCoursePage = 'True'"><xsl:apply-templates select="navNext" /></xsl:if></li>
					</ul>
				</div>
			</xsl:if>

		</div>
		<xsl:comment>End tabs</xsl:comment>

	</xsl:template>


	<!-- Single tab -->
	<xsl:template match="entry" mode="tab">
		<xsl:variable name="cssClass"><xsl:if test="@selected = 'True'">active</xsl:if></xsl:variable>
		<li class="subtoc-pill {$cssClass}">
			<a href="{@href}"><xsl:value-of select="caption"/></a>
		</li>
	</xsl:template>

	<!-- RW and FF Buttons -->
	<xsl:template match="navPrev">
		<a id="prev-chapter" href="{@href}"><span class="glyphicon glyphicon-chevron-left"></span></a>
	</xsl:template>

	<xsl:template match="navNext">
		<a id="next-chapter" href="{@href}"><span class="glyphicon glyphicon-chevron-right"></span></a>
	</xsl:template>
</xsl:stylesheet>
