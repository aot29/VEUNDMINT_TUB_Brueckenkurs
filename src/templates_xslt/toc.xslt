<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="toc">
		<xsl:comment>TOC side bar</xsl:comment>
		<div class="col-md-3 sidebar-offcanvas" id="sidebar" role="navigation" style="margin-top: 5px;">
			<div id="toc" class="panel-group">
				<h3><span data-toggle="i18n" data-i18n="module_content"/></h3>
				<xsl:apply-templates select="entries/entry"/>
				<xsl:call-template name="legend"/>
            </div>
        </div>
		<xsl:comment>End TOC side bar</xsl:comment>
	</xsl:template>

	<xsl:template match="entry">
		<div class="panel panel-default">
			<div class="panel-heading">
				<h4 class="panel-title">
					<a data-toggle="collapse" data-parents="#toc" href="{@href}"><xsl:value-of select="title"/></a>
				</h4>
			</div>
		</div>
	</xsl:template>

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