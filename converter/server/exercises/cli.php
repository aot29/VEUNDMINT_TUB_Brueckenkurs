#!/usr/bin/php
<?php
include_once 'exercises.php';

if (php_sapi_name() != 'cli') {
    exit('<h1>ERROR: This can only be run from the command line.</h1>');
}


function print_help() {
    global $argv;
    echo "Usage:\n";
    echo "  $argv[0] --help\n";
    echo "  $argv[0] -h\n";
    echo "  $argv[0] exercise\n";
    echo "       list: List all exercises\n";
    echo "       show exercise_id: Show exercise with the given id\n";
    echo "       delete exercise_id: Delete exercise with the given id\n";
    echo "  $argv[0] collection\n";
    echo "       list: List all collections\n";
    echo "       show collection_id: Show collection with the given id\n";
    echo "       delete collection_id: Delete exercise with the given id\n";
    echo "  $argv[0] import filename.json\n";
    echo "  $argv[0] tree\n";
}

if ($argc < 2) {
    print_help();
    exit(1);
}

try {
    $db_handler = db_connect();
    switch ($argv[1]) {
        case '-h':
        case '--help':
            print_help();
            exit(0);
        case 'exercise':
            if ($argc < 3) {
                echo "ERROR: Missing argument for 'exercise'\n";
                print_help();
                exit(1);
            }
            switch ($argv[2]) {
                case 'show':
                    $output = get_exercise($db_handler, $argv[3]);
                    if ($output === FALSE) {
                        echo "ERROR: Exercise '$argv[3]' doesn't exist.\n";
                        exit(1);
                    }
                    echo $output;
                    exit(0);
                case 'list':
                    foreach(list_exercises($db_handler) as $line) {
                        echo $line."\n";
                    }
                    exit(0);
                case 'delete':
                    del_exercise($db_handler, $argv[3]);
                    exit(0);
            }
            break;
        case 'collection':
            if ($argc < 3) {
                echo "ERROR: Missing argument for 'collection'\n";
                print_help();
                exit(1);
            }
            switch ($argv[2]) {
                case 'show':
                    $output = get_roulette($db_handler, $argv[3]);
                    if ($output === FALSE) {
                        echo "ERROR: Roulette '$argv[3]' doesn't exist or is incomplete.\n";
                        exit(1);
                    }
                    //TODO find correct output method for cli
                    echo json_encode($output);
                    exit(0);
                case 'list':
                    foreach(list_roulettes($db_handler) as $line) {
                        echo $line."\n";
                    }
                    exit(0);
                case 'delete':
                    del_roulette($db_handler, $argv[3]);
                    exit(0);
            }
            break;
        case 'import':
            try {
                add_from_json($db_handler, $argv[2]);
            } catch (Exception $e) {
                echo $e;
                exit(1);
            }
            exit(0);
        case 'tree':
            echo tree_view($db_handler);
            exit(0);
        default:
            echo "ERROR: Unknown argument '$argv[1]'\n";
            print_help();
            exit(1);
    }
} catch (PDOException $e) {
    print_r($e);
    echo "ERROR: Database error. Check your settings in exercises-conf.php\n";
    exit(1);
}

?>
