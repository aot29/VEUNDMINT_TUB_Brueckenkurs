<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template name="mathJax">
	<script type="text/x-mathjax-config">
		<![CDATA[
		MathJax.Hub.Config({
		  jax: ["input/TeX","input/MathML", "output/CommonHTML"],
		  extensions: ["tex2jax.js", "mml2jax.js", "MathMenu.js", "MathZoom.js"],
		  TeX: {
		    extensions: ["AMSmath.js","AMSsymbols.js","noErrors.js","noUndefined.js"],
		    Macros: {
		      RR: '{\\bf R}',
		      bold: ['{\\bf #1}', 1]
		    }
		  },
		  tex2jax: {
		    ignoreClass: "tex2jaxignore",
		    inlineMath: [['\\(','\\)']],
		    displayMath: [['\\[','\\]']]
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
	<script type="text/javascript" src="https://cdn.mathjax.org/mathjax/2.6-latest/MathJax.js?locale="></script>
	</xsl:template>

</xsl:stylesheet>