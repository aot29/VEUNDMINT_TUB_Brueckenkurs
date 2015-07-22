<?php
/*
 * Debugging interface (for now)
 **/

include_once 'exercises.php';

try {
    $db_handler = db_connect();
    var_dump($db_handler);

    //add_exercise($db_handler, "add", "1+1=?");
    //add_exercise($db_handler, "sub", "1-1=?");

    //add_relation($db_handler, 'Grundrechenarten', 'add', 1);
    //add_roulette_id($db_handler, 'Grundrechenarten');
    //add_roulette_id($db_handler, 'Trigonometrie');
    //add_roulette($db_handler, 'Grundrechenarten', array('add', 'sub', 'mult', 'div'));
    
    add_from_json($db_handler, "example.json");
    add_from_json($db_handler, "no-collection.json");
    add_from_json($db_handler, "empty-collection.json");
    add_from_json($db_handler, "collectionexport.json");
    

} catch (Exception $e) {
    echo '<pre>';
    print_r($e);
    echo '</pre>';
    exit();
}
?>
