<?php
/*
 * This PHP script contains all the necessary functions to manage exercises in a database.
 *
 * Copyright (C) 2015 KIT (www.kit.edu), Author: Max Bruckner (FSMaxB)
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
include_once 'exercises-config.php';

/*
 * Connect to the database, create it if necessary and return
 * a PDO database handler.
 **/
function db_connect() {
    global $mysql_dbname, $mysql_username, $mysql_password, $mysql_hostname,
        $mysql_exercises_table, $mysql_roulettes_table, $mysql_relations_table;

    //connect to the database
    $db_handler = new PDO("mysql:host=$mysql_hostname;dbname=$mysql_dbname;charset:utf8", $mysql_username, $mysql_password, array(PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION));

    //get list of all tables
    $table_query = $db_handler->query("SHOW TABLES FROM $mysql_dbname");
    $tables = $table_query->fetchAll(PDO::FETCH_NUM);

    //create table $mysql_exercises_table if it doesn't exist already
    if (!in_array(array(0 => $mysql_exercises_table), $tables, TRUE)) {
        $create_table = "CREATE TABLE $mysql_exercises_table (exercise_id CHAR(255) UNIQUE NOT NULL PRIMARY KEY, exercise_content TEXT NOT NULL)";
        $db_handler->exec($create_table);
    }

    //create table $mysql_roulettes_table if it doesn't exist already
    if (!in_array(array(0 => $mysql_roulettes_table), $tables, TRUE)) {
        $create_table = "CREATE TABLE $mysql_roulettes_table (roulette_id CHAR(255) UNIQUE NOT NULL PRIMARY KEY)";
        $db_handler->exec($create_table);
    }

    //create table $mysql_relations_table if it doesn't exist already
    if (!in_array(array(0 => $mysql_relations_table), $tables, TRUE)) {
        $create_table = "CREATE TABLE $mysql_relations_table (roulette_id CHAR(255) NOT NULL, exercise_id CHAR(255) NOT NULL, position INT NOT NULL)";
        $db_handler->exec($create_table);
    }

    return $db_handler;
}

/*
 * Add an exercise to the database
 **/
function add_exercise($db_handler, $id, $content) {
    global $mysql_exercises_table;

    $statement = $db_handler->prepare("INSERT INTO $mysql_exercises_table (exercise_id, exercise_content) VALUES (:id, :content) ON DUPLICATE KEY UPDATE exercise_content=VALUES(exercise_content), exercise_id=VALUES(exercise_id)");
    $statement->bindValue(':id', $id, PDO::PARAM_STR);
    $statement->bindValue(':content', $content, PDO::PARAM_STR);
    return $statement->execute();
}

/*
 * Delete an exercise from the database
 */
function del_exercise($db_handler, $id) {
    global $mysql_exercises_table, $mysql_relations_table;

    $roulette_ids = roulettes_containing_exercise($db_handler, $id);

    //delete the exercise
    $exercise_statement = $db_handler->prepare("DELETE FROM $mysql_exercises_table WHERE exercise_id = :id");
    $exercise_statement->bindValue(':id', $id, PDO::PARAM_STR);
    $exercise_statement->execute();

    //delete all relations that referenced the exercise
    $relations_statement = $db_handler->prepare("DELETE FROM $mysql_relations_table WHERE exercise_id = :id");
    $relations_statement->bindValue(':id', $id, PDO::PARAM_STR);
    $relations_statement->execute();

    $count_statement = $db_handler->prepare("SELECT COUNT(*) FROM $mysql_relations_table WHERE roulette_id = :roulette_id");

    // remove roulettes that are empty because the exercise got deleted
    foreach ($roulette_ids as $roulette_id) {
        $count_statement->bindValue(':roulette_id', $roulette_id, PDO::PARAM_STR);
        $count_statement->execute();
        $count = $count_statement->fetch()[0];
        if ($count == 0) {
            del_roulette($db_handler, $roulette_id);
        }
    }
}

/*
 * Add a relation to the database
 */
function add_relation($db_handler, $roulette_id, $exercise_id, $position) {
    global $mysql_relations_table;

    $statement = $db_handler->prepare("INSERT INTO $mysql_relations_table (roulette_id, exercise_id, position) VALUES (:roulette_id, :exercise_id, :position) ON DUPLICATE KEY UPDATE roulette_id=VALUES(roulette_id), exercise_id=VALUES(exercise_id), position=VALUES(position)");
    $statement->bindValue(':roulette_id', $roulette_id, PDO::PARAM_STR);
    $statement->bindValue(':exercise_id', $exercise_id, PDO::PARAM_STR);
    $statement->bindValue(':position', $position, PDO::PARAM_INT);
    return $statement->execute();
}

/*
 * Add a roulette_id to the database and add the respective relations
 */
function add_roulette_id($db_handler, $id) {
    global $mysql_roulettes_table;

    $statement = $db_handler->prepare("INSERT IGNORE INTO $mysql_roulettes_table (roulette_id) VALUES (:id)");
    $statement->bindValue(':id', $id, PDO::PARAM_STR);
    return $statement->execute();
}

/*
 * Add a roulette (id an relations)
 */
function add_roulette($db_handler, $id, $exercise_ids) {
    global $mysql_roulettes_table, $mysql_relations_table;

    $drop_relations_statement = $db_handler->prepare("DELETE FROM $mysql_relations_table WHERE roulette_id = :id");
    $drop_relations_statement->bindValue(':id', $id, PDO::PARAM_STR);
    $drop_relations_statement->execute();

    add_roulette_id($db_handler, $id);

    //add all the relations
    foreach ($exercise_ids as $pos => $exercise_id) {
        add_relation($db_handler, $id, $exercise_id, $pos);
    }
}

/*
 * Add a roulettes from a JSON-File, see example.json
 */
function add_from_json($db_handler, $filename) {
    $json = file_get_contents($filename);
    if ($json === FALSE) {
        throw new Exception("Can't read '$filename'.");
    }

    $array = json_decode($json, TRUE/*associative array*/);

    //free memory
    $json = NULL;
    unset($json);

    foreach ($array['collections'] as $roulette) {
        if ($roulette === NULL) { //skip empty roulettes
            continue;
        }
        $ids = array(); //list of exercise id's in the current roulette
        foreach ($roulette['exercises'] as $pos => $exercise) {
            add_exercise($db_handler, $exercise['id'], base64_decode($exercise['content']));
            array_push($ids, $exercise['id']);
        }
        add_roulette($db_handler, $roulette['id'], $ids);
    }

    //free more memory
    $array = NULL;
    unset($array);
}

/*
 * Get an exercise based on the exercise_id
 */
function get_exercise($db_handler, $exercise_id) {
    global $mysql_exercises_table;

    $statement = $db_handler->prepare("SELECT * FROM $mysql_exercises_table WHERE exercise_id = :exercise_id");
    $statement->bindValue(':exercise_id', $exercise_id, PDO::PARAM_STR);
    $statement->execute();
    $result = $statement->fetch();

    if ($statement->rowCount() == 0) {
        return FALSE;
    }

    return $result["exercise_content"];
}

/*
 * Get a list of all exercises in the database
 */
function list_exercises($db_handler) {
    global $mysql_exercises_table;

    $statement = $db_handler->prepare("SELECT exercise_id FROM $mysql_exercises_table");
    $statement->execute();
    $data = $statement->fetchAll();
    $result = array();
    foreach ($data as $dataset) {
        array_push($result, $dataset['exercise_id']);
    }
    return $result;
}

/*
 * Get a list of all roulettes in the database
 */
function list_roulettes($db_handler) {
    global $mysql_roulettes_table;

    $statement = $db_handler->prepare("SELECT roulette_id FROM $mysql_roulettes_table");
    $statement->execute();
    $data = $statement->fetchAll();
    $result = array();
    foreach ($data as $dataset) {
        array_push($result, $dataset['roulette_id']);
    }
    return $result;
}

/*
 * Delete a roulette from the database
 */
function del_roulette($db_handler, $id) {
    global $mysql_roulettes_table, $mysql_relations_table, $mysql_exercises_table;

    $exercise_ids = exercises_in_roulette($db_handler, $id);

    //delete the roulette
    $roulette_statement = $db_handler->prepare("DELETE FROM $mysql_roulettes_table WHERE roulette_id = :id");
    $roulette_statement->bindValue(':id', $id, PDO::PARAM_STR);
    $roulette_statement->execute();

    //delete all relations that referenced the roulette
    $relations_statement = $db_handler->prepare("DELETE FROM $mysql_relations_table WHERE roulette_id = :id");
    $relations_statement->bindValue(':id', $id, PDO::PARAM_STR);
    $relations_statement->execute();

    //delete all the exercises
    $exercise_statement = $db_handler->prepare("DELETE FROM $mysql_exercises_table WHERE exercise_id = :exercise_id");

    if ($exercise_ids !== FALSE) {
        foreach ($exercise_ids as $exercise_id) {
            $roulette_count = number_of_containing_roulettes($db_handler, $exercise_id);
            if ($roulette_count == 0) { //only delete the exercise if it isn't contained by another roulette
                $exercise_statement->bindValue(":exercise_id", $exercise_id, PDO::PARAM_STR);
                $exercise_statement->execute();
            }
        }
    }
}

/*
 * Get a list of all roulettes that contain an exercise (roulette_ids)
 */
function roulettes_containing_exercise($db_handler, $id) {
    global $mysql_relations_table;

    $relations_statement = $db_handler->prepare("SELECT * FROM $mysql_relations_table WHERE exercise_id = :exercise_id");
    $relations_statement->bindValue(':exercise_id', $id, PDO::PARAM_STR);
    $relations_statement->execute();
    $relations = $relations_statement->fetchAll();

    $roulettes = array();
    foreach ($relations as $relation) {
        array_push($roulettes, $relation['roulette_id']);
    }

    return $roulettes;
}

/*
 * Returns how many roulettes contain a given exercise
 **/
function number_of_containing_roulettes($db_handler, $exercise_id) {
    global $mysql_relations_table;

    $count_statement = $db_handler->prepare("SELECT COUNT(*) FROM $mysql_relations_table WHERE exercise_id = :exercise_id");
    $count_statement->bindValue(':exercise_id', $exercise_id, PDO::PARAM_STR);
    $count_statement->execute();
    $count = $count_statement->fetch()[0];

    return $count;
}

/*
 * Get a list of all exercises in a roulette (exercise ids)
 */
function exercises_in_roulette($db_handler, $id) {
    global $mysql_relations_table;
    $relations_statement = $db_handler->prepare("SELECT * FROM $mysql_relations_table WHERE roulette_id = :roulette_id");
    $relations_statement->bindValue(':roulette_id', $id, PDO::PARAM_STR);
    $relations_statement->execute();
    $relations = $relations_statement->fetchAll();

    $exercises = array();
    foreach ($relations as $relation) {
        array_push($exercises, $relation['exercise_id']);
    }

    if ($relations_statement->rowCount() == 0) {
        return FALSE;
    }

    return $exercises;
}

/*
 * Check if the given roulette exists
 */
function roulette_exists($db_handler, $id) {
    global $mysql_roulettes_table;

    $count_statement = $db_handler->prepare("SELECT COUNT(*) FROM $mysql_roulettes_table WHERE roulette_id = :roulette_id");
    $count_statement->bindValue(':roulette_id', $id, PDO::PARAM_STR);
    $count_statement->execute();
    $count = $count_statement->fetch()[0];

    return $count > 0;
}

/*
 * Get a roulette and return it as JSON
 * {
 *  "id": "roulette_id",
 *  "exercises": [
 *    { "id": "exercise_id_1", "content": "content1" },
 *    { "id": "exercise_id_2", "content": "content1" }
 *  ]
 * }
 *
 * returns false if nothing is found
 */
function get_roulette($db_handler, $roulette_id) {
    global $mysql_relations_table, $mysql_exercises_table;
    
    if (!roulette_exists($db_handler, $roulette_id)) {
        return FALSE;
    }

    $exercise_ids = exercises_in_roulette($db_handler, $roulette_id);
    if ($exercise_ids === FALSE) {
        $exercise_ids = array();
    }

    $result = array("id" => $roulette_id, "exercises" => array());

    foreach ($exercise_ids as $exercise_id) {
        $exercise = get_exercise($db_handler, $exercise_id);
        if ($exercise === FALSE) {
            return FALSE;
        }
        array_push($result['exercises'], array($exercise_id => $exercise));
    }


    return $result;
}

/*
 * Generate a tree view of all the roulettes and exercises in the database
 */
function tree_view($db_handler) {
    $tree = '';
    $roulettes = list_roulettes($db_handler);

    foreach ($roulettes as $roulette) {
        $tree .= $roulette . "\n";
        $exercises = exercises_in_roulette($db_handler, $roulette);
        foreach ($exercises as $exercise) {
            $containing_roulettes = roulettes_containing_exercise($db_handler, $exercise);
            $count = count($containing_roulettes);
            $tree .= '└── ' . $exercise . "\t($count) [";
            foreach ($containing_roulettes as $containing_roulette) {
                $tree .= $containing_roulette . ', ';
            }
            $tree[strlen($tree)-2] = ']';
            $tree .= "\n";
        }
        $tree .= "\n";
    }
    return $tree;
}
?>
