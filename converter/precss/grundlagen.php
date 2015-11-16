<?php header('Content-type: text/css'); ?>

body
{
  /* max-width: 1000px; */
  font-family: [-BASICFONTFAMILY-];
  font-size: [-BASICFONTSIZE-];
  padding: 0px;
  margin: 0px;
  height: 100%;  
}

input
{
  font-family: [-BASICFONTFAMILY-];
  font-size: [-BASICFONTSIZE-];
  height: 100%;  
}

button
{
  font-family: [-BASICFONTFAMILY-];
  font-size: [-BASICFONTSIZE-];
  height: 100%;  
}

td {
  font-size: [-BASICFONTSIZE-];
}

hr
{
  display: none;
}

#fixed,
#notfixed
{
  position: relative;
  width: 100%;
  /* max-width: 1000px; */
}

#fixed
{
  position: fixed;
  top: 0px;
  left: 0px;
  z-index: 1;
}
a
{
  font:  inherit;
  color: inherit;
  text-decoration: none;
}

.clear
{
  clear:    both;
  height:   0px;
  overflow: hidden;
}

#editor {
  position: relative;
  width: 600px;
  height: 400px;
}


/* Progress-Bar styling mit Browserweichen */
progress {  
  background-color: #F0F0F0;  
  border: 1;  
  height: 11px; 
  width: 90%;
}  

/* Firefox */
progress::-moz-progress-bar {
        background-image: -moz-linear-gradient(
                center bottom,
                rgb(43,194,123) 37%,
                rgb(84,240,124) 69%
        );
}
 
/* Chrome */
progress::-webkit-progress-value {
        background-image: -webkit-gradient(
                linear,
                left bottom,
                left top,
                color-stop(0, rgb(43,194,123)),
                color-stop(1, rgb(84,240,124))
        );
        background-image: -webkit-linear-gradient(
                center bottom,
                rgb(43,194,123) 37%,
                rgb(84,240,124) 69%
        );
}
 
/* Polyfill */
progress[aria-valuenow]:before {
        background-image: -moz-linear-gradient(
                center bottom,
                rgb(43,194,123) 37%,
                rgb(84,240,124) 69%
        );
        background-image: -ms-linear-gradient(
                center bottom,
                rgb(43,194,123) 37%,
                rgb(84,240,124) 69%
        );
        background-image: -o-linear-gradient(
                center bottom,
                rgb(43,194,123) 37%,
                rgb(84,240,124) 69%
        );
}




.searchtable {
     font-size: [-SMALLFONTSIZE-];
    -webkit-column-count: 2; /* Chrome, Safari, Opera */
    -moz-column-count: 2; /* Firefox */
    column-count: 2;
}

<?php
include('headfooter.php');
include('toc.php');
include('navi.php');
include('content.php');
include('boxen.php');
?>

