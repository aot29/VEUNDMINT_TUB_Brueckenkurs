.head
{
  background-color: [-HEADBACKGROUND-];
	color: [-HEAD-];
	width: 100%;
	font-weight: bold;
	padding: 0.2em 0px;
	border-bottom: 2px solid black;
}

#footer
{
  position: fixed;
  bottom: 0px;
  text-align: center;
  width: 100%;
  font-size: 10px;
  max-width: 1000px;
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
}

.headright,
#footerright
{
  float: right;
  text-align: right;
  direction: rtl;
  margin-right: 15px;
}

.headmiddle,
#footermiddle
{
  text-align: center;
  font-size: 120%;
  font-family: Arial, Helvetica, Verdana, sans-serif;
}
