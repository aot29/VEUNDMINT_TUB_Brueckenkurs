<?php
//Maximale Größe der geloggten Strings
$max_string_size = 1000;

//mysql Zugansdaten, wenn Datenbank als Storage benutzt wird
$mysql_username = 'Feedback'; //Durch tatsächlichen Nutzernamen zu ersetzen!
$mysql_password = '5ehaQapA';
$mysql_hostname = 'localhost';
$mysql_dbname = 'Feedback'; //Durch tatsächlichen Datenbank-Namen zu ersetzen!

$mysql_feedback_table = 'feedback';
$mysql_statistics_table = 'statistics';

//Dateipfad falls eine Datei als Storage benutzt wird
$file_path = "/veundmint_storage/strings.list";

//Was für eine Storage-Backend? ( "database" oder "file" )
//$storage_backend = "file";
$storage_backend = "database";
?>
