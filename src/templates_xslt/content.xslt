<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="content">
		<xsl:param name="selectedPage" />
		
		<!-- Top level pages don't have a tab bar at the top, so need in-line CSS to override -->
		<xsl:variable name="inlineCss"><xsl:if test="$selectedPage/@level = 1 or $selectedPage/@level = 2">border: 1px solid #ccc; border-radius: 4px;</xsl:if></xsl:variable>

		<div class="row" id="pageContents" style="{$inlineCss}">
			<!-- Copy whatever is in content to the output tree -->
			<xsl:copy-of select="*" />

			<!-- Add a module launch button to module overview pages (level 2) -->
			<xsl:if test="$selectedPage/@level = 2">
				<a type="button" class="btn btn-primary center-block" href="{@href}" style="margin-top: 2em; width: 33%;">
					<span data-toggle="i18n" data-i18n="module_starttext"/>: <xsl:value-of select="$selectedPage/caption" />
				</a>
			</xsl:if>
			
		</div>
	</xsl:template>

</xsl:stylesheet>