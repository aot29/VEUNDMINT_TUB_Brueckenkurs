<?php

$pwhash = "$2y$10$.Y8rSyYkjoA1x2T3mxizUOVe1w1GZjaMPJXmizbzJM/zPkUGrQ4KC";
$pw = $_GET["password"];
if (password_verify($pw, $pwhash)) {
} else {
    exit("Nicht authentifiziert!");
}




exit();
?>
