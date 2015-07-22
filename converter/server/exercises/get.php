<?php
include_once "exercises.php";

if (is_string($_GET["id"])) {
    try {
        $db_handler = db_connect();
        $output = get_roulette($db_handler, $_GET["id"]);
        if ($output === FALSE) {
            exit(json_encode(array("status" => false, "error" => "collection doesn't exist or is incomplete")));
        }
        $output["status"] = true;
        exit(json_encode($output));
    } catch (PDOException $e) {
        exit(json_encode(array("status" => false, "error" => "database access failed")));
    }
} else {
    exit(json_encode(array("status" => false, "error" => "no id specified" )));
}
?>
