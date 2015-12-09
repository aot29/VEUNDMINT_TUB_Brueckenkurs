<?php
/* Copyright (C) 2015 KIT (www.kit.edu), Author: Daniel Haase
 *
 *     This file is part of the VE&MINT program compilation
 *     (see www.ve-und-mint.de).
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 2 of the License,
 *     or any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see http://www.gnu.org
 */


$branch = "develop_content";
$bbusername = "mint_autoconverter";
$bbpassword = "autoconv";
$repo = "https://$bbusername:$bbpassword@bitbucket.org/dhaase/ve-und-mint.git";
$commits = 20;
$linkstring = "https://mintlx3.scc.kit.edu/autoconverter/ve-und-mint/tu9onlinekurstest/index.html";

function simple_execute($cm, $title) {
  echo("<p>");
  echo("<h3>$title</h3>");
  $reply = `$cm`;
  $reply = preg_replace("/\n/", "<br />", $reply);
  echo("<div style=\"color:#3333FF\"><tt>$reply</tt></div>");
  echo("</p>");
}
 
 
try {
  
  echo("<html>");
  echo("<head>");
  echo("<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/>");
  echo("</head>");
  
  echo("<body>");
  echo("<h1>Autoconverter von <a href=\"www.ve-und-mint.de\">https://www.ve-und-mint.de</a></h1>");
  
  chdir("ve-und-mint");

  simple_execute("git checkout $branch", "Wechsel auf branch $branch");
  simple_execute("git status", "Status des branchs");
  simple_execute("git pull $repo", "Die letzen $commits Änderungen:");
  
  $comtext = `git log -$commits`;
  $comtext = str_replace("<", "(", $comtext); $comtext = str_replace(">", ")", $comtext);  // eMail-Klammern entfernen
  $comtext = preg_replace("/Merge:\s+[\w\s]+\n/i", "", $comtext);
  $comtext = preg_replace("/commit\s+([\w\s]+)\nAuthor:\s(.+)\nDate:\s(.+)\n\n(.+)\n/i", "$4 ($2, $3)", $comtext);
  $comtext = preg_replace("/\n/", "<br />", $comtext);
  
  echo("<p><div style=\"color:#A05000\"><tt>");
  echo($comtext);
  echo("</tt></div></p>");
  
  
  echo("<p>");
  echo("Mail an Admin: <a href=\"mailto:admin@ve-und-mint.de\">admin@ve-und-mint.de</a>");
  echo("</p>");
  
  
  $reply = `converter/mconvert.pl tu9onlinekurs_test.pl`;
  

  echo("<p>");  
  echo("<br ><strong>Die Konvertierung wurde erzeugt und ist einsehbar unter <a href=\"$linkstring\">$linkstring</a></strong><br />");
  simple_execute("converter/mconvert.pl tu9onlinekurs_test.pl", "Konvertierungsmeldungen");
  echo("</p>");

  echo("</body>");
  echo("</html>");

  chdir("..");
  
  
} catch (Exception $e) {
	exit(json_encode(array('error' => 'Exception error', 'status' => false)));
}
?>
