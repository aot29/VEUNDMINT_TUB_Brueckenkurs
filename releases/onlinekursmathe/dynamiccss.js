var COLORS = new Object();
COLORS.CONTENT = "000000";
COLORS.CONTENTANCHOR = "483AA1";
COLORS.CONTENTBACKGROUND = "FFFFFF";
COLORS.EXMPBACKGROUND = "FFDCEC";
COLORS.EXMPLINE = "EFC2C3";
COLORS.EXPEBACKGROUND = "DFDCBC";
COLORS.EXPELINE = "CFC2A3";
COLORS.FOOT = "202070";
COLORS.FOOTBACKGROUND = "2F6C97";
COLORS.GENERALBORDER = "A0B0D0";
COLORS.HEAD = "FFFFFF";
COLORS.HEADBACKGROUND = "00528C";
COLORS.HINTBACKGROUND = "E4E4E4";
COLORS.HINTBACKGROUNDC = "E0FFE0";
COLORS.HINTBACKGROUNDWARN = "C5DFC5";
COLORS.HINTLINE = "C4C4C4";
COLORS.INFOBACKGROUND = "CBEFFF";
COLORS.INFOLINE = "5680E4";
COLORS.LIGHTBACKGROUND = "CDDDFF";
COLORS.LOGINBACKGROUND = "D5D5FF";
COLORS.LOGINCOLOR = "000000";
COLORS.MODSTARTBOXBACKGROUND = "B0DFFF";
COLORS.MODSTARTBOXCOLOR = "2255CF";
COLORS.NAVI = "000090";
COLORS.NAVIBACKGROUND = "296D9E";
COLORS.NAVIHOVER = "EBFFFF";
COLORS.NAVISELECTED = "4080A0";
COLORS.REPLYBACKGROUND = "E4FFF4";
COLORS.REPLYCOLOR = "000000";
COLORS.SELECTORBACKGROUND = "D0E0F0";
COLORS.TOC = "000090";
COLORS.TOCB = "202070";
COLORS.TOCBACKGROUND = "7CA5C4";
COLORS.TOCBORDERCOLOR = "000090";
COLORS.TOCBSELECTED = "D02030";
COLORS.TOCFIRSTMENUBACKGROUND = "BFBFBF";
COLORS.TOCHOVER = "F2FFF2";
COLORS.TOCMENUBACKGROUND = "CFEFCF";
COLORS.TOCMENUBORDER = "404040";
COLORS.TOCMINBORDER = "2564AC";
COLORS.TOCMINBUTTON = "9EE3FF";
COLORS.TOCMINBUTTONCOLOR = "000090";
COLORS.TOCMINBUTTONHOVER = "B6F3FF";
COLORS.TOCMINCOLOR = "00528C";
COLORS.TOCNAVSYMBBACKGROUND = "14D2FF";
COLORS.TOCSELECTED = "4080A0";
COLORS.XSYMB = "C4EDFF";
COLORS.XSYMBCOLOR = "000090";
COLORS.XSYMBHOVER = "FAF4FF";
var FONTS = new Object();
FONTS.BASICFONTFAMILY = "open-sans";
FONTS.STDMATHFONTFAMILY = "'HelveticaNeue-Light', 'Helvetica Neue Light', 'Helvetica Neue', Helvetica, Arial, 'Lucida Grande', Verdana, Arial, Helvetica , sans-serif";
var SIZES = new Object();
SIZES.BASICFONTSIZE = 16;
SIZES.BIGFONTSIZE = 18;
SIZES.CONTENTMINWIDTH = 800;
SIZES.FOOTERHEIGHT = 20;
SIZES.HEADHEIGHT = 30;
SIZES.MENUWIDTH = 175;
SIZES.NAVIHEIGHT = 60;
SIZES.SMALLFONTSIZE = 14;
SIZES.STARTFONTSIZE = 16;
SIZES.TINYFONTSIZE = 12;
SIZES.TOCTOP = 90;
SIZES.TOCWIDTH = 154;
var DYNAMICCSS = ""
 + "body"
 + "{"
 + "  /* max-width: 1000px; */"
 + "  font-family: [-BASICFONTFAMILY-];"
 + "  font-size: [-BASICFONTSIZE-];"
 + "  padding: 0px;"
 + "  margin: 0px;"
 + "  height: 100%;  "
 + "}"
 + "input"
 + "{"
 + "  font-family: [-BASICFONTFAMILY-];"
 + "  font-size: [-BASICFONTSIZE-];"
 + "  height: 100%;  "
 + "}"
 + "button"
 + "{"
 + "  font-family: [-BASICFONTFAMILY-];"
 + "  font-size: [-BASICFONTSIZE-];"
 + "  height: 100%;  "
 + "}"
 + "td {"
 + "  font-size: [-BASICFONTSIZE-];"
 + "}"
 + "hr"
 + "{"
 + "  display: none;"
 + "}"
 + "#fixed,"
 + "#notfixed"
 + "{"
 + "  position: relative;"
 + "  width: 100%;"
 + "  /* max-width: 1000px; */"
 + "}"
 + "#fixed"
 + "{"
 + "  position: fixed;"
 + "  top: 0px;"
 + "  left: 0px;"
 + "  z-index: 1;"
 + "}"
 + "a"
 + "{"
 + "  font:  inherit;"
 + "  color: inherit;"
 + "  text-decoration: none;"
 + "}"
 + ".clear"
 + "{"
 + "  clear:    both;"
 + "  height:   0px;"
 + "  overflow: hidden;"
 + "}"
 + "#editor {"
 + "  position: relative;"
 + "  width: 600px;"
 + "  height: 400px;"
 + "}"
 + "/* Progress-Bar styling mit Browserweichen */"
 + "progress {  "
 + "  background-color: #F0F0F0;  "
 + "  border: 1;  "
 + "  height: 11px; "
 + "  width: 90%;"
 + "}  "
 + "/* Firefox */"
 + "progress::-moz-progress-bar {"
 + "        background-image: -moz-linear-gradient("
 + "                center bottom,"
 + "                rgb(43,194,123) 37%,"
 + "                rgb(84,240,124) 69%"
 + "        );"
 + "}"
 + " "
 + "/* Chrome */"
 + "progress::-webkit-progress-value {"
 + "        background-image: -webkit-gradient("
 + "                linear,"
 + "                left bottom,"
 + "                left top,"
 + "                color-stop(0, rgb(43,194,123)),"
 + "                color-stop(1, rgb(84,240,124))"
 + "        );"
 + "        background-image: -webkit-linear-gradient("
 + "                center bottom,"
 + "                rgb(43,194,123) 37%,"
 + "                rgb(84,240,124) 69%"
 + "        );"
 + "}"
 + " "
 + "/* Polyfill */"
 + "progress[aria-valuenow]:before {"
 + "        background-image: -moz-linear-gradient("
 + "                center bottom,"
 + "                rgb(43,194,123) 37%,"
 + "                rgb(84,240,124) 69%"
 + "        );"
 + "        background-image: -ms-linear-gradient("
 + "                center bottom,"
 + "                rgb(43,194,123) 37%,"
 + "                rgb(84,240,124) 69%"
 + "        );"
 + "        background-image: -o-linear-gradient("
 + "                center bottom,"
 + "                rgb(43,194,123) 37%,"
 + "                rgb(84,240,124) 69%"
 + "        );"
 + "}"
 + ".searchtable {"
 + "     font-size: [-SMALLFONTSIZE-];"
 + "    -webkit-column-count: 2; /* Chrome, Safari, Opera */"
 + "    -moz-column-count: 2; /* Firefox */"
 + "    column-count: 2;"
 + "}"
 + "button.groupbutton {"
 + "    background-color: rgb(120,120,170);"
 + "    color: white;"
 + "    font-family: \'open-sans-condensed\';"
 + "    font-weight: 700;"
 + "    display: inline-block;"
 + "    border: 2px solid rgb(210,210,210) !important;"
 + "    border-radius: 3px 3px 0px 0px;"
 + "    padding: 5px 10px !important;"
 + "    letter-spacing: 0.5px;"
 + "    margin: 0 !important;"
 + "}"
 + "button.hintbutton_closed:after {"
 + "	font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f107\" !important;"
 + "	width:30px !important;"
 + "	font-size: 16px !important;"
 + "	line-height: 20px !important;"
 + "	padding-left: 10px;"
 + "	margin: 0 !important;"
 + "}"
 + "button.hintbutton_open:after {"
 + "	font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f106\" !important;"
 + "	width:30px !important;"
 + "	font-size: 16px !important;"
 + "	line-height: 20px !important;"
 + "	padding-left: 10px;"
 + "	margin: 0 !important;"
 + "}"
 + "button.hintbutton_closed {"
 + "	color: rgb(210,210,210);"
 + "	background-color: rgb(160,170,180);"
 + "	font-family: \'open-sans-condensed\';"
 + "	font-weight: 700;"
 + "	display: inline-block;"
 + "	border: 2px solid rgb(210,210,210) !important;"
 + "	border-radius: 3px;"
 + "	padding: 5px 10px !important;"
 + "	text-transform: uppercase !important;"
 + "	letter-spacing: 0.5px;"
 + "	margin: 0 !important;"
 + "}"
 + "button.hintbutton_open {"
 + "	background-color: rgb(120,120,170);"
 + "	color: white;"
 + "	font-family: \'open-sans-condensed\';"
 + "	font-weight: 700;"
 + "	display: inline-block;"
 + "	border: 2px solid rgb(210,210,210) !important;"
 + "	border-radius: 3px 3px 0px 0px;"
 + "	padding: 5px 10px !important;"
 + "	text-transform: uppercase !important;"
 + "	letter-spacing: 0.5px;"
 + "	margin: 0 !important;"
 + "}"
 + "button.chintbutton_closed:after {"
 + "	font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f107\" !important;"
 + "	width:30px !important;"
 + "	font-size: 16px !important;"
 + "	line-height: 20px !important;"
 + "	padding-left: 10px;"
 + "	margin: 0 !important;"
 + "}"
 + "button.chintbutton_open:after {"
 + "	font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f106\" !important;"
 + "	width:30px !important;"
 + "	font-size: 16px !important;"
 + "	line-height: 20px !important;"
 + "	padding-left: 10px;"
 + "	margin: 0 !important;"
 + "}"
 + "button.chintbutton_closed {"
 + "	color: rgb(190,240,200);"
 + "	background-color: rgb(150,200,150);"
 + "	font-family: \'open-sans-condensed\';"
 + "	font-weight: 700;"
 + "	display: inline-block;"
 + "	border: 2px solid rgb(190,240,200) !important;"
 + "	border-radius: 3px;"
 + "	padding: 5px 10px !important;"
 + "	text-transform: uppercase !important;"
 + "	letter-spacing: 0.5px;"
 + "	margin: 0 !important;"
 + "}"
 + "button.chintbutton_open {"
 + "	background-color: rgb(120,190,120);"
 + "	color: white;"
 + "	font-family: \'open-sans-condensed\';"
 + "	font-weight: 700;"
 + "	display: inline-block;"
 + "	border: 2px solid rgb(210,210,210) !important;"
 + "	border-radius: 3px 3px 0px 0px;"
 + "	padding: 5px 10px !important;"
 + "	text-transform: uppercase !important;"
 + "	letter-spacing: 0.5px;"
 + "	margin: 0 !important;"
 + "}"
 + "/* fontAwesome fonts */"
 + "@font-face {"
 + "  font-family: \'FontAwesome\';"
 + "  src: url(\'[LINKPATH]fonts/fontawesome/fontawesome-webfont.eot\');"
 + "  src: url(\'[LINKPATH]fonts/fontawesome/fontawesome-webfont.eot\') format(\'embedded-opentype\'),"
 + "       url(\'[LINKPATH]fonts/fontawesome/fontawesome-webfont.woff2\') format(\'woff2\'),"
 + "       url(\'[LINKPATH]fonts/fontawesome/fontawesome-webfont.woff\') format(\'woff\'),"
 + "       url(\'[LINKPATH]fonts/fontawesome/fontawesome-webfont.ttf\') format(\'truetype\'),"
 + "       url(\'[LINKPATH]fonts/fontawesome/fontawesome-webfont.svg\') format(\'svg\');"
 + "  font-weight: normal;"
 + "  font-style: normal;"
 + "}"
 + "/* open-sans font faces */"
 + "@font-face {"
 + "  font-family: open-sans;"
 + "  src: url(\"[LINKPATH]fonts/open-sans/light.eot\");"
 + "  src: url(\"[LINKPATH]fonts/open-sans/light.eot?#iefix\") format(\"embedded-opentype\"), url(\"[LINKPATH]fonts/open-sans/light.woff\") format(\"woff\"), url(\"[LINKPATH]fonts/open-sans/light.ttf\") format(\"truetype\"), url(\"[LINKPATH]fonts/open-sans/light.svg#open-sans\") format(\"svg\");"
 + "  font-weight: 200;"
 + "  font-style: normal; }"
 + "@font-face {"
 + "  font-family: open-sans;"
 + "  src: url(\"[LINKPATH]fonts/open-sans/light-italic.eot\");"
 + "  src: url(\"[LINKPATH]fonts/open-sans/light-italic.eot?#iefix\") format(\"embedded-opentype\"), url(\"[LINKPATH]fonts/open-sans/light-italic.woff\") format(\"woff\"), url(\"[LINKPATH]fonts/open-sans/light-italic.ttf\") format(\"truetype\"), url(\"[LINKPATH]fonts/open-sans/light-italic.svg#open-sans\") format(\"svg\");"
 + "  font-weight: 200;"
 + "  font-style: italic; }"
 + "@font-face {"
 + "  font-family: open-sans;"
 + "  src: url(\"[LINKPATH]fonts/open-sans/regular.eot\");"
 + "  src: url(\"[LINKPATH]fonts/open-sans/regular.eot?#iefix\") format(\"embedded-opentype\"), url(\"[LINKPATH]fonts/open-sans/regular.woff\") format(\"woff\"), url(\"[LINKPATH]fonts/open-sans/regular.ttf\") format(\"truetype\"), url(\"[LINKPATH]fonts/open-sans/regular.svg#open-sans\") format(\"svg\");"
 + "  font-weight: normal;"
 + "  font-style: normal; }"
 + "@font-face {"
 + "  font-family: open-sans;"
 + "  src: url(\"[LINKPATH]fonts/open-sans/regular.eot\");"
 + "  src: url(\"[LINKPATH]fonts/open-sans/regular.eot?#iefix\") format(\"embedded-opentype\"), url(\"[LINKPATH]fonts/open-sans/regular.woff\") format(\"woff\"), url(\"[LINKPATH]fonts/open-sans/regular.ttf\") format(\"truetype\"), url(\"[LINKPATH]fonts/open-sans/regular.svg#open-sans\") format(\"svg\");"
 + "  font-weight: normal;"
 + "  font-style: italic; }"
 + "@font-face {"
 + "  font-family: open-sans;"
 + "  src: url(\"[LINKPATH]fonts/open-sans/semibold.eot\");"
 + "  src: url(\"[LINKPATH]fonts/open-sans/semibold.eot?#iefix\") format(\"embedded-opentype\"), url(\"[LINKPATH]fonts/open-sans/semibold.woff\") format(\"woff\"), url(\"[LINKPATH]fonts/open-sans/semibold.ttf\") format(\"truetype\"), url(\"[LINKPATH]fonts/open-sans/semibold.svg#open-sans\") format(\"svg\");"
 + "  font-weight: 600;"
 + "  font-style: normal; }"
 + "@font-face {"
 + "  font-family: open-sans;"
 + "  src: url(\"[LINKPATH]fonts/open-sans/semibold-italic.eot\");"
 + "  src: url(\"[LINKPATH]fonts/open-sans/semibold-italic.eot?#iefix\") format(\"embedded-opentype\"), url(\"[LINKPATH]fonts/open-sans/semibold-italic.woff\") format(\"woff\"), url(\"[LINKPATH]fonts/open-sans/semibold-italic.ttf\") format(\"truetype\"), url(\"[LINKPATH]fonts/open-sans/semibold-italic.svg#open-sans\") format(\"svg\");"
 + "  font-weight: 600;"
 + "  font-style: italic; }"
 + "@font-face {"
 + "  font-family: open-sans;"
 + "  src: url(\"[LINKPATH]fonts/open-sans/bold.eot\");"
 + "  src: url(\"[LINKPATH]fonts/open-sans/bold.eot?#iefix\") format(\"embedded-opentype\"), url(\"[LINKPATH]fonts/open-sans/bold.woff\") format(\"woff\"), url(\"[LINKPATH]fonts/open-sans/bold.ttf\") format(\"truetype\"), url(\"[LINKPATH]fonts/open-sans/bold.svg#open-sans\") format(\"svg\");"
 + "  font-weight: bold;"
 + "  font-style: normal; }"
 + "@font-face {"
 + "  font-family: open-sans;"
 + "  src: url(\"[LINKPATH]fonts/open-sans/bold-italic.eot\");"
 + "  src: url(\"[LINKPATH]fonts/open-sans/bold-italic.eot?#iefix\") format(\"embedded-opentype\"), url(\"[LINKPATH]fonts/open-sans/bold-italic.woff\") format(\"woff\"), url(\"[LINKPATH]fonts/open-sans/bold-italic.ttf\") format(\"truetype\"), url(\"[LINKPATH]fonts/open-sans/bold-italic.svg#open-sans\") format(\"svg\");"
 + "  font-weight: bold;"
 + "  font-style: italic; }"
 + "@font-face {"
 + "  font-family: open-sans;"
 + "  src: url(\"[LINKPATH]fonts/open-sans/extrabold.eot\");"
 + "  src: url(\"[LINKPATH]fonts/open-sans/extrabold.eot?#iefix\") format(\"embedded-opentype\"), url(\"[LINKPATH]fonts/open-sans/extrabold.woff\") format(\"woff\"), url(\"[LINKPATH]fonts/open-sans/extrabold.ttf\") format(\"truetype\"), url(\"[LINKPATH]fonts/open-sans/extrabold.svg#open-sans\") format(\"svg\");"
 + "  font-weight: 800;"
 + "  font-style: normal; }"
 + "@font-face {"
 + "  font-family: open-sans;"
 + "  src: url(\"[LINKPATH]fonts/open-sans/extrabold-italic.eot\");"
 + "  src: url(\"[LINKPATH]fonts/open-sans/extrabold-italic.eot?#iefix\") format(\"embedded-opentype\"), url(\"[LINKPATH]fonts/open-sans/extrabold-italic.woff\") format(\"woff\"), url(\"[LINKPATH]fonts/open-sans/extrabold-italic.ttf\") format(\"truetype\"), url(\"[LINKPATH]fonts/open-sans/extrabold-italic.svg#open-sans\") format(\"svg\");"
 + "  font-weight: 800;"
 + "  font-style: italic; }"
 + "@font-face {"
 + "  font-family: open-sans-condensed;"
 + "  src: url(\"[LINKPATH]fonts/open-sans-condensed/light.eot\");"
 + "  src: url(\"[LINKPATH]fonts/open-sans-condensed/light.eot?#iefix\") format(\"embedded-opentype\"), url(\"[LINKPATH]fonts/open-sans-condensed/light.woff\") format(\"woff\"), url(\"[LINKPATH]fonts/open-sans-condensed/light.ttf\") format(\"truetype\"), url(\"[LINKPATH]fonts/open-sans-condensed/light.svg#open-sans-condensed\") format(\"svg\");"
 + "  font-weight: 200;"
 + "  font-style: normal; }"
 + "@font-face {"
 + "  font-family: open-sans-condensed;"
 + "  src: url(\"[LINKPATH]fonts/open-sans-condensed/light-italic.eot\");"
 + "  src: url(\"[LINKPATH]fonts/open-sans-condensed/light-italic.eot?#iefix\") format(\"embedded-opentype\"), url(\"[LINKPATH]fonts/open-sans-condensed/light-italic.woff\") format(\"woff\"), url(\"[LINKPATH]fonts/open-sans-condensed/light-italic.ttf\") format(\"truetype\"), url(\"[LINKPATH]fonts/open-sans-condensed/light-italic.svg#open-sans-condensed\") format(\"svg\");"
 + "  font-weight: 200;"
 + "  font-style: italic; }"
 + "@font-face {"
 + "  font-family: open-sans-condensed;"
 + "  src: url(\"[LINKPATH]fonts/open-sans-condensed/bold.eot\");"
 + "  src: url(\"[LINKPATH]fonts/open-sans-condensed/bold.eot?#iefix\") format(\"embedded-opentype\"), url(\"[LINKPATH]fonts/open-sans-condensed/bold.woff\") format(\"woff\"), url(\"[LINKPATH]fonts/open-sans-condensed/bold.ttf\") format(\"truetype\"), url(\"[LINKPATH]fonts/open-sans-condensed/bold.svg#open-sans-condensed\") format(\"svg\");"
 + "  font-weight: bold;"
 + "  font-style: normal; }"
 + "/* --------------------------- Uebernahme vom alten Design --------------------------- */"
 + ".toc ul"
 + "{"
 + "  margin:  0px;"
 + "  padding: 0px;"
 + "}"
 + ".toc ul.level1a"
 + "{"
 + "  margin-top:       10px;"
 + "  padding-left:     5px;"
 + "  list-style-type:  none;"
 + "  font-weight:      bold;"
 + "  font-size:        [-SMALLFONTSIZE-];"
 + "  line-height:      20px;"
 + "}"
 + ".toc ul.level1b"
 + "{"
 + "  margin-top:       10px;"
 + "  padding-left:     5px;"
 + "  list-style-type:  none;"
 + "  font-weight:      bold;"
 + "  font-size:        [-SMALLFONTSIZE-];"
 + "  line-height:      25px;"
 + "}"
 + ".toc ul.level2"
 + "{"
 + "  margin-bottom:    10px;"
 + "  padding-left:     10px;"
 + "  list-style-type:  none;"
 + "  font-weight:      normal;"
 + "  font-size:        [-SMALLFONTSIZE-];"
 + "  line-height:      13px;"
 + "}"
 + ".toc ul.level3"
 + "{"
 + "  margin-bottom:    5px;"
 + "  margin-left: 1em;"
 + "  padding-top:      0px;"
 + "  padding-left:     15px;"
 + "  list-style-type:  disc;"
 + "  font-weight:      normal;"
 + "  font-size:        11px;"
 + "}"
 + ".toc li.selected"
 + "{"
 + "  font-weight:      bold;"
 + "  color: [-TOCSELECTED-];"
 + "}"
 + ".toc li.notselected"
 + "{"
 + "  font-weight:      normal;"
 + "  color: [-TOC-];"
 + "}"
 + ".toc li.bselected"
 + "{"
 + "  font-weight:      normal;"
 + "  color: [-TOCBSELECTED-];"
 + "}"
 + ".toc li.bnotselected"
 + "{"
 + "  font-weight:      normal;"
 + "  color: [-TOCB-];"
 + "}"
 + "tocnavsymb ul {"
 + "    margin: 0;"
 + "    padding: 0;"
 + "    list-style-type: disc;"
 + "}"
 + "tocnavsymb ul li {"
 + "      display: inline-block;"
 + "      list-style-type: none;"
 + "      color: #000000;"
 + "      width: 100%; "
 + "  "
 + "  "
 + "  "
 + "      -webkit-transition: all 0.2s;"
 + "        -moz-transition: all 0.2s;"
 + "        -ms-transition: all 0.2s;"
 + "        -o-transition: all 0.2s;"
 + "        transition: all 0.2s; "
 + "}"
 + ".head"
 + "{"
 + "  background-color: [-HEADBACKGROUND-];"
 + "  color: [-HEAD-];"
 + "  width: 100%;"
 + "  padding: 0px /* 0.2em 0px; */"
 + "  border-bottom: 1px solid black;"
 + "  border-top: 1px solid black;"
 + "}"
 + ".navi"
 + "{"
 + "  margin: 0px;"
 + "  color: [-XSYMBCOLOR-];"
 + "  background-color: [-NAVIBACKGROUND-];"
 + "  margin-left: [-MENUWIDTH-];"
 + "  border-bottom: 1px solid [-GENERALBORDER-];"
 + "}"
 + ".navi ul"
 + "{"
 + "  margin: 0px;"
 + "  padding: 0px;"
 + "  list-style-type:  none;"
 + "  text-align: center;  "
 + "}"
 + ".navi ul li,"
 + ".stdbutton,"
 + ".testsbutton,"
 + ".roulettebutton,"
 + ".nprev,"
 + ".nnext,"
 + "{"
 + "  background-color: [-TOCMINBUTTON-];"
 + "  display: inline-block;"
 + "  background-repeat: no-repeat;"
 + "  background-position: center top;"
 + "  margin: 0px;"
 + "  min-width: 35px;"
 + "  padding-top: 35px;"
 + "  padding-left: 12px;"
 + "  padding-right: 10px;"
 + "  border: 1px solid [-TOCMENUBORDER-];"
 + "  color: [-XSYMBCOLOR-];"
 + "}"
 + ".nprev {"
 + "  float: left;"
 + "}"
 + ".nnext {"
 + "  float: right;"
 + "}"
 + ".navi a"
 + "{"
 + "  padding-top: 35px;"
 + "}"
 + "#footer"
 + "{"
 + "  position: fixed;"
 + "  bottom: 0px;"
 + "  text-align: center;"
 + "  width: 100%;"
 + "  font-size: [-BIGFONTSIZE-];"
 + "  color: [-FOOT-];"
 + "  background-color: [-FOOTBACKGROUND-];"
 + "  padding: 0.2em 0px;"
 + "}"
 + "/* ------------------------- neues Design ------------------------------ */"
 + "/* align all img images in the center */"
 + "img {"
 + "    horizontal-align: middle;"
 + "    vertical-align: middle;"
 + "    margin-bottom: .25em;"
 + "}"
 + "/* Normaler xsection button */"
 + ".xsectbutton {"
 + "    padding: 0 !important;"
 + "    background-image: none !important;"
 + "}"
 + ".head, .headmiddle {"
 + "    padding: 0 !important;"
 + "    border: 0 !important;   "
 + "    font-family: \'open-sans-condensed\' !important;"
 + "    font-weight: 700 !important;"
 + "    min-height:[-HEADHEIGHT-] !important;"
 + "}"
 + ".headmiddle {"
 + "    display: flex;"
 + "}"
 + "#minusbutton img,"
 + "#plusbutton img,"
 + "#sharebutton img,"
 + "#starbutton img,"
 + "#menubutton img,"
 + ".headmiddle a:nth-child(4) div,"
 + ".headmiddle a:nth-child(5) div"
 + " {"
 + "	display: none !important;"
 + "}"
 + ".head .symbolbutton {"
 + "    background-color: transparent !important;"
 + "    border: 0 !important;"
 + "    color: white !important;"
 + "}"
 + ".head .symbolbutton:hover,"
 + "#listebutton:hover, #homebutton:hover {"
 + "    color: rgba(255,255,255,.5) !important;"
 + "}"
 + "#minusbutton:before {"
 + "	font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f068\" !important;"
 + "	width: [-HEADHEIGHT-] !important;"
 + "	height: [-HEADHEIGHT-] !important;"
 + "	font-size: [-SMALLFONTSIZE-] !important;"
 + "	line-height: [-HEADHEIGHT-] !important;"
 + "}"
 + "#plusbutton:before {"
 + "	font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f067\" !important;"
 + "	width: [-HEADHEIGHT-] !important;"
 + "	height: [-HEADHEIGHT-] !important;"
 + "	font-size: [-SMALLFONTSIZE-] !important;"
 + "	line-height: [-HEADHEIGHT-] !important;"
 + "}"
 + "#sharebutton:before {"
 + "	font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f1e0\" !important;"
 + "	width: [-HEADHEIGHT-] !important;"
 + "	height: [-HEADHEIGHT-] !important;"
 + "	font-size: [-SMALLFONTSIZE-] !important;"
 + "	line-height: [-HEADHEIGHT-] !important;"
 + "}"
 + "#starbutton:before {"
 + "	font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f005\" !important;"
 + "	width: [-HEADHEIGHT-] !important;"
 + "	height: [-HEADHEIGHT-] !important;"
 + "	font-size: [-SMALLFONTSIZE-] !important;"
 + "	line-height: [-HEADHEIGHT-] !important;"
 + "}"
 + "#menubutton:before {"
 + "	font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f0c9\" !important;"
 + "	width: [-HEADHEIGHT-] !important;"
 + "	height: [-HEADHEIGHT-] !important;"
 + "	font-size: [-SMALLFONTSIZE-] !important;"
 + "	line-height: [-HEADHEIGHT-] !important;"
 + "}"
 + "#settingsbutton:before {"
 + "	font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f013\" !important;"
 + "	width: [-HEADHEIGHT-] !important;"
 + "	height: [-HEADHEIGHT-] !important;"
 + "	font-size: [-SMALLFONTSIZE-] !important;"
 + "	line-height: [-HEADHEIGHT-] !important;"
 + "}"
 + "#listebutton:before {"
 + "	font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f03a\" !important;"
 + "	font-weight: 400;"
 + "	width: [-HEADHEIGHT-] !important;"
 + "	height: [-HEADHEIGHT-] !important;"
 + "	font-size: [-SMALLFONTSIZE-] !important;"
 + "	line-height: [-HEADHEIGHT-] !important;"
 + "	display: inline-block;"
 + "	text-align: center;"
 + "}"
 + "#homebutton:before {"
 + "	font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f015\" !important;"
 + "	font-weight: 400;"
 + "	width: [-HEADHEIGHT-] !important;"
 + "	height: [-HEADHEIGHT-] !important;"
 + "	font-size: [-SMALLFONTSIZE-] !important;"
 + "	line-height: [-HEADHEIGHT-] !important;"
 + "	display: inline-block;"
 + "	text-align: center;"
 + "}"
 + "#LOGINROW {"
 + "        display: inline-block;"
 + "        flex-grow:100;"
 + "        text-align:center"
 + "        /* color und content wird dynamisch gesetzt */"
 + "}"
 + "#loginbutton, #cdatabutton, #LOGINROW {"
 + "	text-transform: uppercase;"
 + "	padding: 2px 0px 2px 10px !important;"
 + "	font-size: [-SMALLFONTSIZE-] !important;"
 + "	letter-spacing: 0.5px !important;"
 + "	line-height: 26px;"
 + "}"
 + "#loginbutton:hover, #cdatabutton:hover {"
 + "	color: rgba(255,255,255,.5) !important;"
 + "}"
 + "/* navi */ "
 + ".navi {"
 + "	font-family: \'open-sans-condensed\' !important;"
 + "	font-weight: 700 !important;"
 + "    border-bottom: 0px !important;"
 + "    margin-left: 0px !important;"
 + "    min-height: [-NAVIHEIGHT-] !important;"
 + "    padding: 10px 0 !important;"
 + "    box-sizing: border-box;"
 + "}"
 + ".navi ul {"
 + "    padding: 0 [-HEADHEIGHT-] !important;"
 + "}"
 + ".navi ul li {"
 + "    background-color: transparent !important;"
 + "    display: inline-block;"
 + "    background-repeat: no-repeat;"
 + "    background-position: center top;"
 + "    border: 0 !important;"
 + "    margin: 0px;"
 + "    min-width: 35px;"
 + "    padding-top: 35px;"
 + "    padding-left: 12px;"
 + "    padding-right: 10px;"
 + "    border: 2px solid white;"
 + "    border-radius: 3px;"
 + "    color: #000090;"
 + "}"
 + ".navi ul li a {"
 + "    color: rgb(200,200,200) !important;"
 + "    display: inline-block;"
 + "    border: 2px solid rgba(255,255,255,0.5) !important;"
 + "    border-radius: 3px;"
 + "    padding: 5px 10px  !important;"
 + "    text-transform: uppercase !important;"
 + "    letter-spacing: 0.5px;"
 + "    margin: 0px 10px;"
 + "}"
 + ".navi ul li a:hover {"
 + "    background-color:rgba(255,255,255,.5) !important;"
 + "}"
 + ".navi ul li a.naviselected {"
 + "    color: white !important;"
 + "}"
 + ".navi .nprev a, .navi .nprev a:before {"
 + "    background-image: none !important;"
 + "    font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f104\";"
 + "	color: white !important;"
 + "	width:60px !important;"
 + "	height:40px !important;"
 + "	line-height: 40px !important;"
 + "	font-size: 40px;"
 + "	font-weight: 400;"
 + "}"
 + ".navi .nnext a, .navi .nnext a:before {"
 + "    background-image: none !important;"
 + "    font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f105\";"
 + "	color: white !important;	"
 + "	width:60px !important;"
 + "	height:40px !important;"
 + "	line-height: 40px !important;"
 + "	font-size: 40px;"
 + "	font-weight: 400;"
 + "}"
 + ".navi .nprev:hover a,"
 + ".navi .nnext:hover a {"
 + "	color:rgba(255,255,255,.5) !important;"
 + "}"
 + ".navi .nprev, .navi.nnext {"
 + "    background-color: transparent !important;"
 + "    border: 0 !important;"
 + "    background-image: none !important;"
 + "    padding: 0 10px !important;"
 + "}"
 + "/* toc */ "
 + "/* toc with 15px padding to accomodate a vertical scrollbar, 15px are included in MENUWIDTH */"
 + ".toc {"
 + "    overflow-x: hidden;"
 + "    overflow-y: auto;"
 + "    padding: 0 !important;"
 + "    padding-right: 15px;"
 + "    margin-top: 0px !important;"
 + "    bottom: [-FOOTERHEIGHT-];"
 + "    top: [-TOCTOP-]  !important;"
 + "    font-family: \'open-sans-condensed\' !important;"
 + "    font-weight: 700 !important;"
 + "    border-right: 0 !important;"
 + "    width:[-MENUWIDTH-] !important;"
 + "    box-sizing: border-box !important;"
 + "    position: fixed !important;"
 + "    background-color: [-TOCBACKGROUND-] !important;"
 + "}"
 + "tocnavsymb {"
 + "    background-color: transparent !important;"
 + "    border: 0 !important;"
 + "    box-shadow: 0 !important;"
 + "    color: [-TOCBORDERCOLOR-];"
 + "    margin: 0 !important;"
 + "	font-family: \'open-sans-condensed\' !important;"
 + "    font-size: [-BASICFONTSIZE-];"
 + "    box-sizing: border-box !important;"
 + "}"
 + ".tocmintitle {"
 + "    background-color: transparent !important;"
 + "    color: [-TOCMINCOLOR-] !important;"
 + "    padding: 20px 10px !important;"
 + "    border: 0 !important;"
 + "    font-family: \'open-sans-condensed\' !important;"
 + "    font-size: [-BIGFONTSIZE-];"
 + "    text-transform: uppercase;"
 + "    letter-spacing: 0.5px;"
 + "    border-bottom: 1px solid [-TOCMINCOLOR-] !important;"
 + "    box-sizing: border-box !important;"
 + "}"
 + "tocnavsymb ul li ul li {"
 + "    border-bottom: 1px solid [-TOCMINCOLOR-] !important;"
 + "    padding: 3px 10px !important;"
 + "    box-sizing: border-box !important;"
 + "}"
 + "tocnavsymb ul li ul li ul li {"
 + "    border-bottom: 0 !important;"
 + "    padding: 3px 10px !important;"
 + "    box-sizing: border-box !important;"
 + "}"
 + "tocnavsymb ul li ul li.aktiv  {"
 + "    background-color: [-TOCMINCOLOR-] !important;"
 + "    padding: 3px 0px !important;"
 + "    box-sizing: border-box !important;"
 + "}"
 + "tocnavsymb ul li ul li.aktiv ul li {"
 + "    border-bottom: 0 !important;"
 + "    padding: 3px 10px !important;"
 + "    box-sizing: border-box !important;"
 + "}"
 + "tocnavsymb ul li ul li.aktiv a .tocminbutton {"
 + "	padding: 3px 10px !important;"
 + "}"
 + "tocnavsymb ul li ul li.aktiv a:hover .tocminbutton {"
 + "	color:rgba(255,255,255,0.5) !important;"
 + "}"
 + "tocnavsymb ul li ul li a:hover div{"
 + "    color: [-TOCMINCOLOR-] !important;"
 + "    box-sizing: border-box !important;"
 + "}"
 + ".xsymb {"
 + "    color: white !important;"
 + "    background-color: [-XSYMB-];"
 + "    display: inline-block;"
 + "    border:0 !important;"
 + "    background-color: transparent !important;"
 + "    padding: 0px 2px 0px 0px !important;"
 + "    font-weight: 300 !important;"
 + "    font-size: [-SMALLFONTSIZE-];"
 + "}"
 + ".xsymb:hover {"
 + "	color: rgba(255,255,255,0.5) !important;"
 + "}"
 + ".xsymb.status3:before {"
 + "	font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f15b\" !important;"
 + "	width:auto !important;"
 + "	height: [-SMALLFONTSIZE-] !important;"
 + "	font-size: [-SMALLFONTSIZE-] !important;"
 + "	line-height: [-SMALLFONTSIZE-] !important;"
 + "}"
 + ".xsymb.status2:before {"
 + "	font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f0f6\" !important;"
 + "	width:auto !important;"
 + "	height: [-SMALLFONTSIZE-] !important;"
 + "	font-size: [-SMALLFONTSIZE-] !important;"
 + "	line-height: [-SMALLFONTSIZE-] !important;"
 + "}"
 + ".xsymb.status1:before {"
 + "	font-family: \'FontAwesome\' !important;"
 + "	content: \"\\f016\" !important;"
 + "	width:auto !important;"
 + "	height: [-SMALLFONTSIZE-] !important;"
 + "	font-size: [-SMALLFONTSIZE-] !important;"
 + "	line-height: [-SMALLFONTSIZE-] !important;"
 + "}"
 + ".xsymb.state_problem {"
 + "    color: rgba(255,20,20,0.3) !important;"
 + "}"
 + ".xsymb.state_progress {"
 + "    color: rgba(255,255,20,0.3) !important;"
 + "}"
 + ".xsymb.state_done {"
 + "    color: rgba(20,255,20,0.3) !important;"
 + "}"
 + ".xsymb.selected {"
 + "    font-weight: 700 !important;"
 + "}"
 + ".xsymb.status3 tt,"
 + ".xsymb.status2 tt,"
 + ".xsymb.status1 tt {"
 + "   display: none;"
 + "}"
 + "/* footer */ "
 + "#footer {"
 + "    font-family: \'open-sans-condensed\' !important;"
 + "    font-weight: 700 !important;"
 + "    padding: 0px !important;"
 + "    color: white !important;"
 + "    height: [-FOOTERHEIGHT-] !important;"
 + "    text-transform: uppercase !important;"
 + "    max-width: auto !important;"
 + "    font-size: [-TINYFONTSIZE-] !important;"
 + "    line-height: [-FOOTERHEIGHT-] !important;"
 + "    letter-spacing: 0.5px;"
 + "    position: fixed;"
 + "    display: flex;"
 + "}"
 + ".footermiddle {"
 + "        display: inline-block;"
 + "        flex-grow:100;"
 + "        text-align:center"
 + "}"
 + ".footerleft, .footerright {"
 + "    display: inline-block;"
 + "    width: 150px;"
 + "    text-align:center"
 + "}"
 + "#footerleft .tocminbutton, #footerright .tocminbutton {"
 + "    font-size: [-TINYFONTSIZE-] !important;"
 + "    line-height: [-FOOTERHEIGHT-] !important;"
 + "    letter-spacing: 0.5px;"
 + "    color: white !important;"
 + "    font-family: \'open-sans-condensed\' !important;"
 + "}"
 + "#footerleft a:hover .tocminbutton, #footerright a:hover .tocminbutton  {"
 + "    color: rgba(255,255,255,0.5) !important;"
 + "}"
 + "/* qtip */"
 + ".qtip-default {"
 + "    font-family: \'open-sans\' !important;"
 + "    font-weight: 700;"
 + "    font-size: [-SMALLFONTSIZE-];"
 + "    border-width: 1px !important;"
 + "    border-style: solid;"
 + "    border-color: [-TOCMINCOLOR-] !important;"
 + "    background-color: [-LIGHTBACKGROUND-] !important;"
 + "    color: [-TOCMINCOLOR-];"
 + "    box-shadow: 2px 2px 5px rgba(0,0,0,0.7);"
 + "}"
 + "/* allgemein */"
 + ".tocminbutton {"
 + "    background-color: transparent !important;"
 + "    padding: 0 !important;"
 + "    border: 0 !important;"
 + "    font-family: \'open-sans-condensed\' !important;"
 + "    font-size: [-BIGFONTSIZE-];"
 + "}"
 + "a .tocminbutton {"
 + "    color: white !important;"
 + "}"
 + "#settings {"
 + "    /* Element is hidden until toggled by mintscripts.js */"
 + "    position: absolute;"
 + "    top: 0;"
 + "    left: 0;"
 + "    width: 0;"
 + "    height: 0;"
 + "    overflow-x: auto;"
 + "    overflow-y: auto;"
 + "    visibility: hidden;"
 + "    padding: 10px;"
 + "    position: fixed;"
 + "    background-color: [-NAVIBACKGROUND-];"
 + "    border-style: solid;"
 + "    box-shadow: 2px 2px 5px rgba(0,0,0,0.7);"
 + "    border-color: rgb(0,82,140) !important;"
 + "    border-radius: 5px !important;"
 + "    font-family: \'open-sans-condensed\';"
 + "    font-weight: 700;"
 + "    color: white;"
 + "    display: block;"
 + "    min-width: 500px;"
 + "}"
 + ".stdbutton {"
 + "    color: white !important;"
 + "    background-color: rgba(255,255,255,0) !important;"
 + "    border: 2px solid rgba(255,255,255,0.5) !important;"
 + "    border-radius: 3px;"
 + "    padding: 5px 10px  !important;"
 + "    text-transform: uppercase !important;"
 + "    letter-spacing: 0.5px;"
 + "    margin: 0px 10px;"
 + "    font-family: \'open-sans-condensed\';"
 + "    font-weight: 700;"
 + "}"
 + ".stdbutton:hover {"
 + "    background-color:rgba(255,255,255,.5) !important;"
 + "}"
 + ".testsbutton {"
 + "    color: white !important;"
 + "    background-color: rgb(155, 125, 50) !important;"
 + "    border: 2px solid rgb(100, 100, 32) !important;"
 + "    border-radius: 3px;"
 + "    padding: 5px 10px  !important;"
 + "    text-transform: uppercase !important;"
 + "    letter-spacing: 0.5px;"
 + "    margin: 0px 10px;"
 + "    font-family: \'open-sans-condensed\';"
 + "    font-weight: 700;"
 + "}"
 + ".testsbutton:hover {"
 + "    background-color: rgb(195, 195, 80) !important;"
 + "}"
 + ".roulettebutton {"
 + "    color: grey !important;"
 + "    background-color: rgba(215,235,255,0) !important;"
 + "    display: inline-block;"
 + "    border: 2px solid rgba(155,200,210,0.5) !important;"
 + "    border-radius: 3px;"
 + "    padding: 5px 10px  !important;"
 + "    text-transform: uppercase !important;"
 + "    letter-spacing: 0.5px;"
 + "    margin: 0px 10px;"
 + "    font-family: \'open-sans-condensed\';"
 + "    font-weight: 700;"
 + "}"
 + ".roulettebutton:hover {"
 + "    background-color:rgba(215,235,255,.5) !important;"
 + "}"
 + "ul.legende {"
 + "    display: block;"
 + "    width:100%;"
 + "    margin-top: [-FOOTERHEIGHT-] !important;"
 + "    padding: 10px !important;"
 + "    font-size: smaller;"
 + "}"
 + "ul.legende li {"
 + "    color: [-TOCMINCOLOR-];"
 + "    font-weight: 300;"
 + "}"
 + "ul.legende li:first-child {"
 + "    color: [-TOCMINCOLOR-];"
 + "    font-weight: 700;"
 + "    text-transform: uppercase;"
 + "}"
 + "ul.legende li .xsymb {"
 + "    min-width: [-TINYFONTSIZE-];"
 + "    color: [-TOCMINCOLOR-] !important;"
 + "}"
 + ".modstartbox {"
 + "    padding: 5px;"
 + "    background-color: [-MODSTARTBOXBACKGROUND-];"
 + "    color: [-MODSTARTBOXCOLOR-];"
 + "    border: 0 !important;"
 + "    border-radius: 3px !important;"
 + "}"
 + "#content"
 + "{"
 + "  margin-left: [-MENUWIDTH-];"
 + "  padding: 10px;"
 + "  padding-bottom: 20px;"
 + "  z-index: 10;"
 + "  bottom: [-FOOTERHEIGHT-];"
 + "  color: [-CONTENT-];"
 + "  background-color: [-CONTENTBACKGROUND-];"
 + "  min-width: [-CONTENTMINWIDTH-];"
 + "}"
 + "#start"
 + "{"
 + "  margin-left: [-MENUWIDTH-];"
 + "  padding: 10px;"
 + "  z-index: 10;"
 + "  bottom: [-FOOTERHEIGHT-];"
 + "  color: [-CONTENT-];"
 + "  background-color: [-CONTENTBACKGROUND-];"
 + "}"
 + "#content h1,"
 + "#content h2,"
 + "#content h3,"
 + "#content h4,"
 + "#content h5,"
 + "#content h6"
 + "{"
 + "  text-align: center;"
 + "}"
 + "#start h1,"
 + "#start h2,"
 + "#start h3,"
 + "#start h4,"
 + "#start h5,"
 + "#start h6"
 + "{"
 + "  text-align: left;"
 + "}"
 + "#content a,"
 + "#start a"
 + "{"
 + "  color: [-CONTENTANCHOR-];"
 + "}"
 + "#start a {"
 + "  text-decoration: underline;"
 + "}"
 + "#content a:hover"
 + "#start a:hover"
 + "{"
 + "  text-decoration: underline;"
 + "}"
 + "/*"
 + " Spezielle td-Klassen fuer wtabular:"
 + " Coding im split.pm_"
 + "         A -> keine Raender"
 + "         B -> Rand nur links"
 + "         C -> Rand nur rechts"
 + "         D -> Rand an beiden Seiten"
 + "*/"
 + "table.wtabular {"
 + "border-collapse: collapse;"
 + "table-layout: auto;"
 + "}"
 + "td.wtabular_A {"
 + "/* border : 1px solid; */"
 + "padding : 1px;"
 + "}"
 + "td.wtabular_B {"
 + "border: solid 0 [-CONTENT-];"
 + "border-left-width:1px;"
 + "padding-left:0.5ex;"
 + "}"
 + "td.wtabular_C {"
 + "border: solid 0 [-CONTENT-];"
 + "border-right-width:1px;"
 + "padding-right:0.5ex;"
 + "}"
 + "td.wtabular_D {"
 + "border: solid 0 [-CONTENT-];"
 + "border-right-width:1px;"
 + "padding-right:0.5ex;"
 + "border-left-width:1px;"
 + "padding-left:0.5ex;"
 + "}"
 + "td.wtabular_AU {"
 + "border: solid 0 [-CONTENT-];"
 + "border-bottom-width:1px;"
 + "padding-bottom:0.5ex;"
 + "}"
 + "td.wtabular_BU {"
 + "border: solid 0 [-CONTENT-];"
 + "border-left-width:1px;"
 + "padding-left:0.5ex;"
 + "border-bottom-width:1px;"
 + "padding-bottom:0.5ex;"
 + "}"
 + "td.wtabular_CU {"
 + "border: solid 0 [-CONTENT-];"
 + "border-right-width:1px;"
 + "padding-right:0.5ex;"
 + "border-bottom-width:1px;"
 + "padding-bottom:0.5ex;"
 + "}"
 + "td.wtabular_DU {"
 + "border: solid 0 [-CONTENT-];"
 + "border-right-width:1px;"
 + "padding-right:0.5ex;"
 + "border-left-width:1px;"
 + "padding-left:0.5ex;"
 + "border-bottom-width:1px;"
 + "padding-bottom:0.5ex;"
 + "}"
 + ".info,"
 + ".hint,"
 + ".hintc,"
 + ".exmp,"
 + ".expe"
 + ".xreply"
 + ".coshwarn"
 + ".loginbox"
 + ".usercreatereply"
 + "{"
 + "	padding:5px;"
 + "	margin: 10px 0px;"
 + "}"
 + ".hint"
 + "{"
 + "  margin-top: 0px;"
 + "  background-color: [-HINTBACKGROUND-];"
 + "  border: 0 !important;"
 + "  border-radius: 3px !important;"
 + "}"
 + ".hintc"
 + "{"
 + "  margin-top: 0px;"
 + "  background-color: [-HINTBACKGROUNDC-];"
 + "  border: 0 !important;"
 + "  border-radius: 3px !important;"
 + "}"
 + ".coshwarn,"
 + ".rouletteselector"
 + "{"
 + "  margin-top: 0px;"
 + "  padding-left: 5px;"
 + "  padding-right: 5px;"
 + "  background-color: [-HINTBACKGROUNDWARN-];"
 + "  border: this solid [-HINTLINE-];"
 + "  font-family: [-BASICFONTFAMILY-];"
 + "}"
 + ".rouletteselector"
 + "{"
 + "  background-color: white;"
 + "  border: 2px solid [-HINTLINE-];"
 + "}"
 + ".expe"
 + "{"
 + "  background-color: [-EXPEBACKGROUND-];"
 + "  border: 0 !important;"
 + "  border-radius: 3px !important;"
 + "}"
 + ".info"
 + "{"
 + "  background-color: [-INFOBACKGROUND-];"
 + "  border: 0 !important;"
 + "  border-radius: 3px !important;"
 + "}"
 + ".exmp"
 + "{"
 + "  background-color: [-EXMPBACKGROUND-];"
 + "  border: 0 !important;"
 + "  border-radius: 3px !important;"
 + "}"
 + ".xreply"
 + "{"
 + "  padding: 5px;"
 + "  background-color: [-REPLYBACKGROUND-];"
 + "  color: [-REPLYCOLOR-];"
 + "  border-radius: 4px;"
 + "  box-shadow: 0 2px 2px -1px rgba(0, 0, 0, 0.055);"
 + "  margin: 8px 12px 8px 12px;"
 + "  font-family: [-BASICFONTFAMILY-];"
 + "  font-weight: 300;"
 + "  font-size: [-BIGFONTSIZE-];"
 + "  border: thin solid [-HINTLINE-]"
 + "}"
 + ".usercreatereply"
 + "{"
 + "  padding: 5px;"
 + "  background-color: [-REPLYBACKGROUND-];"
 + "  color: [-REPLYCOLOR-];"
 + "  box-shadow: 0 2px 2px -1px rgba(0, 0, 0, 0.055);"
 + "  margin: 8px 12px 8px 12px;"
 + "  font-family: [-BASICFONTFAMILY-];"
 + "  font-weight: 300;"
 + "  font-size: [-BIGFONTSIZE-];"
 + "}"
 + ".loginbox"
 + "{"
 + "  width: 70%px;"
 + "  padding: 5px;"
 + "  background-color: [-LOGINBACKGROUND-];"
 + "  color: [-LOGINCOLOR-];"
 + "  box-shadow: 0 2px 2px -1px rgba(0, 0, 0, 0.055);"
 + "  margin: 8px 12px 8px 12px;"
 + "  font-family: [-BASICFONTFAMILY-];"
 + "  font-weight: 300;"
 + "  font-size: [-BIGFONTSIZE-];"
 + "  border: thin solid [-INFOLINE-];"
 + "}"
 + "";