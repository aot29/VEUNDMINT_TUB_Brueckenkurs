<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="page" mode="pageFooter">
		<xsl:comment>Page footer</xsl:comment>
		<div class="container-fluid" style="margin: 0px;" >
			<div class="row" style="display: flex; align-items: center; margin-bottom: 2em;"  id="footer">
				<div class="col-xs-2">
					<img src="{@basePath}/../images/ccbysa80x15.png" border="0" class="pull-left"/>
				</div>
				<div class="col-xs-8" style="text-align: center">
                    <xsl:value-of select="toc/@description"/>
				</div>
				<div class="col-xs-2">
					<a href="mailto:admin@ve-und-mint.de" target="_new" class="pull-right">Mail an Admin</a>
				</div>
			</div>
		</div>
		<div class="modal fade ve-import-modal" tabindex="-1" role="dialog" aria-labelledby="mySmallModalLabel">
		  <div class="modal-dialog modal-sm" role="document">
		    <div class="modal-content">
					<div class="modal-header">
		      	Importiere Nutzerdaten
					</div>
					<div class="modal-body">
					...
					</div>
		    </div>
		  </div>
		</div>
		<xsl:comment>End page footer</xsl:comment>
	</xsl:template>

</xsl:stylesheet>
