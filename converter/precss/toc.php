.toc
{
  position:         fixed;
  width:            164px; /* 185-21 */
  height:           100%;
  padding:          1em 10px;
  margin:           0px;
  margin-top:       0px;
  color:            [-TOC-];
  background-color: [-TOCBACKGROUND-];
  border-right: 1px solid [-GENERALBORDER-];
}

.toccaption
{
  font-size: 110%;
  font-weight: bold;
}

.homelink
{
  float: right;
  font-weight: bold;
}

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

.xsymb {
  background-color: [-XSYMB-];
  padding: 0px 5px 0px;
  border: 1px solid rgb(55,180,220);
  display: inline-block;
  color: [-XSYMBCOLOR-];
}

.xsymb:hover {
  background-color: [-XSYMBHOVER-];
}

.tocmintitle {
  background-color: [-TOCNAVSYMBBACKGROUND-];
  color: [-TOCMINBUTTONCOLOR-];
  padding: 0px 5px 0px;
  border: 1px solid [-TOCMINBORDER-];
  font-family: "HelveticaNeue-Light", "Helvetica Neue Light", "Helvetica Neue", Helvetica, Arial, "Lucida Grande", sans-serif;
  font-size: [-BIGFONTSIZE-];
}

.tocminbutton {
  background-color: [-TOCMINBUTTON-];
  color: [-TOCMINBUTTONCOLOR-];
  padding: 0px 5px 0px;
  border: 1px solid [-TOCMINBORDER-];
  font-family: "HelveticaNeue-Light", "Helvetica Neue Light", "Helvetica Neue", Helvetica, Arial, "Lucida Grande", sans-serif;
  font-size: [-BIGFONTSIZE-];
}

.tocminbutton:hover {
  background-color: [-TOCMINBUTTONHOVER-];
}

tocnavsymb {
  background-color: [-TOCNAVSYMBBACKGROUND-];
  border: 1px solid [-TOCMENUBORDER-];
  box-shadow: 0 2px 2px -1px rgba(0, 0, 0, 0.055);
  color: [-TOC-];
  display: block;
  margin: 8px 4px 8px 4px;
  overflow: hidden;
  font-family: "HelveticaNeue-Light", "Helvetica Neue Light", "Helvetica Neue", Helvetica, Arial, "Lucida Grande", sans-serif;
  font-size: [-BASICFONTSIZE-];
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

tocnavsymb ul li ul li {
      display: inline-block;
      list-style-type: none;
      color: #FFFFFF;
  
  
      -webkit-transition: all 0.2s;
        -moz-transition: all 0.2s;
        -ms-transition: all 0.2s;
        -o-transition: all 0.2s;
        transition: all 0.2s; 
}
    
