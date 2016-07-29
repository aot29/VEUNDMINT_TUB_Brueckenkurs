<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="/page">
		<html lang="de">
		    <head>
			    <meta charset="utf-8"/>
			    <title><xsl:value-of select="title" /></title>
			    <!--touch zooming-->
	    		<meta name="viewport" content="width=device-width, initial-scale=1" />
		    </head>
		    <body>
		    </body>
		</html>
	</xsl:template>
	
</xsl:stylesheet>