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

.nprev,
.nnext,
.xnprev,
.xnnext,
.nprevg,
.nnextg,
.xnprevg,
.xnnextg
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

.navi a
{
  padding-top: 35px;
}

/* ------------------------- neues Design ------------------------------ */

.inormalbutton_book {
    padding: 0 !important;
    background-image: none !important;
}

.head, .headmiddle {
    padding: 0 !important;
    border: 0 !important;   
    font-family: 'open-sans-condensed' !important;
    font-weight: 700 !important;
    min-height:30px !important;
    background-color: rgba(0,82,140,1) !important;
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
	width:30px !important;
	height:30px !important;
	font-size: 14px !important;
	line-height: 30px !important;
}
#plusbutton:before {
	font-family: 'FontAwesome' !important;
	content: "\f067" !important;
	width:30px !important;
	height:30px !important;
	font-size: 14px !important;
	line-height: 30px !important;
}
#sharebutton:before {
	font-family: 'FontAwesome' !important;
	content: "\f1e0" !important;
	width:30px !important;
	height:30px !important;
	font-size: 14px !important;
	line-height: 30px !important;
}
#starbutton:before {
	font-family: 'FontAwesome' !important;
	content: "\f005" !important;
	width:30px !important;
	height:30px !important;
	font-size: 14px !important;
	line-height: 30px !important;
}
#menubutton:before {
	font-family: 'FontAwesome' !important;
	content: "\f0c9" !important;
	width:30px !important;
	height:30px !important;
	font-size: 14px !important;
	line-height: 30px !important;
}
#settingsbutton:before {
	font-family: 'FontAwesome' !important;
	content: "\f013" !important;
	width:30px !important;
	height:30px !important;
	font-size: 14px !important;
	line-height: 30px !important;
}
#listebutton:before {
	font-family: 'FontAwesome' !important;
	content: "\f03a" !important;
	font-weight: 400;
	width:30px !important;
	height:30px !important;
	font-size: 14px !important;
	line-height: 30px !important;
	display: inline-block;
	text-align: center;
}

#homebutton:before {
	font-family: 'FontAwesome' !important;
	content: "\f015" !important;
	font-weight: 400;
	width:30px !important;
	height:30px !important;
	font-size: 14px !important;
	line-height: 30px !important;
	display: inline-block;
	text-align: center;
}

#loginbutton, #cdatabutton, #LOGINROW {
	text-transform: uppercase;
	padding: 2px 0px 2px 10px !important;
	font-size: 14px !important;
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
    min-height:60px !important;
    background-color: rgba(0,82,140,.6) !important;
    padding: 10px 0 !important;
    box-sizing: border-box;
}
.navi ul {
    padding: 0 30px !important;
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
    color: white !important;
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

.navi .nprevg a, .navi .nprevg a:before {
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
.navi .xnnext a, .navi .xnnext a:before {
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
.navi .nprevg:hover a,
.navi .xnnext:hover a {
	color:rgba(255,255,255,.5) !important;
}
.navi .nprev, .navi.nnext, .navi .xnprev, .navi .xnnext, .navi .nprevg, .navi .nnextg, .navi .xnprevg, .navi .xnnextg {
    background-color: transparent !important;
    border: 0 !important;
    background-image: none !important;
    padding: 0 10px !important;
}

/* toc */ 

.toc {
    height: 100% !important;
    padding: 0 !important;
    margin: 0 !important;
	font-family: 'open-sans-condensed' !important;
	font-weight: 700 !important;
    top: 90px  !important;
    border-right: 0 !important;
    background-color: rgba(0,82,140,0.3) !important;
    width:160px !important;
    box-sizing: border-box !important;
}
tocnavsymb {
    background-color: transparent !important;
    border: 0 !important;
    box-shadow: 0 !important;
    color: #000090;
    margin: 0 !important;
	font-family: 'open-sans-condensed' !important;
    font-size: 16px;
    box-sizing: border-box !important;
}

.tocmintitle {
    background-color: transparent !important;
    color: rgb(0,82,140) !important;
    padding: 20px 10px !important;
    border: 0 !important;
    font-family: 'open-sans-condensed' !important;
    font-size: 18px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border-bottom: 1px solid rgb(0,82,140) !important;
    box-sizing: border-box !important;
}

tocnavsymb ul li ul li {
    border-bottom: 1px solid rgb(0,82,140) !important;
    padding: 3px 10px !important;
    box-sizing: border-box !important;
}
tocnavsymb ul li ul li ul li {
    border-bottom: 0 !important;
    padding: 3px 10px !important;
    box-sizing: border-box !important;
}
tocnavsymb ul li ul li.aktiv  {
    background-color: rgb(0,82,140) !important;
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
    color:rgb(0,82,140) !important;
    box-sizing: border-box !important;
}
.xsymb {
	border:0 !important;
	background-color: transparent !important;
	color: white !important;
	padding: 0px 2px 0px 0px !important;
}
.xsymb:hover {
	color: rgba(255,255,255,0.5) !important;
}
.xsymb.status3:before {
	font-family: 'FontAwesome' !important;
	content: "\f15b" !important;
	width:auto !important;
	height:14px !important;
	font-size: 14px !important;
	line-height: 14px !important;
}
.xsymb.status2:before {
	font-family: 'FontAwesome' !important;
	content: "\f0f6" !important;
	width:auto !important;
	height:14px !important;
	font-size: 14px !important;
	line-height: 14px !important;
}
.xsymb.status1:before {
	font-family: 'FontAwesome' !important;
	content: "\f016" !important;
	width:auto !important;
	height:14px !important;
	font-size: 14px !important;
	line-height: 14px !important;
}
.xsymb.erledigt {
	color: rgba(255,255,255,0.3) !important;
}

.xsymb.aktiv {
	color: red !important;
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
    height:20px !important;
    text-transform: uppercase !important;
    max-width: auto !important;
    background-color: rgba(0,82,140,.8) !important;
    font-size: 12px !important;
    line-height: 20px !important;
    letter-spacing: 0.5px;
}

#footerleft .tocminbutton, #footerleft .tocminbutton {
    font-size: 12px !important;
    line-height: 20px !important;
    letter-spacing: 0.5px;
    color: white !important;
    font-family: 'open-sans-condensed' !important;
}
#footerleft a:hover .tocminbutton {
    color: rgba(255,255,255,0.5) !important;
}

#footerright {
    font-size: 12px !important;
    line-height: 20px !important;
    letter-spacing: 0.5px;
    color: white !important;
    font-family: 'open-sans-condensed' !important;
}


/* qtip */

.qtip-default {
	font-family: 'open-sans-condensed' !important;
    border-width: 1px !important;
    border-style: solid;
    border-color: rgb(0,82,140) !important;
    background-color: rgb(255,255,255) !important;
    color: rgb(0,82,140);
    box-shadow: 2px 2px 5px rgba(0,0,0,0.7);
}


/* allgemein */

.tocminbutton {
    background-color: transparent !important;
    padding: 0 !important;
    border: 0 !important;
    font-family: 'open-sans-condensed' !important;
    font-size: 18px;
}
a .tocminbutton {
    color: white !important;
}

