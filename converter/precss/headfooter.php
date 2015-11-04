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
  font-family: "HelveticaNeue-Light", "Helvetica Neue Light", "Helvetica Neue", Helvetica, Arial, "Lucida Grande", Verdana, Arial, Helvetica , sans-serif;
  font-size: 16px;
}

.headright,
#footerright
{
  float: right;
  text-align: right;
  direction: rtl;
  margin-right: 15px;
  font-family: "HelveticaNeue-Light", "Helvetica Neue Light", "Helvetica Neue", Helvetica, Arial, "Lucida Grande", Verdana, Arial, Helvetica , sans-serif;
  font-size: 16px;
}

.headmiddle
{
  text-align: center;
  font-family: "HelveticaNeue-Light", "Helvetica Neue Light", "Helvetica Neue", Helvetica, Arial, "Lucida Grande", Verdana, Arial, Helvetica , sans-serif;
  font-size: 16px;
  display: flex;
}

.footermiddle
{
  text-align: center;
  font-family: "HelveticaNeue-Light", "Helvetica Neue Light", "Helvetica Neue", Helvetica, Arial, "Lucida Grande", Verdana, Arial, Helvetica , sans-serif;
  font-size: 16px;
}
