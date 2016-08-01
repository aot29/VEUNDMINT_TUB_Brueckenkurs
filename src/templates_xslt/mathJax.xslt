<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template name="mathJax">
		<script type="text/javascript" src="https://cdn.mathjax.org/mathjax/2.6-latest/MathJax.js?locale=de"></script>
		<script type="text/x-mathjax-config">
		<![CDATA[
			MathJax.Hub.Config({
			  jax: [":directmaterial:input/TeX",":directmaterial:input/MathML", ":directmaterial:output/CommonHTML"],
			  extensions: [":directmaterial:tex2jax.js", ":directmaterial:mml2jax.js", ":directmaterial:MathMenu.js", ":directmaterial:MathZoom.js"],
			  TeX: {
			    extensions: [":directmaterial:AMSmath.js",":directmaterial:AMSsymbols.js",":directmaterial:noErrors.js",":directmaterial:noUndefined.js"],
			    Macros: {
			      RR: '{\\\\bf R}',
			      bold: ['{\\\\bf #1}', 1]
			    }
			  },
			  tex2jax: {
			    ignoreClass: "tex2jaxignore",
			    inlineMath: [['\\\\(','\\\\)']],
			    displayMath: [['\\\\[','\\\\]']]
			  },
			  "CommonHTML": {
			    scale: 100,
			    minScaleAdjust: 80,
			    mtextFontInherit: true,
			    linebreak: { automatic: false, width: "container" },
			  },
			  "fast-preview": {
			      disabled: true
			  },
			  menuSettings: { zoom: "Double-Click", zscale: "200%" }
			});
			MathJax.Hub.processSectionDelay = 0;
		]]>
		</script>
	</xsl:template>

</xsl:stylesheet>