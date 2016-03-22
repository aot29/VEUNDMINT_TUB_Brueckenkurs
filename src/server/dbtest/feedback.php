<?php
/* Copyright (C) 2015 KIT (www.kit.edu), Author: Max Bruckner (FSMaxB)
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

//load settings
include_once 'feedback-config.php';

$feedback_string = $_POST["feedback"];
if( !isset( $feedback_string ) || (gettype($feedback_string) != "string") ) {
	$feedback_string = "";
} else if( strlen($feedback_string) > $max_string_size ) { //string too long?
	exit( "error" );
}

$statistics_string = $_POST["statistics"];
if( !isset( $statistics_string ) || (gettype($statistics_string) != "string") ) {
	$statistics_string = "";
} else if( strlen($statistics_string) > $max_string_size ) { //string too long?
	exit( "error" );
}

if( ($feedback_string === "") && ($statistics_string === "") ) {
	exit( "nothing to write" );
}

$userip = ($_SERVER['X_FORWARDED_FOR']) ? $_SERVER['X_FORWARDED_FOR'] : $_SERVER['REMOTE_ADDR'];

if( $storage_backend === "database" ) {
	try {
		//connect to database
		$database_handler = new PDO( "mysql:host=$mysql_hostname;dbname=$mysql_dbname;charset:utf8", $mysql_username, $mysql_password, array( PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION ) );

		//get list of all tables
		$table_query = $database_handler->query("SHOW TABLES FROM $mysql_dbname");
		$tables = $table_query->fetchAll(PDO::FETCH_NUM);
		
		//create table $mysql_feedback_table if it doesn't exist already
		if( ! in_array( array( 0 => $mysql_feedback_table), $tables, TRUE /*also check data type*/ ) ) {
			$create_table = "CREATE TABLE $mysql_feedback_table ( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
				content TEXT NOT NULL,
				timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)";
			$database_handler->exec( $create_table );
		}

		//create table $mysql_statistics_table if it doesn't exist already
		if( ! in_array( array( 0 => $mysql_statistics_table), $tables, TRUE /*also check data type*/ ) ) {
			$create_table = "CREATE TABLE $mysql_statistics_table ( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
				content TEXT NOT NULL,
				timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)";
			$database_handler->exec( $create_table );
		}

		//write feedback to database if there is any
		if( $feedback_string !== "" ) {
			$feedback_string = $database_handler->quote($feedback_string . " FROM $userip"); //escape the feedback to prevent SQL injection
			$database_handler->exec("INSERT INTO $mysql_feedback_table( content ) VALUES ($feedback_string)");
			echo "success\n";
			echo "$feedback_string\n";
		}

		//write statistics to database if there are any
		if( $statistics_string !== "" ) {
			$statistics_string = $database_handler->quote($statistics_string . " FROM $userip"); //escape the statistics to prevent SQL injection
                        $database_handler->exec("INSERT INTO $mysql_statistics_table( content ) VALUES ($statistics_string)");
			echo "success\n";
			echo "$statistics_string\n";
		}

		
		
		//close database connection
		$database_handler = null;
		exit();
	} catch( PDOException  $e ) {
		$database_handler = null;
		$storage_backend = "file"; //fallback to file backend in case of a database error
	}
}

if( $storage_backend === "file" ) { //no 'else if' because 'file' is the fallback
	//remove line separators to make datasets distinguishible (only one line per dataset)
	$feedback_string = str_replace( array( "\n", "\r\n" ), '', $feedback_string );
	$statistics_string = str_replace( array( "\n", "\r\n" ), '', $statistics_string );


        
	//get current time
	$timestamp = time();

	$data = "";
	if( $feedback_string !== "" ) {
		$data .= "FEEDBACK,$timestamp: $feedback_string, FROM $userip\n";
	}
	if( $statistics_string !== "" ) {
		$data .= "STATISTICS,$timestamp: $statistics_string, FROM $userip\n";
	}

	/* Write $data to the file. LOCK_EX is used to prevent race conditions because file_put_contents
	 * blocks until it can get an exclusive lock, then writes to the file and removes the lock.
	 * This means that two scripts can run simultaneously without messing up lines by accessing the
	 * file simultaneously.
	 **/

			
	$return_value = file_put_contents( $file_path, "$data", FILE_APPEND | LOCK_EX );
	if( $return_value === FALSE ) {
		exit( "error" );
	} 
	echo "success\n$data";
	exit();
}

exit( "error" );
?>
