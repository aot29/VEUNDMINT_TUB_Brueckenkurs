<?php

//Maximale Größe der geloggten Strings
$max_string_size = 1000;

//mysql Zugansdaten, wenn Datenbank als Storage benutzt wird
$mysql_username = 'Feedback';
$mysql_password = '5ehaQapA';
$mysql_hostname = 'localhost';
$mysql_dbname = 'Feedback';

$mysql_feedback_table = 'feedback';
$mysql_statistics_table = 'statistics';

$pwhash = "$2y$10$1ZBvdFFYNQ9ROaUsDDrwGO4op1nBLP2Q7VyFagh5CPPq2h0bqjQDm";

$pw = $_GET["password"];
if (password_verify($pw, $pwhash)) {
} else {
    exit("Nicht authentifiziert!");
}

$like_string = $_GET["likestring"];
if( !isset( $like_string) ) { exit( "Fehler: Kein String gegeben" ); }
if(gettype($like_string) != "string")  { exit( "Fehler: Kein String-Datentyp gegeben" ); }
if( strlen($like_string) > $max_string_size ) { exit( "Fehler: String zu lang" ); }


try {
		//Mit Datenbank verbinden
		$database_handler = new PDO( "mysql:host=$mysql_hostname;dbname=$mysql_dbname;charset:utf8", $mysql_username, $mysql_password, array( PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION ) );

		//Hole liste aller Tabellen
		$table_query = $database_handler->query("SHOW TABLES FROM $mysql_dbname");
		$tables = $table_query->fetchAll(PDO::FETCH_NUM);
		
		//Tabelle $mysql_statistics_table anlegen, wenn sie noch nicht existiert
		if( ! in_array( array( 0 => $mysql_statistics_table), $tables, TRUE /*auch Datentyp prüfen*/ ) ) {
			//Tabelle erstellen
			$create_table = "CREATE TABLE $mysql_statistics_table ( id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
				content TEXT NOT NULL,
				timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)";
			$database_handler->exec( $create_table );
		}

		//Wenn vorhanden, Feedback in Datenbank schreiben
                $inj_string = $database_handler->quote($like_string); //Escapen um SQL-Injection zu verhindern
                $query_string = "SELECT id,timestamp,content FROM $mysql_statistics_table WHERE content LIKE $inj_string";
                try {
                    $data = $database_handler->query($query_string);
                    $n = 0;
                    foreach ($data as $row) {
                      $ot = "id: " . $row['id'] . ", timestamp: " . $row['timestamp'] . ", content: " . $row['content'] . "\n"; 
                      echo $ot;
                      $n = $n + 1;
                    }
                    echo "Erfolg, $query_string erfolgreich ausgeführt und $n Zeilen erhalten!\n";
                } catch( PDOException $e) {
                    echo "Fehler, $query_string nicht von Datenbank akzeptiert\n";
                }
		
		//Datenbank-Verbindung schließen
		$database_handler = null;
		exit();
} catch( PDOException $e ) {
	$database_handler = null;
	exit("Fehler: PDOException");
}

exit( "Fehler bei Datenbankzugriff" );
?>
