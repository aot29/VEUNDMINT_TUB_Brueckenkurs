<?php

//mysql Zugansdaten, wenn Datenbank als Storage benutzt wird
$mysql_username = 'FBUser';
$mysql_password = 'kQAds4RI';
$mysql_hostname = 'localhost';
$mysql_dbname = 'UserData';

$mysql_user_table = 'users';
$mysql_data_table = 'data';

$pwhash = "\$2y\$10\$O.CPDXuVhRwe2cJ5ZWUpF.WkBt5w0qjm6bQIGAvFBp86Mi9Dr1.li";

$pw = $_GET["password"];
if (password_verify($pw, $pwhash)) {
} else {
    exit("Nicht authentifiziert!");
}

$like_string = $_GET["likestring"]; // Ggf. Auswahl des Benutzernamens durch like-Klausel in SELECT
if( !isset( $like_string) ) { exit( "Fehler: Kein String gegeben" ); }
if(gettype($like_string) != "string")  { exit( "Fehler: Kein String-Datentyp gegeben" ); }

try {
		//Mit Datenbank verbinden
		$database_handler = new PDO( "mysql:host=$mysql_hostname;dbname=$mysql_dbname;charset:utf8", $mysql_username, $mysql_password, array( PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION ) );

		//Hole liste aller Tabellen
		$table_query = $database_handler->query("SHOW TABLES FROM $mysql_dbname");
		$tables = $table_query->fetchAll(PDO::FETCH_NUM);
		
		//Tabelle $mysql_statistics_table anlegen, wenn sie noch nicht existiert
		if( ! in_array( array( 0 => $mysql_user_table), $tables, TRUE /*auch Datentyp prüfen*/ ) ) {
                    $database_handler = null;
                    exit("Fehler: user-Tabelle nicht gefunden");
		}

                //Tabelle $mysql_statistics_table anlegen, wenn sie noch nicht existiert
                if( ! in_array( array( 0 => $mysql_data_table), $tables, TRUE /*auch Datentyp prüfen*/ ) ) {
                    $database_handler = null;
                    exit("Fehler: data-Tabelle nicht gefunden");
                }
                
		//Wenn vorhanden, Feedback in Datenbank schreiben
                $inj_string = $database_handler->quote($like_string); //Escapen um SQL-Injection zu verhindern
                $query_string = "SELECT user_id,user,role,timestamp FROM $mysql_user_table WHERE user LIKE $inj_string";
                try {
                    $data = $database_handler->query($query_string);
                    $n = 0;
                    foreach ($data as $row) {
                      $ot = "user_id: " . $row['user_id'] . ", timestamp: " . $row['timestamp'] . ", user: " . $row['user'] . ", role: " . $row['role'] . "\n"; 
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
