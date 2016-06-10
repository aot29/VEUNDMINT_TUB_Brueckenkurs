<?php

$pwhash = "\$2y\$10\$O.CPDXuVhRwe2cJ5ZWUpF.WkBt5w0qjm6bQIGAvFBp86Mi9Dr1.li";
$pw = $_GET["password"];
if (password_verify($pw, $pwhash)) {
} else {
    exit("Nicht authentifiziert!");
}




exit();
?>
