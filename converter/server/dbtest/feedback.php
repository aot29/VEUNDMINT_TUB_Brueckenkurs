<?php
//load settings
include_once 'feedback-config.php';

$feedback_string = $_POST["feedback"];
if( !isset( $feedback_string ) || (gettype($feedback_string) != "string") ) {
	$feedback_string = "";
} else if( strlen($feedback_string) > $max_string_size ) { //String zu lang?
	exit( "error" );
}

$statistics_string = $_POST["statistics"];
if( !isset( $statistics_string ) || (gettype($statistics_string) != "string") ) {
	$statistics_string = "";
} else if( strlen($statistics_string) > $max_string_size ) { //String zu lang?
	exit( "error" );
}

if( ($feedback_string === "") && ($statistics_string === "") ) {
	exit( "nothing to write" );
}

$userip = ($_SERVER['X_FORWARDED_FOR']) ? $_SERVER['X_FORWARDED_FOR'] : $_SERVER['REMOTE_ADDR'];

if( $storage_backend === "database" ) {
	try {
		//Mit Datenbank verbinden
		$database_handler = new PDO( "mysql:host=$mysql_hostname;dbname=$mysql_dbname;charset:utf8", $mysql_username, $mysql_password, array( PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION ) );

		//Hole liste aller Tabellen
		$table_query = $database_handler->query("SHOW TABLES FROM $mysql_dbname");
		$tables = $table_query->fetchAll(PDO::FETCH_NUM);
		
		//Tabelle $mysql_feedback_table anlegen, wenn sie noch nicht existiert
		if( ! in_array( array( 0 => $mysql_feedback_table), $tables, TRUE /*auch Datentyp prüfen*/ ) ) {
			//Tabelle erstellen
			$create_table = "CREATE TABLE $mysql_feedback_table ( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
				content TEXT NOT NULL,
				timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)";
			$database_handler->exec( $create_table );
		}

		//Tabelle $mysql_statistics_table anlegen, wenn sie noch nicht existiert
		if( ! in_array( array( 0 => $mysql_statistics_table), $tables, TRUE /*auch Datentyp prüfen*/ ) ) {
			//Tabelle erstellen
			$create_table = "CREATE TABLE $mysql_statistics_table ( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
				content TEXT NOT NULL,
				timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)";
			$database_handler->exec( $create_table );
		}

		//Wenn vorhanden, Feedback in Datenbank schreiben
		if( $feedback_string !== "" ) {
			$feedback_string = $database_handler->quote($feedback_string . " FROM $userip"); //Escapen um SQL-Injection zu verhindern
			$database_handler->exec("INSERT INTO $mysql_feedback_table( content ) VALUES ($feedback_string)");
			echo "success\n";
			echo "$feedback_string\n";
		}

		//Wenn vorhanden, Feedback in Datenbank schreiben
		if( $statistics_string !== "" ) {
			$statistics_string = $database_handler->quote($statistics_string . " FROM $userip"); //Escapen um SQL-Injection zu verhindern
                        $database_handler->exec("INSERT INTO $mysql_statistics_table( content ) VALUES ($statistics_string)");
			echo "success\n";
			echo "$statistics_string\n";
		}

		
		
		//Datenbank-Verbindung schließen
		$database_handler = null;
		exit();
	} catch( PDOException  $e ) {
		$database_handler = null;
		$storage_backend = "file";	//Fallback zur Speicherung in einer Datei
	}
}

if( $storage_backend === "file" ) { //Kein elseif weil "file" der Fallback für "database" is
	//Zeilentrenner entfernen ( sonst kann man keine Datensätze unterscheiden )
	$feedback_string = str_replace( array( "\n", "\r\n" ), '', $feedback_string );
	$statistics_string = str_replace( array( "\n", "\r\n" ), '', $statistics_string );


        
	//Timestamp holen
	$timestamp = time();

	$data = "";
	if( $feedback_string !== "" ) {
		$data .= "FEEDBACK,$timestamp: $feedback_string, FROM $userip\n";
	}
	if( $statistics_string !== "" ) {
		$data .= "STATISTICS,$timestamp: $statistics_string, FROM $userip\n";
	}

	/* Schreiben $data in die Datei. LOCK_EX sorgt dafür, dass hierbei keine race conditions auftreten
	 * file_put_contents wartet, bis es sich ein exclusive lock holen kann, schreibt dann in die Datei und gibt das
	 * lock dann wieder frei! Deswegen können beliebig viele Anfragen an den Server eintreffen, ohne dass zwei 
	 * Skripte gleichzeitig in die Datei schreiben
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
