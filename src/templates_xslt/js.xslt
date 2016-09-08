<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="page" mode="js">
		<xsl:param name="basePath" />
        <!-- <script src="{$basePath}/jQuery/jquery-2.2.4.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/bootstrap/js/bootstrap.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/js/mintscripts_bootstrap.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/es5-sham.min.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/qtip2/jquery.qtip.min.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/datatables/datatables.min.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/knockout-3.0.0.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/math.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/convinfo.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/mparser.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/scormwrapper.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/dlog.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/userdata.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/intersite.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/exercises.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/servicescripts.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/CLDRPluralRuleParser/src/CLDRPluralRuleParser.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/jquery.i18n.js" type="text/javascript"></script><xsl:text>&#xa;</xsl:text>
        <script src="{$basePath}/jquery.i18n.messagestore.js" type="text/javascript"></script> -->

		<script>

			var isTest = <xsl:value-of select="@isTest" />;
			var requestLogout = <xsl:value-of select="@requestLogout" />;
			<![CDATA[
			var nMaxPoints = 0;
			var nPoints = 0;
			var testFinished = null;
			var FVAR = new Array();
			FVAR.push("CounterDummy");
			var MVAR = new Array();
			var SOLUTION_TRUE = 1; var SOLUTION_FALSE = 2; var SOLUTION_NEUTRAL = 3;
			var QCOLOR_TRUE = "#44FF33"; var QCOLOR_FALSE = "#F0A4A4"; var QCOLOR_NEUTRAL = "#E0E0E0";
			var objScormApi = null;
			var viewmodel;
			var activeinputfieldid = "";
			var activetooltip = null;
			var activefieldid = "";
			var sendcounter = 0;

			var localStoragePresent = false;
			var SITE_ID = "(unknown)";
			var SITE_UXID = "(unknown)";
			var SITE_PULL = 0;
			var STYLEBLUE = "0";
			var STYLERED = "1";
			var STYLEGREEN = "2";
			var STYLEGREY = "3";
			var animationSpeed = 250;
			var timerMillis = 250;
			var timerActive = false;
			var timerVar = null;
			var timerColors = new Array();
			var timerIterator = 0;
			]]>

			<!-- Create question objects  -->
			<xsl:apply-templates select="questions/question" />

			var SITE_ID = "<xsl:value-of select="@siteId" />";
			var SITE_UXID = "<xsl:value-of select="@uxId" />";
			var SECTION_ID = "<xsl:value-of select="@sectionId" />";

			<!-- Paths -->
			var linkPath = "<xsl:value-of select="$basePath" />";
			var imagesPath = "<xsl:value-of select="$basePath" />/images";

			<!-- Roulette exercises -->
			var docName = "<xsl:value-of select="@docName" />";
			var fullName = "<xsl:value-of select="@fullName" />";
			var sitejson_load = true;
			var sitejson = {};
			<!-- xsl:apply-templates select="roulettes/roulette" / -->

			<!-- Event handlers -->
	    	<![CDATA[

				$(document).ready(function() {

	            // footer at bottom of column
	            // don't use navbar-fixed-bottom, as it doesn't play well with offcanvas
	            $(window).resize( positionFooter );
	            positionFooter();

	            // body onload
	            globalloadHandler("");

	            // on the logout page
	            if( requestLogout ) {
	            	localStorage.clear();
	            }

	        });

	        function positionFooter() {
	            var docHeight = $(window).height();
	            var offsetHeight = $( "#navbarTop" ).height() + $( "#subtoc" ).height() + $( "#footer" ).height() * 2;
	            $( "#pageContents" ).css( "minHeight", docHeight - offsetHeight + "px" );
	        }
			]]>
	    </script>
	</xsl:template>

	<xsl:template match="question">
		<xsl:value-of select="." />
		<!-- a new line -->
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="roulette">
		<xsl:if test="@myid = 0">sitejson['_RLV_<xsl:value-of select="@rid"/>'] = list();</xsl:if>
		sitejson["_RLV_<xsl:value-of select="@rid"/>"].append( '<div id="DROULETTE{@rid}.{@myid}"><button type="button" class="roulettebutton" onclick="rouletteClick( {@rid}, {@myid}, {@maxid});">roulette_new</button><br/></div>');
	</xsl:template>


</xsl:stylesheet>
