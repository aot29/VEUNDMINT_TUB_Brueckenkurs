<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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

		<script>
		<![CDATA[

			var isTest = false;
			var testFinished = true;
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
			var intersiteactive = false;
			var intersiteobj = createIntersiteObj();
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
			var requestLogout = 0;
			var sitejson_load = false;
			var sitejson = {};
			
			// <JSCRIPTPRELOADTAG>
			
			function loadHandler() {
			  globalloadHandler("");
			}
			
			function unloadHandler() {
			  globalunloadHandler();
			}
		
		]]>
		</script>        
	</xsl:template>

</xsl:stylesheet>