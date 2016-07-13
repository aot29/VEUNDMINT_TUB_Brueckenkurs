<?php

//mysql Zugansdaten, wenn Datenbank als Storage benutzt wird
$mysql_username = 'FBUser';
$mysql_password = 'kQAds4RI';
$mysql_hostname = 'localhost';
$mysql_dbname = 'UserData';

$mysql_user_table = 'users';
$mysql_data_table = 'data';

$pwhash = "$2y$10$1ZBvdFFYNQ9ROaUsDDrwGO4op1nBLP2Q7VyFagh5CPPq2h0bqjQDm";

$pw = $_GET["password"];
if (password_verify($pw, $pwhash)) {
} else {
    exit("Nicht authentifiziert!");
}

$like_string = $_GET["likestring"]; // Ggf. Auswahl des Benutzernamens durch like-Klausel in SELECT
$uid = $_GET["uid"]; // Ist "" falls alle Benutzer gelistet werden sollen
if( !isset( $like_string) ) { exit( "Fehler: Kein String gegeben" ); }
if( !isset( $uid) ) { exit( "Fehler: Kein uid gegeben" ); }
if(gettype($like_string) != "string")  { exit( "Fehler: Kein String-Datentyp fuer like gegeben" ); }
if(gettype($uid) != "string")  { exit( "Fehler: Kein String-Datentyp fuer uid gegeben" ); }

if ($uid == "") {
    // Es sollen alle uids gelistet werden
    try {
        //Mit Datenbank verbinden
        $database_handler = new PDO( "mysql:host=$mysql_hostname;dbname=$mysql_dbname;charset:utf8", $mysql_username, $mysql_password, array( PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION ) );
        
        //Hole liste aller Tabellen
        $table_query = $database_handler->query("SHOW TABLES FROM $mysql_dbname");
        $tables = $table_query->fetchAll(PDO::FETCH_NUM);
        
        if( ! in_array( array( 0 => $mysql_user_table), $tables, TRUE /*auch Datentyp prüfen*/ ) ) {
            $database_handler = null;
            exit("Fehler: user-Tabelle nicht gefunden");
        }
        
        if( ! in_array( array( 0 => $mysql_data_table), $tables, TRUE /*auch Datentyp prüfen*/ ) ) {
            $database_handler = null;
            exit("Fehler: data-Tabelle nicht gefunden");
        }
        
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
} else {
    // Datenpaket eines Einzelnutzers soll geliefert werden
    try {
        //Mit Datenbank verbinden
        $database_handler = new PDO( "mysql:host=$mysql_hostname;dbname=$mysql_dbname;charset:utf8", $mysql_username, $mysql_password, array( PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION ) );
        
        //Hole liste aller Tabellen
        $table_query = $database_handler->query("SHOW TABLES FROM $mysql_dbname");
        $tables = $table_query->fetchAll(PDO::FETCH_NUM);
        
        if( ! in_array( array( 0 => $mysql_user_table), $tables, TRUE /*auch Datentyp prüfen*/ ) ) {
            $database_handler = null;
            exit("Fehler: user-Tabelle nicht gefunden");
        }
        
        if( ! in_array( array( 0 => $mysql_data_table), $tables, TRUE /*auch Datentyp prüfen*/ ) ) {
            $database_handler = null;
            exit("Fehler: data-Tabelle nicht gefunden");
        }
        
        $inj_string = $database_handler->quote($uid); //Escapen um SQL-Injection zu verhindern
        $query_string = "SELECT user_id,data FROM $mysql_data_table WHERE user_id= $inj_string";
        try {
            $data = $database_handler->query($query_string);
            $n = 0;
            $d = "";
            foreach ($data as $row) {
                $n = $n + 1;
                $d = $row['data'];
            }
            if ($n == 1) {
              echo "DATAGET: $d";
            } else {
              echo "ERROR: user_id $uid$ besitzt $n Datensaetze\n";
            }
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
}

exit( "Fehler bei Datenbankzugriff" );
?>
