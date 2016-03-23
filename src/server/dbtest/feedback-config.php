<?php
//maximum length of the feedback strings
$max_string_size = 1000;

//mysql login credentials (only relevant if the 'database' storage backend is used)
//replace those values with actual credentials
$mysql_username = 'Feedback';
$mysql_password = '5ehaQapA';
$mysql_hostname = 'localhost';
$mysql_dbname = 'Feedback';

$mysql_feedback_table = 'feedback';
$mysql_statistics_table = 'statistics';

//file path of the log file (this is used as fallback if the 'database' backend isn't available)
$file_path = '/veundmint_storage/strings.list';

//which storage backend to use? ( 'database' or 'file' )
//$storage_backend = 'file';
$storage_backend = 'database';
?>
