.symbolbutton
{
  background-position: center;
  background-repeat: no-repeat;
  background-color: [-TOCMINBUTTON-];
  border: 1px solid [-TOCMINBORDER-];
}

.symbolbutton:hover
{
  background-color: [-TOCMINBUTTONHOVER-];
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

#footer
{
  position: fixed;
  bottom: 0px;
  text-align: center;
  width: 100%;
  font-size: [-BIGFONTSIZE-];
  /* max-width: 1000px; */
  color: [-FOOT-];
  background-color: [-FOOTBACKGROUND-];
  padding: 0.2em 0px;
}

.headleft,
.headright,
#footerleft,
#footerright
{
  overflow: visible;
  width: 0px;
  white-space: nowrap;
}

.headleft,
#footerleft
{
  float: left;
  text-align: left;
  direction: ltr;
  margin-left: 15px;
  font-family: [-BASICFONTFAMILY-];
  font-size: [-BASICFONTSIZE-];
}

.headright,
#footerright
{
  float: right;
  text-align: right;
  direction: rtl;
  margin-right: 15px;
  font-family: [-BASICFONTFAMILY-];
  font-size: [-BASICFONTSIZE-];
}

.headmiddle
{
  text-align: center;
  display: flex;
  background-color: [-HEADBACKGROUND-];
  font-weight: normal;
  text-align: left;
  font-family: [-BASICFONTFAMILY-];
  font-size: [-BIGFONTSIZE-];
  border-bottom: 1px solid black;
  border-top: 0px solid black;
}

.footermiddle
{
  text-align: center;
  font-family: [-BASICFONTFAMILY-];
  font-size: [-BASICFONTSIZE-];
  border-top: 1px solid [-GENERALBORDER-];
  border-bottom: 0px solid [-GENERALBORDER-];
}

