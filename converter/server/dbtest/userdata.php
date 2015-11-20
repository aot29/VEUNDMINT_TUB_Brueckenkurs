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

session_start(); //start the session
/*
 * Information stored in the session:
 * $_SESSION['authenticated']:
 *     Boolean that shows if a session is already authenticated (if a role is assigned).
 *     Don't rely on this for access permissions because users with the role 'anonymous'
 *     are also authenticated
 * $_SESSION['role']:
 *     The role of the current user ( see roles in authentication.php ). This is
 *     relevant for security. You can rely on this for access permission.
 * $_SESSION['username']:
 *     The name of the current user. Don't rely only on the username for
 *     access permission. You have to also check if the user_id matches.
 * $_SESSION['user_id']:
 *     The id of the current user. This is relevant for security. Use this to
 *     uniquely identify a user in combination with the username.
 **/
include_once 'authentication.php';

//Load settings
include_once 'userdata-config.php';

try {
	//connect to database
	$database_handler = new PDO("mysql:host=$mysql_hostname;dbname=$mysql_dbname;charset:utf8", $mysql_username, $mysql_password, array(PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION));

	//get list of all tables
	$table_query = $database_handler->query("SHOW TABLES FROM $mysql_dbname");
	$tables = $table_query->fetchAll(PDO::FETCH_NUM);

	//create table $mysql_users_table if it doesn't exist already
	if (!in_array(array(0 => $mysql_users_table), $tables, TRUE)) {
		$create_table = "CREATE TABLE $mysql_users_table ( user_id INT UNIQUE NOT NULL AUTO_INCREMENT PRIMARY KEY,
			user CHAR(255) UNIQUE NOT NULL,
			password CHAR(255) NOT NULL,
			role CHAR(30) NOT NULL,
			timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)";
		$database_handler->exec($create_table);
	}

	//create table $mysql_data_table if it doesn't exist already
	if (!in_array(array(0 => $mysql_data_table), $tables, TRUE)) {
		$create_table = "CREATE TABLE $mysql_data_table ( user_id INT UNIQUE NOT NULL PRIMARY KEY,
			data TEXT NOT NULL)";
		$database_handler->exec($create_table);
	}

	//database initialization is now done

	if (!$_SESSION['authenticated'] === true) {
		authenticate($database_handler, '', '', ''); // authenticate as role 'ANONYMOUS'
	}

	//IMPORTANT: Check the role first before doing anything
	switch ($_SERVER['REQUEST_METHOD']) {
		case 'GET':
			switch($_GET['action']) {
				case 'get_data':
					get_data($database_handler, filter_var($_GET['username']), $mysql_users_table, $mysql_data_table);
					break;
				case 'check_user': //check if a user already exists
					//this can be done by any role
					$username = filter_var($_GET['username']);
					exit(json_encode(array('action' => 'check_user',
						'user_exists' => user_exists($database_handler, $username, $mysql_users_table),
					   	'status' => true)));
					break;
				case 'get_role': //TODO allow admins to see the role of every user
					//this can be done by any role
					get_role($database_handler, filter_var($_GET['username']), $mysql_users_table);
					break;
				case 'get_username':
					//this can be done by any role
					exit(json_encode(array('action' => 'get_username',
						'username' => $_SESSION['username'],
						'status' => true)));
					break;
				case 'get_login_data':
					//this can be done by admins and evaluation
					get_login_data($database_handler, filter_var($_GET['username']), $mysql_users_table, $mysql_data_table);
					break;
				default:
					if ($_GET['action'] != NULL) {
						exit(json_encode(array('error' => "invalid action: '{$_GET['action']}'", 'status' => false)));
					}
					exit(json_encode(array('error' => 'no action specified', 'status' => false)));
			}
			break;
		case 'POST':
			switch ($_POST['action']) {
				case 'login':
					authenticate($database_handler, filter_var($_POST['username']), filter_var($_POST['password']), $mysql_users_table);
					exit(json_encode(array('action' => 'login',
						'role' => $_SESSION['role'],
						'username' => $_SESSION['username'],
						'status' => true)));
					break;
				case 'add_user':
					//any role can create new users
					$new_password = filter_var($_POST['password']);
					$new_username = filter_var($_POST['username']);
					$new_role = ROLES['USER'];
					if (isset($_POST['role'])) {
						//don't worry, adduser checks if this allowed
						$new_role = $_POST['role'];
					}

					adduser($database_handler, $new_username, $new_password, $new_role, $mysql_users_table);

					exit(json_encode(array(
						'action' => 'add_user',
						'role' => $new_role,
						'username' => $new_username,
						'status' => true)));
					break;
				case 'del_user':
					deluser($database_handler, filter_var($_POST['username']), $mysql_users_table, $mysql_data_table);
					break;
				case 'change_pwd':
					change_pwd($database_handler, filter_var($_POST['username']), filter_var($_POST['old_password']), filter_var($_POST['password']), $mysql_users_table);
					break;
				case 'change_role':
					change_role($database_handler, filter_var($_POST['username']), $_POST['role'], $mysql_users_table);
					break;
				case 'write_data':
					write_data($database_handler, filter_var($_POST['data']), filter_var($_POST['username']), $mysql_users_table, $mysql_data_table);
					break;
				case 'logout':
					logout();
					break;
				default:
					if ($_POST['action'] != NULL) {
						exit(json_encode(array('error' => "invalid action: '{$_POST['action']}'", 'status' => false)));
					}
					exit(json_encode(array('error' => 'no action specified', 'status' => false)));
			}
			break;
		default:
			exit(json_encode(array('error' => 'no action specified', 'status' => false)));
	}
} catch (PDOException $e) {
	$database_handler = null;
	//nl2br(var_dump($e)); //DEBUG ONLY, LEAKS DATA
	//echo  $e; //DEBUG ONLY, LEAKS DATA
	exit(json_encode(array('error' => 'database access failed', 'status' => false)));
}
?>
