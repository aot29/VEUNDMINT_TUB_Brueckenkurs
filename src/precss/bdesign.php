/* --------------------------- Uebernahme vom alten Design --------------------------- */
.toc ul
{
  margin:  0px;
  padding: 0px;
}

.toc ul.level1a
{
  margin-top:       10px;
  padding-left:     5px;
  list-style-type:  none;
  font-weight:      bold;
  font-size:        [-SMALLFONTSIZE-];
  line-height:      20px;
}
.toc ul.level1b
{
  margin-top:       10px;
  padding-left:     5px;
  list-style-type:  none;
  font-weight:      bold;
  font-size:        [-SMALLFONTSIZE-];
  line-height:      25px;
}
.toc ul.level2
{
  margin-bottom:    10px;
  padding-left:     10px;
  list-style-type:  none;
  font-weight:      normal;
  font-size:        [-SMALLFONTSIZE-];
  line-height:      13px;
}
.toc ul.level3
{
  margin-bottom:    5px;
  margin-left: 1em;
  padding-top:      0px;
  padding-left:     15px;
  list-style-type:  disc;
  font-weight:      normal;
  font-size:        11px;
}
.toc li.selected
{
  font-weight:      bold;
  color: [-TOCSELECTED-];
}

.toc li.notselected
{
  font-weight:      normal;
  color: [-TOC-];
}

.toc li.bselected
{
  font-weight:      normal;
  color: [-TOCBSELECTED-];
}

.toc li.bnotselected
{
  font-weight:      normal;
  color: [-TOCB-];
}

tocnavsymb ul {
    margin: 0;
    padding: 0;
    list-style-type: disc;
}

tocnavsymb ul li {
      display: inline-block;
      list-style-type: none;
      color: #000000;
      width: 100%; 
  
  
  
      -webkit-transition: all 0.2s;
        -moz-transition: all 0.2s;
        -ms-transition: all 0.2s;
        -o-transition: all 0.2s;
        transition: all 0.2s; 
}

.head
{
  background-color: [-HEADBACKGROUND-];
  color: [-HEAD-];
  width: 100%;
  padding: 0px /* 0.2em 0px; */
  border-bottom: 1px solid black;
  border-top: 1px solid black;
}

.navi
{
  margin: 0px;
  color: [-XSYMBCOLOR-];
  background-color: [-NAVIBACKGROUND-];
  margin-left: [-MENUWIDTH-];
  border-bottom: 1px solid [-GENERALBORDER-];
}

.navi ul
{
  margin: 0px;
  padding: 0px;
  list-style-type:  none;
  text-align: center;  
}

.navi ul li,
.stdbutton,
.testsbutton,
.roulettebutton,
.nprev,
.nnext,
{
  background-color: [-TOCMINBUTTON-];
  display: inline-block;
  background-repeat: no-repeat;
  background-position: center top;
  margin: 0px;
  min-width: 35px;
  padding-top: 35px;
  padding-left: 12px;
  padding-right: 10px;
  border: 1px solid [-TOCMENUBORDER-];
  color: [-XSYMBCOLOR-];
}

.nprev {
  float: left;
}

.nnext {
  float: right;
}


.navi a
{
  padding-top: 35px;
}

#footer
{
  position: fixed;
  bottom: 0px;
  text-align: center;
  width: 100%;
  font-size: [-BIGFONTSIZE-];
  color: [-FOOT-];
  background-color: [-FOOTBACKGROUND-];
  padding: 0.2em 0px;
}


/* ------------------------- neues Design ------------------------------ */

/* align all img images in the center */
img {
    horizontal-align: middle;
    vertical-align: middle;
    margin-bottom: .25em;
}


/* Normaler xsection button */
.xsectbutton {
    padding: 0 !important;
    background-image: none !important;
}

.head, .headmiddle {
    padding: 0 !important;
    border: 0 !important;   
    font-family: 'open-sans-condensed' !important;
    font-weight: 700 !important;
    min-height:[-HEADHEIGHT-] !important;
}

.headmiddle {
    display: flex;
}

#minusbutton img,
#plusbutton img,
#sharebutton img,
#starbutton img,
#menubutton img,
.headmiddle a:nth-child(4) div,
.headmiddle a:nth-child(5) div
 {
	display: none !important;
}
.head .symbolbutton {
    background-color: transparent !important;
    border: 0 !important;
    color: white !important;
}
.head .symbolbutton:hover,
#listebutton:hover, #homebutton:hover {
    color: rgba(255,255,255,.5) !important;
}
#minusbutton:before {
	font-family: 'FontAwesome' !important;
	content: "\f068" !important;
	width: [-HEADHEIGHT-] !important;
	height: [-HEADHEIGHT-] !important;
	font-size: [-SMALLFONTSIZE-] !important;
	line-height: [-HEADHEIGHT-] !important;
}
#plusbutton:before {
	font-family: 'FontAwesome' !important;
	content: "\f067" !important;
	width: [-HEADHEIGHT-] !important;
	height: [-HEADHEIGHT-] !important;
	font-size: [-SMALLFONTSIZE-] !important;
	line-height: [-HEADHEIGHT-] !important;
}
#sharebutton:before {
	font-family: 'FontAwesome' !important;
	content: "\f1e0" !important;
	width: [-HEADHEIGHT-] !important;
	height: [-HEADHEIGHT-] !important;
	font-size: [-SMALLFONTSIZE-] !important;
	line-height: [-HEADHEIGHT-] !important;
}
#starbutton:before {
	font-family: 'FontAwesome' !important;
	content: "\f005" !important;
	width: [-HEADHEIGHT-] !important;
	height: [-HEADHEIGHT-] !important;
	font-size: [-SMALLFONTSIZE-] !important;
	line-height: [-HEADHEIGHT-] !important;
}
#menubutton:before {
	font-family: 'FontAwesome' !important;
	content: "\f0c9" !important;
	width: [-HEADHEIGHT-] !important;
	height: [-HEADHEIGHT-] !important;
	font-size: [-SMALLFONTSIZE-] !important;
	line-height: [-HEADHEIGHT-] !important;
}
#settingsbutton:before {
	font-family: 'FontAwesome' !important;
	content: "\f013" !important;
	width: [-HEADHEIGHT-] !important;
	height: [-HEADHEIGHT-] !important;
	font-size: [-SMALLFONTSIZE-] !important;
	line-height: [-HEADHEIGHT-] !important;
}
#listebutton:before {
	font-family: 'FontAwesome' !important;
	content: "\f03a" !important;
	font-weight: 400;
	width: [-HEADHEIGHT-] !important;
	height: [-HEADHEIGHT-] !important;
	font-size: [-SMALLFONTSIZE-] !important;
	line-height: [-HEADHEIGHT-] !important;
	display: inline-block;
	text-align: center;
}

#homebutton:before {
	font-family: 'FontAwesome' !important;
	content: "\f015" !important;
	font-weight: 400;
	width: [-HEADHEIGHT-] !important;
	height: [-HEADHEIGHT-] !important;
	font-size: [-SMALLFONTSIZE-] !important;
	line-height: [-HEADHEIGHT-] !important;
	display: inline-block;
	text-align: center;
}

#LOGINROW {
        display: inline-block;
        flex-grow:100;
        text-align:center
        /* color und content wird dynamisch gesetzt */
}


#loginbutton, #cdatabutton, #LOGINROW {
	text-transform: uppercase;
	padding: 2px 0px 2px 10px !important;
	font-size: [-SMALLFONTSIZE-] !important;
	letter-spacing: 0.5px !important;
	line-height: 26px;
}
#loginbutton:hover, #cdatabutton:hover {
	color: rgba(255,255,255,.5) !important;
}

/* navi */ 

.navi {
	font-family: 'open-sans-condensed' !important;
	font-weight: 700 !important;
    border-bottom: 0px !important;
    margin-left: 0px !important;
    min-height: [-NAVIHEIGHT-] !important;
    padding: 10px 0 !important;
    box-sizing: border-box;
}
.navi ul {
    padding: 0 [-HEADHEIGHT-] !important;
}
.navi ul li {
    background-color: transparent !important;
    display: inline-block;
    background-repeat: no-repeat;
    background-position: center top;
    border: 0 !important;
    margin: 0px;
    min-width: 35px;
    padding-top: 35px;
    padding-left: 12px;
    padding-right: 10px;
    border: 2px solid white;
    border-radius: 3px;
    color: #000090;
}
.navi ul li a {
    color: rgb(200,200,200) !important;
    display: inline-block;
    border: 2px solid rgba(255,255,255,0.5) !important;
    border-radius: 3px;
    padding: 5px 10px  !important;
    text-transform: uppercase !important;
    letter-spacing: 0.5px;
    margin: 0px 10px;
}

.navi ul li a:hover {
    background-color:rgba(255,255,255,.5) !important;
}

.navi ul li a.naviselected {
    color: white !important;
}

.navi .nprev a, .navi .nprev a:before {
    background-image: none !important;
    font-family: 'FontAwesome' !important;
	content: "\f104";
	color: white !important;
	width:60px !important;
	height:40px !important;
	line-height: 40px !important;
	font-size: 40px;
	font-weight: 400;
}
.navi .nnext a, .navi .nnext a:before {
    background-image: none !important;
    font-family: 'FontAwesome' !important;
	content: "\f105";
	color: white !important;	
	width:60px !important;
	height:40px !important;
	line-height: 40px !important;
	font-size: 40px;
	font-weight: 400;
}
.navi .nprev:hover a,
.navi .nnext:hover a {
	color:rgba(255,255,255,.5) !important;
}
.navi .nprev, .navi.nnext {
    background-color: transparent !important;
    border: 0 !important;
    background-image: none !important;
    padding: 0 10px !important;
}

/* toc */ 

/* toc with 15px padding to accomodate a vertical scrollbar, 15px are included in MENUWIDTH */
.toc {
    overflow-x: hidden;
    overflow-y: auto;
    padding: 0 !important;
    padding-right: 15px;
    margin-top: 0px !important;
    bottom: [-FOOTERHEIGHT-];
    top: [-TOCTOP-]  !important;
    font-family: 'open-sans-condensed' !important;
    font-weight: 700 !important;
    border-right: 0 !important;
    width:[-MENUWIDTH-] !important;
    box-sizing: border-box !important;
    position: fixed !important;
    background-color: [-TOCBACKGROUND-] !important;
}
tocnavsymb {
    background-color: transparent !important;
    border: 0 !important;
    box-shadow: 0 !important;
    color: [-TOCBORDERCOLOR-];
    margin: 0 !important;
	font-family: 'open-sans-condensed' !important;
    font-size: [-BASICFONTSIZE-];
    box-sizing: border-box !important;
}

.tocmintitle {
    background-color: transparent !important;
    color: [-TOCMINCOLOR-] !important;
    padding: 20px 10px !important;
    border: 0 !important;
    font-family: 'open-sans-condensed' !important;
    font-size: [-BIGFONTSIZE-];
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border-bottom: 1px solid [-TOCMINCOLOR-] !important;
    box-sizing: border-box !important;
}

tocnavsymb ul li ul li {
    border-bottom: 1px solid [-TOCMINCOLOR-] !important;
    padding: 3px 10px !important;
    box-sizing: border-box !important;
}
tocnavsymb ul li ul li ul li {
    border-bottom: 0 !important;
    padding: 3px 10px !important;
    box-sizing: border-box !important;
}
tocnavsymb ul li ul li.aktiv  {
    background-color: [-TOCMINCOLOR-] !important;
    padding: 3px 0px !important;
    box-sizing: border-box !important;
}
tocnavsymb ul li ul li.aktiv ul li {
    border-bottom: 0 !important;
    padding: 3px 10px !important;
    box-sizing: border-box !important;
}
tocnavsymb ul li ul li.aktiv a .tocminbutton {
	padding: 3px 10px !important;
}
tocnavsymb ul li ul li.aktiv a:hover .tocminbutton {
	color:rgba(255,255,255,0.5) !important;
}
tocnavsymb ul li ul li a:hover div{
    color: [-TOCMINCOLOR-] !important;
    box-sizing: border-box !important;
}
.xsymb {
    color: white !important;
    background-color: [-XSYMB-];
    display: inline-block;
    border:0 !important;
    background-color: transparent !important;
    padding: 0px 2px 0px 0px !important;
    font-weight: 300 !important;
    font-size: [-SMALLFONTSIZE-];
}
.xsymb:hover {
	color: rgba(255,255,255,0.5) !important;
}
.xsymb.status3:before {
	font-family: 'FontAwesome' !important;
	content: "\f15b" !important;
	width:auto !important;
	height: [-SMALLFONTSIZE-] !important;
	font-size: [-SMALLFONTSIZE-] !important;
	line-height: [-SMALLFONTSIZE-] !important;
}
.xsymb.status2:before {
	font-family: 'FontAwesome' !important;
	content: "\f0f6" !important;
	width:auto !important;
	height: [-SMALLFONTSIZE-] !important;
	font-size: [-SMALLFONTSIZE-] !important;
	line-height: [-SMALLFONTSIZE-] !important;
}
.xsymb.status1:before {
	font-family: 'FontAwesome' !important;
	content: "\f016" !important;
	width:auto !important;
	height: [-SMALLFONTSIZE-] !important;
	font-size: [-SMALLFONTSIZE-] !important;
	line-height: [-SMALLFONTSIZE-] !important;
}

.xsymb.state_problem {
    color: rgba(255,20,20,0.3) !important;
}
.xsymb.state_progress {
    color: rgba(255,255,20,0.3) !important;
}
.xsymb.state_done {
    color: rgba(20,255,20,0.3) !important;
}

.xsymb.selected {
    font-weight: 700 !important;
}

.xsymb.status3 tt,
.xsymb.status2 tt,
.xsymb.status1 tt {
   display: none;
}
/* footer */ 

#footer {
    font-family: 'open-sans-condensed' !important;
    font-weight: 700 !important;
    padding: 0px !important;
    color: white !important;
    height: [-FOOTERHEIGHT-] !important;
    text-transform: uppercase !important;
    max-width: auto !important;
    font-size: [-TINYFONTSIZE-] !important;
    line-height: [-FOOTERHEIGHT-] !important;
    letter-spacing: 0.5px;
    position: fixed;
    display: flex;
}


.footermiddle {
        display: inline-block;
        flex-grow:100;
        text-align:center
}

.footerleft, .footerright {
    display: inline-block;
    width: 150px;
    text-align:center
}


#footerleft .tocminbutton, #footerright .tocminbutton {
    font-size: [-TINYFONTSIZE-] !important;
    line-height: [-FOOTERHEIGHT-] !important;
    letter-spacing: 0.5px;
    color: white !important;
    font-family: 'open-sans-condensed' !important;
}
#footerleft a:hover .tocminbutton, #footerright a:hover .tocminbutton  {
    color: rgba(255,255,255,0.5) !important;
}


/* qtip */

.qtip-default {
    font-family: 'open-sans' !important;
    font-weight: 700;
    font-size: [-SMALLFONTSIZE-];
    border-width: 1px !important;
    border-style: solid;
    border-color: [-TOCMINCOLOR-] !important;
    background-color: [-LIGHTBACKGROUND-] !important;
    color: [-TOCMINCOLOR-];
    box-shadow: 2px 2px 5px rgba(0,0,0,0.7);
}


/* allgemein */

.tocminbutton {
    background-color: transparent !important;
    padding: 0 !important;
    border: 0 !important;
    font-family: 'open-sans-condensed' !important;
    font-size: [-BIGFONTSIZE-];
}
a .tocminbutton {
    color: white !important;
}


#settings {
    /* Element is hidden until toggled by mintscripts.js */
    position: absolute;
    top: 0;
    left: 0;
    width: 0;
    height: 0;
    overflow: hidden;
    visibility: hidden;
    padding: 10px;
    position: fixed;
    background-color: [-NAVIBACKGROUND-];
    border-style: solid;
    box-shadow: 2px 2px 5px rgba(0,0,0,0.7);
    border-color: rgb(0,82,140) !important;
    border-radius: 5px !important;
    font-family: 'open-sans-condensed';
    font-weight: 700;
    color: white;
    display: block;
}

.stdbutton {
    color: white !important;
    background-color: rgba(255,255,255,0) !important;
    border: 2px solid rgba(255,255,255,0.5) !important;
    border-radius: 3px;
    padding: 5px 10px  !important;
    text-transform: uppercase !important;
    letter-spacing: 0.5px;
    margin: 0px 10px;
    font-family: 'open-sans-condensed';
    font-weight: 700;
}

.stdbutton:hover {
    background-color:rgba(255,255,255,.5) !important;
}

.testsbutton {
    color: white !important;
    background-color: rgb(155, 125, 50) !important;
    border: 2px solid rgb(100, 100, 32) !important;
    border-radius: 3px;
    padding: 5px 10px  !important;
    text-transform: uppercase !important;
    letter-spacing: 0.5px;
    margin: 0px 10px;
    font-family: 'open-sans-condensed';
    font-weight: 700;
}

.testsbutton:hover {
    background-color: rgb(195, 195, 80) !important;
}

.roulettebutton {
    color: grey !important;
    background-color: rgba(215,235,255,0) !important;
    display: inline-block;
    border: 2px solid rgba(155,200,210,0.5) !important;
    border-radius: 3px;
    padding: 5px 10px  !important;
    text-transform: uppercase !important;
    letter-spacing: 0.5px;
    margin: 0px 10px;
    font-family: 'open-sans-condensed';
    font-weight: 700;
}

.roulettebutton:hover {
    background-color:rgba(215,235,255,.5) !important;
}

ul.legende {
    display: block;
    width:100%;
    margin-top: [-FOOTERHEIGHT-] !important;
    padding: 10px !important;
    font-size: smaller;
}
ul.legende li {
    color: [-TOCMINCOLOR-];
    font-weight: 300;
}
ul.legende li:first-child {
    color: [-TOCMINCOLOR-];
    font-weight: 700;
    text-transform: uppercase;
}
ul.legende li .xsymb {
    min-width: [-TINYFONTSIZE-];
    color: [-TOCMINCOLOR-] !important;
}
