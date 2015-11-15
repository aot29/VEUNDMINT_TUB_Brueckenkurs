#content
{
  margin-left: [-MENUWIDTH-];
  padding: 10px;
  z-index: 10;
  margin-bottom: 20px;
  color: [-CONTENT-];
  background-color: [-CONTENTBACKGROUND-];
  min-width: 800px;
}


#start
{
  margin-left: [-MENUWIDTH-];
  padding: 10px;
  z-index: 10;
  margin-bottom: 20px;


  color: [-CONTENT-];
  background-color: [-CONTENTBACKGROUND-];
}

#content h1,
#content h2,
#content h3,
#content h4,
#content h5,
#content h6
{
  text-align: center;
}

#start h1,
#start h2,
#start h3,
#start h4,
#start h5,
#start h6
{
  text-align: left;
}

#content a,
#start a
{
  color: [-CONTENTANCHOR-];
}

#start a {
  text-decoration: underline;
}

#content a:hover
#start a:hover
{
  text-decoration: underline;
}

/*
 Spezielle td-Klassen fuer wtabular:

 Coding im split.pm_
         A -> keine Raender
         B -> Rand nur links
         C -> Rand nur rechts
         D -> Rand an beiden Seiten
*/

table.wtabular {
border-collapse: collapse;
table-layout: auto;
}

td.wtabular_A {
/* border : 1px solid; */
padding : 1px;
}

td.wtabular_B {
border: solid 0 [-CONTENT-];
border-left-width:1px;
padding-left:0.5ex;
}

td.wtabular_C {
border: solid 0 [-CONTENT-];
border-right-width:1px;
padding-right:0.5ex;
}

td.wtabular_D {
border: solid 0 [-CONTENT-];
border-right-width:1px;
padding-right:0.5ex;
border-left-width:1px;
padding-left:0.5ex;
}

td.wtabular_AU {
border: solid 0 [-CONTENT-];
border-bottom-width:1px;
padding-bottom:0.5ex;
}

td.wtabular_BU {
border: solid 0 [-CONTENT-];
border-left-width:1px;
padding-left:0.5ex;
border-bottom-width:1px;
padding-bottom:0.5ex;
}

td.wtabular_CU {
border: solid 0 [-CONTENT-];
border-right-width:1px;
padding-right:0.5ex;
border-bottom-width:1px;
padding-bottom:0.5ex;
}

td.wtabular_DU {
border: solid 0 [-CONTENT-];
border-right-width:1px;
padding-right:0.5ex;
border-left-width:1px;
padding-left:0.5ex;
border-bottom-width:1px;
padding-bottom:0.5ex;
}
