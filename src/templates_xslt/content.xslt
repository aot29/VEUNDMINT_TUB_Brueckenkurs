<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="page" mode="content">
		<!-- The currently selected module -->
		<xsl:variable name="selectedModule" select="toc/entries/entry[@selected='True']" />
		<!-- The currently selected section -->
		<xsl:variable name="selectedPage" select="toc/entries/entry[@selected='True']/children/entry/children/entry[@selected='True']" />

		<!-- Is the selected page a module page? -->
		<xsl:variable name="isModuleSelected" select="not ($selectedPage) and $selectedModule" />

		<!-- Module level pages don't have a tab bar at the top, so need in-line CSS to override -->
		<xsl:variable name="inlineCss"><xsl:if test="$isModuleSelected or @isSpecialPage='True' or @isTestPage='True'">border: 1px solid #ccc; border-radius: 4px;</xsl:if></xsl:variable>

		<div class="row" id="pageContents" style="{$inlineCss}">

			<xsl:if test="@isSpecialPage='False'">
				<xsl:call-template name="contentButtons" />
			</xsl:if>

			<!-- Placeholder. Whatever non-valid HTML comes out of TTM will be pasted here in PageTUB, after the XSLT transformation is done -->
			<content/>

			<!-- Add a module launch button to module overview pages, but not on the first page -->
			<xsl:if test="$isModuleSelected and @isCoursePage = 'True'">
				<a type="button" class="btn btn-primary btn-block btn-lg" href="{navNext/@href}" style="margin-top: 2em;">
					<span data-toggle="i18n" data-i18n="module_starttext"/>: <xsl:value-of select="$selectedModule/caption" />
				</a>
			</xsl:if>

		</div>
	</xsl:template>


	<xsl:template name="contentButtons">
		<div id="contentButtons" class="pull-right">
			<!--
			<a data-toggle="tooltip" id="zoomoutbutton" onclick="changeFontSize(-5);" class="btn btn-link glyphicon glyphicon-zoom-out"></a>
			<a data-toggle="tooltip" id="zoominbutton" onclick="changeFontSize(5);" class="btn btn-link glyphicon glyphicon-zoom-in"></a>
			 
			<button id="printbutton" onclick="window.print();" data-toggle="tooltip" type="button" class="btn btn-default"><span class="glyphicon glyphicon-print" aria-hidden="true"></span></button>
			-->
		</div>
	</xsl:template>

</xsl:stylesheet>
