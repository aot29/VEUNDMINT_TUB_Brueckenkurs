<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:import href="mathJax.xslt" />

	<xsl:template match="/page">
		<html lang="{@lang}">
		    <head>
			    <meta charset="utf-8"/>
			    <title><xsl:value-of select="title" /></title>
	    		<meta name="viewport" content="width=device-width, initial-scale=1" />
	    		<xsl:call-template name="css"/>
	    		<xsl:call-template name="js"/>
	    		<xsl:call-template name="mathJax"/>
		    </head>
		    <body>
		    </body>
		</html>
	</xsl:template>
		
	<xsl:template name="css">
        <link rel="stylesheet" type="text/css" href="qtip2/jquery.qtip.min.css" />
        <link rel="stylesheet" type="text/css" href="datatables/min.css" />
        <link rel="stylesheet" type="text/css" href="bootstrap/css/bootstrap.css" />
        <link rel="stylesheet" type="text/css" href="bootstrap/css/bootstrap-theme.css" />
        <link rel="stylesheet" type="text/css" href="css/veundmint_theme.css" />
	</xsl:template>
	
	<xsl:template name="js">
        <script src="../jQuery/jquery-2.2.4.js" type="text/javascript"></script>
        <script src="../bootstrap/js/bootstrap.js" type="text/javascript"></script>
        <script src="../js/mintscripts_bootstrap.js" type="text/javascript"></script>
        <script src="../es5-sham.min.js" type="text/javascript"></script>
        <script src="../qtip2/jquery.qtip.min.js" type="text/javascript"></script>
        <script src="../datatables/datatables.min.js" type="text/javascript"></script>
        <script src="../knockout-3.0.0.js" type="text/javascript"></script>
        <script src="../math.js" type="text/javascript"></script>
        <script src="../dynamiccss.js" type="text/javascript"></script>
        <script src="../convinfo.js" type="text/javascript"></script>
        <script src="../mparser.js" type="text/javascript"></script>
        <script src="../scormwrapper.js" type="text/javascript"></script>
        <script src="../dlog.js" type="text/javascript"></script>
        <script src="../userdata.js" type="text/javascript"></script>
        <script src="../mintscripts.js" type="text/javascript"></script>
        <script src="../intersite.js" type="text/javascript"></script>
        <script src="../exercises.js" type="text/javascript"></script>
        <script src="../mintscripts.js" type="text/javascript"></script>
        <script src="../servicescripts.js" type="text/javascript"></script>
        <script src="../CLDRPluralRuleParser/src/CLDRPluralRuleParser.js" type="text/javascript"></script>
        <script src="../jquery.i18n.js" type="text/javascript"></script>
        <script src="../jquery.i18n.messagestore.js" type="text/javascript"></script>
	</xsl:template>
	
</xsl:stylesheet>