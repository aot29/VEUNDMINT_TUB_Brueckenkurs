.toc
{
  position:         fixed;
  width:            200px;
  height:           100%;
  padding:          1em 10px;
  margin:           0px;
  margin-top:       0px;
  color:            [-TOC-];
  background-color: [-TOCBACKGROUND-];
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
  font-size:        14px;
  line-height:      20px;
}
.toc ul.level1b
{
  margin-top:       10px;
  padding-left:     5px;
  list-style-type:  none;
  font-weight:      bold;
  font-size:        15px;
  line-height:      25px;
}
.toc ul.level2
{
  margin-bottom:    10px;
  padding-left:     10px;
  list-style-type:  none;
  font-weight:      normal;
  font-size:        11px;
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

/* ---------------------------- CSS toc navigation (old row style) ------------------------------------------------- */

tocnav {
  background-color: [-TOCFIRSTMENUBACKGROUND-];
  border: 1px solid [-TOCMENUBORDER-];
  border-radius: 4px;
  box-shadow: 0 2px 2px -1px rgba(0, 0, 0, 0.055);
  color: [-TOC-];
  display: block;
  margin: 8px 12px 8px 12px;
  overflow: hidden;
  width: 92%; 
  font-family: "HelveticaNeue-Light", "Helvetica Neue Light", "Helvetica Neue", Helvetica, Arial, "Lucida Grande", sans-serif;
  font-weight: 400;
  font-size: 15px;
  
}

  tocnav ul {
    margin: 0;
    padding: 0;
  }

    tocnav ul li {
      display: inline-block;
      list-style-type: none;
      
      -webkit-transition: all 0.2s;
        -moz-transition: all 0.2s;
        -ms-transition: all 0.2s;
        -o-transition: all 0.2s;
        transition: all 0.2s; 
    }
      
      tocnav > ul > li > a > .caret,
	  tocnav > ul > li > div ul > li > a > .caret {
        border-top: 4px solid #aaa;
        border-right: 4px solid transparent;
        border-left: 4px solid transparent;
        content: "";
        display: inline-block;
        height: 0;
        width: 0;
        vertical-align: middle;
  
        -webkit-transition: color 0.1s linear;
     	  -moz-transition: color 0.1s linear;
       	-o-transition: color 0.1s linear;
          transition: color 0.1s linear; 
      }
	  
	  	tocnav > ul > li > div ul > li > a > .caret {
			border-bottom: 4px solid transparent;
			border-top: 4px solid transparent;
			border-right: 4px solid transparent;
			border-left: 4px solid #f2f2f2;
			margin: 0 0 0 8px;
		}

      tocnav > ul > li > a {
        color: [-TOC-];
        display: block;
        line-height: 56px;
        padding: 0 12px;
        text-decoration: none;
        width: 165px;
      }

        tocnav > ul > li:hover {
          background-color: [-TOCHOVER-];
        }

        tocnav > ul > li:hover > a {
          color: [-TOC-];
        }

        tocnav > ul > li:hover > a > .caret {
          border-top-color: [-TOCHOVER-];
        }
		
		tocnav > ul > li > div ul > li:hover > a > .caret {
			border-left-color: [-TOCHOVER-];
		}
      
      tocnav > ul > li > div,
	  tocnav > ul > li > div ul > li > div {
        background-color: [-TOCMENUBACKGROUND-];
        border: 1px solid [-TOCMENUBORDER-];
        border-radius: 0 0 4px 4px;
        box-shadow: 0 2px 2px -1px rgba(0, 0, 0, 0.055);
        display: none;
        margin: 0;
        opacity: 0;
        position: absolute;
        width: 300px;
        visibility: hidden;
  
        -webkit-transiton: opacity 0.2s;
        -moz-transition: opacity 0.2s;
        -ms-transition: opacity 0.2s;
        -o-transition: opacity 0.2s;
        -transition: opacity 0.2s;
      }
	  
	  	tocnav > ul > li > div ul > li > div {
			background-color: [-TOCMENUBACKGROUND-];
			border-radius: 0 4px 4px 4px;
			box-shadow: inset 2px 0 5px rgba(0,0,0,.15);
			margin-top: -42px;
			right: -300px;
		}

        tocnav > ul > li:hover > div,
		tocnav > ul > li > div ul > li:hover > div {
          display: block;
          opacity: 1;
          visibility: visible;
        }

          tocnav > ul > li > div ul > li,
		  tocnav > ul > li > div ul > li > div ul > li {
            display: block;
			position: relative;
          }

            tocnav > ul > li > div ul > li > a,
			tocnav > ul > li > div ul > li > div ul > li > a {
              color: [-TOC-];
              display: block;
              padding: 12px 24px;
              text-decoration: none;
            }

              tocnav > ul > li > div ul > li:hover > a {
                background-color: [-TOCHOVER-];
              }
              
              
/* ---------------------------- CSS toc navigation (symbolized, for layout tu9_thin) ------------------------------------------------- */

.xsymb {
  background-color: [-XSYMB-];
  padding: 0px 5px 0px;
  border: 1px solid rgb(55,180,220);
  display: inline-block;
}

.tocminbutton {
  background-color: [-TOCMINBUTTON-];
  padding: 0px 5px 0px;
  border: 1px solid rgb(5,180,220);
}

tocnavsymb {
  background-color: #14D2FF;  /*    rgb(20,210,255); */
  border: 1px solid [-TOCMENUBORDER-];
  box-shadow: 0 2px 2px -1px rgba(0, 0, 0, 0.055);
  color: [-TOC-];
  display: block;
  margin: 8px 12px 8px 12px;
  overflow: hidden;
  width: 92%; 
  font-family: "HelveticaNeue-Light", "Helvetica Neue Light", "Helvetica Neue", Helvetica, Arial, "Lucida Grande", sans-serif;
  font-weight: 400;
  font-size: 15px;
  
}

  tocnavsymb ul {
    margin: 0;
    padding: 0;
    list-style-type: disc;
    columns: 1;
    -webkit-columns: 1;
    -moz-columns: 1;
    list-style-position: inside;
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
    
    /*
      tocnavsymb > ul > li > a > .caret,
      tocnavsymb > ul > li > div ul > li > a > .caret {
        border-top: 4px solid #aaa;
        border-right: 4px solid transparent;
        border-left: 4px solid transparent;
        content: "";
        display: inline-block;
        height: 0;
        width: 0;
        horizontal-align: middle;
        vertical-align: middle;
  
        -webkit-transition: color 0.1s linear;
          -moz-transition: color 0.1s linear;
        -o-transition: color 0.1s linear;
          transition: color 0.1s linear; 
      }
          
      tocnavsymb > ul > li > div ul > li > a > .caret {
        border-bottom: 4px solid transparent;
        border-top: 4px solid transparent;
        border-right: 4px solid transparent;
        border-left: 4px solid #f2f2f2;
        margin: 0 0 0 0px;
      }

      tocnavsymb > ul > li > a {
        color: [-TOC-];
        display: block;
        line-height: 40px;
        linw-width: 40px;
        padding: 9px 10px 0px;
        text-decoration: none;
      }

        tocnavsymb > ul > li:hover {
          background-color: [-TOCHOVER-];
        }

        tocnavsymb > ul > li:hover > a {
          color: [-TOC-];
        }

        tocnavsymb > ul > li:hover > a > .caret {
          border-top-color: [-TOCHOVER-];
        }
                
        tocnavsymb > ul > li > div ul > li:hover > a > .caret {
          border-left-color: [-TOCHOVER-];
        }
      
      tocnavsymb > ul > li > div,
          tocnavsymb > ul > li > div ul > li > div {
        background-color: [-TOCMENUBACKGROUND-];
        border: 1px solid [-TOCMENUBORDER-];
        border-radius: 0 0 4px 4px;
        box-shadow: 0 2px 2px -1px rgba(0, 0, 0, 0.055);
        display: none;
        margin: 0;
        opacity: 0;
        position: absolute;
        width: 300px;
        visibility: hidden;
  
        -webkit-transiton: opacity 0.2s;
        -moz-transition: opacity 0.2s;
        -ms-transition: opacity 0.2s;
        -o-transition: opacity 0.2s;
        -transition: opacity 0.2s;
      }
          
      tocnavsymb > ul > li > div ul > li > div {
        background-color: [-TOCMENUBACKGROUND-];
        border-radius: 0 4px 4px 4px;
        box-shadow: inset 2px 0 5px rgba(0,0,0,.15);
        margin-top: -42px;
        right: -300px;
      }

        tocnavsymb > ul > li:hover > div,
                tocnavsymb > ul > li > div ul > li:hover > div {
          display: block;
          opacity: 1;
          visibility: visible;
        }

        tocnavsymb > ul > li > div ul {
            columns: 2;
            -webkit-columns: 2;
            -moz-columns: 2;
        }
        
          tocnavsymb > ul > li > div ul > li,
                  tocnavsymb > ul > li > div ul > li > div ul > li {
            display: block;
                        position: relative;
          }

            tocnavsymb > ul > li > div ul > li > a,
                        tocnavsymb > ul > li > div ul > li > div ul > li > a {
              color: [-TOC-];
              display: block;
              padding: 12px 24px;
              text-decoration: none;
            }

              tocnavsymb > ul > li > div ul > li:hover > a {
                background-color: [-TOCHOVER-];
              }
*/
