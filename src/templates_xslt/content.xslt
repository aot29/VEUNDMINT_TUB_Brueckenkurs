<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="page" mode="content">
		<!-- The currently selected module -->
		<xsl:variable name="selectedModule" select="toc/entries/entry[@selected='True']" />	
		<!-- The currently selected section -->
		<xsl:variable name="selectedPage" select="toc/entries/entry[@selected='True']/children/entry/children/entry[@selected='True']" />
		<!-- Is the selected page a module page? -->
		<xsl:variable name="isModuleSelected" select="not ($selectedPage) and $selectedModule" />
		
		<!-- Module level pages don't have a tab bar at the top, so need in-line CSS to override -->
		<xsl:variable name="inlineCss"><xsl:if test="$isModuleSelected">border: 1px solid #ccc; border-radius: 4px;</xsl:if></xsl:variable>

		<div class="row" id="pageContents" style="{$inlineCss}">
			<!-- Copy whatever is in content to the output tree -->
			<xsl:copy-of select="content/*" />

			<!-- Add a module launch button to module overview pages -->
			<xsl:if test="$isModuleSelected">
				<a type="button" class="btn btn-primary center-block" href="{navNext/@href}" style="margin-top: 2em; width: 33%;">
					<span data-toggle="i18n" data-i18n="module_starttext"/>: <xsl:value-of select="$selectedModule/caption" />
				</a>
			</xsl:if>
			
		</div>
	</xsl:template>

</xsl:stylesheet>