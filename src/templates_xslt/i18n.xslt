<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
		
	<xsl:template name="i18n">
		<xsl:param name="lang" />
		<xsl:param name="basePath" />
		<script>
			$.i18n();
			$.i18n().locale = '<xsl:value-of select="$lang" />';
			$.i18n().load( { '<xsl:value-of select="$lang" />' : '../../../<xsl:value-of select="$basePath" />/i18n/<xsl:value-of select="$lang" />.json' } ).done( function() {
				
	            $('[data-toggle="tooltip"]').each( function(i, el) {
	                var hint = $.i18n( 'hint-' + $(el).attr( 'id' ) );
	                $(el).attr( 'title', hint );
	            })
	            
	            // Localized texts
	            $('[data-toggle="i18n"]').each(function(i, el) {
	            	$(el).html( $.i18n( $(el).attr( 'data-i18n' ) ) );
	            });
	            
			  	globalreadyHandler("");   
			
			});
		
		</script>
	</xsl:template>

</xsl:stylesheet>