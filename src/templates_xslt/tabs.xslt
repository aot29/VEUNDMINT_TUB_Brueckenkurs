<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	
	<!-- Tabs bar -->
	<xsl:template match='toc/entries' mode="tabs">
		<xsl:comment>Tabs</xsl:comment>
		<div class="row" id="subtoc" >
		<div class="col-sm-1 ffrwButton"><div class="glyphicon glyphicon-chevron-left pull-left"></div></div>
		<div class="col-xs-12 col-sm-10" style="padding: 0;">
			<ul class="nav nav-tabs nav-justified">
				<xsl:apply-templates select="entry" mode="tab" />
			</ul>
			</div>
		<div class="col-sm-1 ffrwButton"><div class="glyphicon glyphicon-chevron-right pull-right"></div></div>
		</div>
		<xsl:comment>End start tabs</xsl:comment>
	</xsl:template>

	<!-- Single tab -->
	<xsl:template match="entry" mode="tab">
		<xsl:variable name="cssClass"><xsl:if test="@selected = 'True'">active</xsl:if></xsl:variable>
		<li class="{$cssClass}">
			<a href="{@href}"><xsl:value-of select="caption"/></a>
		</li>
	</xsl:template>

</xsl:stylesheet>