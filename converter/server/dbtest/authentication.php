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

//list of all roles
const ROLES = array(
	'ADMIN' => 'admin',
	'PROOFREADER' => 'proofreader',
	'EVALUATION' => 'evaluation',   //has access to loginData of every user
	'USER' => 'user',
	'ANONYMOUS' => 'anonymous');

//check if a given user exists
function user_exists($database_handler, $username, $mysql_users_table) {
	$statement = $database_handler->prepare("SELECT * FROM $mysql_users_table WHERE user = :username");
	$statement->bindValue(':username', $username, PDO::PARAM_STR);
	$status = $statement->execute();
	if (!$status) {
		exit(json_encode(array('error' => 'error in function "user_exists"',
			'status' => false)));
	}
	$users = $statement->rowCount();
	return $users !== 0;
}

//get the database column containing everything about a user
//this is meant for internal use only and mustn't be exposed via the API
function get_user_column($database_handler, $username, $mysql_users_table) {
	if ($username == "") {
		exit(json_encode(array('error' => 'no username specified',
			'status' => false)));
	}
	$statement = $database_handler->prepare("SELECT * FROM $mysql_users_table WHERE user = :username");
	$statement->bindValue(':username', $username, PDO::PARAM_STR);
	$statement->execute();
	if ($statement->rowCount() > 1) {
		exit(json_encode(array('error' => 'multiple db entries for the same user, please contact an administrator',
			'status' => false)));
	}
	return $statement->fetch();
}

//authenticate a given user
function authenticate ($database_handler, $username, $password, $mysql_users_table) {
	$_SESSION['role'] = ROLES['ANONYMOUS'];
	$_SESSION['authenticated'] = true;
	unset($_SESSION['username']); //IMPORTANT FOR SECURITY
	unset($_SESSION['user_id']);
	if ($username == '') { // == is used on purpose rather than === because it has to also match 'undefined'
		return;
	}

	//NOTICE this is prone to race conditions
	//It could happen that a user is deleted in the time between
	//checking if the user exists and the time the user info get's
	//read from the database. This isn't a security risk though,
	//this might only cause an exception
	if(!user_exists($database_handler, $username, $mysql_users_table)) {
		exit(json_encode(array('action' => 'login',
			'error' => "user doesn't exist",
			'status' => false)));
	}

	//get user information from database
	$user_column = get_user_column($database_handler, $username, $mysql_users_table);

	//if the password is valid
	if (password_verify($password, $user_column['password'])) {
		if (in_array($user_column['role'], ROLES)) {
			//if the role in the database is valid, store it in the session
			$_SESSION['role'] = $user_column['role'];
		} else {
			exit(json_encode(array('action' => 'login', 'error' => 'invalid role in database', 'status' => false)));
		}

		//store information in the session
		$_SESSION['user_id'] = $user_column['user_id'];
		$_SESSION['username'] = $user_column['user'];
		$_SESSION['authenticated'] = true;
	} else {
		exit(json_encode(array('action' => 'login', 'error' => 'invalid password', 'status' => false)));
	}
}

//add a new user to the database
function adduser ($database_handler, $username, $password, $role, $mysql_users_table) {
	//checke if the role exists
	if (!in_array($role, ROLES)) {
		exit(json_encode(array('action' => 'add_user',
			'error' => 'invalid role', 'status' => false)));
	}

	//IMPORTANT SECURITY CHECK
	switch ($_SESSION['role']) {
		case ROLES['ADMIN']:
			//leave $role as it is because admins can set any role
			break;
		default:
			//other users can only create regular users
			$role = ROLES['USER'];
	}

	if ($username == '') {
		exit(json_encode(array('action' => 'add_user', 'error' => 'no username specified', 'status' => false)));
	}

	if ($password == '') {
		exit(json_encode(array('action' => 'add_user', 'error' => 'no password specified', 'status' => false)));
	}

	$hash = password_hash($password, PASSWORD_DEFAULT);

	//add the new user to the database
    $statement = $database_handler->prepare("INSERT IGNORE INTO $mysql_users_table ( user, password, role ) VALUES ( :username, :hash, :role )");
	$statement->bindValue(':username', $username, PDO::PARAM_STR);
	$statement->bindValue(':hash', $hash, PDO::PARAM_STR);
	$statement->bindValue(':role', $role, PDO::PARAM_INT);
	$status = $statement->execute();

	if ($statement->rowCount() == 0) { //If nothing happened, the user already exists
		exit(json_encode(array('action' => 'add_user', 'error' => 'user already exists', 'status' => false)));
	}

	if (!$status) {
		exit(json_encode(array('action' => 'add_user', 'error' => 'couldn\'t creat user', 'status' => false)));
	} else {
		exit(json_encode(array('action' => 'add_user', 'status' => true)));
	}
}

//delete a user from the database
function deluser($database_handler, $username, $mysql_users_table, $mysql_data_table) {
	if ($_SESSION['role'] === ROLES['ANONYMOUS']) {
		exit(json_encode(array('action' => 'del_user',
			'error' => 'anonymous users aren\'t allowed to delete users',
			'status' => false)));
	}
	if (($_SESSION['role'] !== ROLES['ADMIN']) && ($_SESSION['username'] !== $username)) {
		exit(json_encode(array('action' => 'del_user',
			'error' => 'only admins can delete other users',
			'status' => false)));
	}

	$user_column = get_user_column($database_handler, $username, $mysql_users_table);

	$user_statement = $database_handler->prepare("DELETE FROM $mysql_users_table WHERE user_id = :user_id");
	$user_statement->bindValue(':user_id', $user_column['user_id'], PDO::PARAM_STR);
	$status = $user_statement->execute();
	if (!$status) {
		exit(json_encode(array('action' => 'del_user',
			'error' => 'couldn\'t delete user',
			'status' => false)));
	}

	$data_statement = $database_handler->prepare("DELETE FROM $mysql_data_table WHERE user_id = :user_id");
	$data_statement->bindValue(':user_id', $user_column['user_id']);
	$status = $data_statement->execute();
	if (!$status) {
		exit(json_encode(array('action' => 'del_user',
			'error' => 'couldn\'t delete userdata',
			'status' => false)));
	}
	exit(json_encode(array('action' => 'del_user',
		'status' => true)));
}

//change the password of a user
function change_pwd($database_handler, $username, $old_password, $password, $mysql_users_table) {
	if ($_SESSION['role'] === ROLES['ANONYMOUS']) {
		//anonymous users can't do anything
		exit(json_encode(array('action' => 'change_pwd',
			'error' => 'anonymous users can\'t change passwords',
			'status' => false)));
	}
	if (($_SESSION['role'] !== ROLES['ADMIN']) && ($_SESSION['username'] !== $username)) {
		//normal users can only change their own password
		exit(json_encode(array('action' => 'change_pwd',
			'error' => 'only admins can change another user\'s password',
			'status' => false)));
	}

	//get the info about the user which will be changed
	$user_column = get_user_column($database_handler, $username, $mysql_users_table);

	if ($_SESSION['role'] !== ROLES['ADMIN']) { //if not admin
		if (($_SESSION['user_id'] !== $user_column['user_id'])) {
			exit(json_encode(array('action' => 'change_pwd',
				'error' => 'user ids don\'t match',
				'status' => false)));
		}
		if (!password_verify($old_password, $user_column['password'])) {
			exit(json_encode(array('action' => 'change_pwd',
				'error' => 'old password isn\'t correct',
				'status' => false)));
		}
	}

	$hash = password_hash($password, PASSWORD_DEFAULT);

	//now actually change the password
	$statement = $database_handler->prepare("UPDATE $mysql_users_table SET password = :hash WHERE user_id = :user_id");
	$statement->bindValue(':hash', $hash, PDO::PARAM_STR);
	$statement->bindValue(':user_id', $user_column['user_id'], PDO::PARAM_INT);
	$status = $statement->execute();
	if (!$status) {
		exit(json_encode(array('action' => 'change_pwd',
			'error' => 'couldn\'t change password',
			'status' => false)));
	} else {
		exit(json_encode(array('action' => 'change_pwd',
			'status' => true)));
	}
}

//change the role of a user
function change_role($database_handler, $username, $new_role, $mysql_users_table) {
	if (!in_array($new_role, ROLES)) {
		exit(json_encode(array('action' => 'change_role',
			'error' => 'invalid role', 'status' => false)));
	}

	if (($_SESSION['role'] !== ROLES['ADMIN'])) {
		exit(json_encode(array('action' => 'change_role',
			'error' => 'only admins can change the role of a user',
			'status' => 'false')));
	}

	//get the info about the user which will be changed
	$user_column = get_user_column($database_handler, $username, $mysql_users_table);

	//check if the user id matches
	if (($_SESSION['role'] !== ROLES['ADMIN']) && ($_SESSION['user_id'] !== $user_column['user_id'])) {
		exit(json_encode(array('action' => 'change_role',
			'error' => 'user id doesn\'t match',
			'status' => false)));
	}

	//now actually change the role
	$statement = $database_handler->prepare("UPDATE $mysql_users_table SET role = :role WHERE user_id = :user_id");
	$statement->bindValue(':role', $new_role, PDO::PARAM_STR);
	$statement->bindValue(':user_id', $user_column['user_id'], PDO::PARAM_INT);
	$status = $statement->execute();
	if (!$status) {
		exit(json_encode(array('action' => 'change_role',
			'error' => 'couldn\'t change role',
			'status' => false)));
	} else {
		exit(json_encode(array('action' => 'change_role',
			'status' => true)));
	}
}

//write data into the database
function write_data($database_handler, $data, $username, $mysql_users_table, $mysql_data_table) {
	// REALLY DIRTY QUICKFIX for CORS-handling problem (which somehow looses the session username between login and get/write)
	$quickfix = "NO";
	if ((null == $_SESSION['username']) && ($_SESSION['role'] == ROLES['ANONYMOUS'])) {
		  $user_column = get_user_column($database_handler, $username, $mysql_users_table);
		  $user_id = $user_column['user_id'];
		  $quickfix = "YES";
	} else {
		if ($username !== $_SESSION['username'] ) {
			if ($_SESSION['role'] !== ROLES['ADMIN']) {
				exit(json_encode(array('action' => 'write_data',
					'error' => 'only admins can write another user\'s data',
					'status' => false)));
			}
			$user_column = get_user_column($database_handler, $username, $mysql_users_table);
			$user_id = $user_column['user_id'];
			if (($_SESSION['role'] !== ROLES['ADMIN']) && ($user_id !== $_SESSION['user_id'])) {
				exit(json_encode(array('action' => 'write_data',
					'error' => 'user id doesn\'t match',
					'status' => false)));
			}
		} else {
			$user_id = $_SESSION['user_id'];
		}
	}

	if ($_POST['overwrite'] !== 'true') { //merge the data if overwrite is false
	    //get the current data from the database (for later merging)
	    $statement = $database_handler->prepare("SELECT * FROM $mysql_data_table WHERE user_id = :user_id");
	    $statement->bindValue(':user_id', $user_id, PDO::PARAM_INT);
	    $statement->execute();
	    $data_column = $statement->fetch();
	    $old_data = $data_column['data'];

	    //merge the old and the new data
	    try {
		$old_data_array = json_decode($old_data, TRUE /* associative array */);
		if ($old_data_array == NULL) {
		    $old_data_array = array();
		}
		$data_array = json_decode($data, TRUE /* associative array */);
		if ($data_array == NULL) {
		    $data_array = array();
		}

		//now do the merge
		$data_array = array_replace_recursive($old_data_array, $data_array);
		if ($data_array === NULL) {
		    throw new Exception('failed to merge arrays');
		}

		//generate resulting json
		$data = json_encode($data_array);
	    } catch (Exception $e) {
		exit(json_encode(array(
		    'action' => 'write_data',
		    'quickfix' => $quickfix,
		    'error' => 'failed to parse JSON',
		    'status' => 'false'
		)));
	    }
	}

	//write data to the database
	$callstr = "REPLACE INTO $mysql_data_table (user_id, data) VALUES (:user_id, :data)";
	$statement = $database_handler->prepare($callstr);
	$statement->bindValue(':user_id', $user_id, PDO::PARAM_STR);
	$statement->bindValue(':data', $data, PDO::PARAM_STR);
	$status = $statement->execute();

	if (!$status) {
		exit(json_encode(array('action' => 'write_data',
			'quickfix' => $quickfix,
			'error' => 'couldn\'t write data',
			'status' => false)));
	}
	exit(json_encode(array('action' => 'write_data',
		'quickfix' => $quickfix,
		'status' => true)));
}

//get data from the database
function get_data($database_handler, $username, $mysql_users_table, $mysql_data_table) {
	// REALLY DIRTY QUICKFIX for CORS-handling problem (which somehow looses the session username between login and get/write)
	$quickfix = "NO";
	if ((null == $_SESSION['username']) && ($_SESSION['role'] == ROLES['ANONYMOUS'])) {
		$user_column = get_user_column($database_handler, $username, $mysql_users_table);
		$user_id = $user_column['user_id'];
		$quickfix = "YES";
	} else {
		if ($username !== $_SESSION['username']) {
			if ($_SESSION['role'] !== ROLES['ADMIN']) {
				exit(json_encode(array('action' => 'get_data',
					'session_user' => $_SESSION['username'],
					'session_role' => $_SESSION['role'],
					'attempted_user' => $username,
					'error' => 'only admins can read another user\'s data',
					'status' => false)));
			}
			$user_column = get_user_column($database_handler, $username, $mysql_users_table);
			$user_id = $user_column['user_id'];
			if (($_SESSION['role'] !== ROLES['ADMIN']) && ($user_id !== $_SESSION['user_id'])) {
				exit(json_encode(array('action' => 'get_data',
					'error' => 'user id doesn\'t match',
					'status' => false)));
			}
		} else {
			$user_id = $_SESSION['user_id'];
		}
	}

	//get data from the database
	$statement = $database_handler->prepare("SELECT * FROM $mysql_data_table WHERE user_id = :user_id");
	$statement->bindValue(':user_id', $user_id, PDO::PARAM_INT);
	$statement->execute();
	$data_column = $statement->fetch();
	exit(json_encode(array('action' => 'get_data',
		'data' => $data_column['data'],
		'quickfix' => $quickfix,
		'status' => true)));
}

//get login field from the JSON data of a user
function get_login_data($database_handler, $username, $mysql_users_table, $mysql_data_table) {
	if (($_SESSION['role'] !== ROLES['ADMIN']) && ($_SESSION['role'] !== ROLES['EVALUATION'])) {
		exit(json_encode(array('action' => 'get_login_data',
			'error' => 'only admins and evaluation have access to login data',
			'status' => false)));
	}
	$user_column = get_user_column($database_handler, $username, $mysql_users_table);

	//get data from the database
	$statement = $database_handler->prepare("SELECT * FROM $mysql_data_table WHERE user_id = :user_id");
	$statement->bindValue(':user_id', $user_column['user_id'], PDO::PARAM_STR);
	$statement->execute();
	$data_column = $statement->fetch();
	$data_object = json_decode($data_column['data'], true/*decode into array*/);
	if (isset($data_object['login'])) {
		exit(json_encode(array('action' => 'get_login_data',
			'data' => $data_object['login'],
			'status' => true)));
	}
	exit(json_encode(array('action' => 'get_login_data',
		'error' => 'login data doesn\'t exist',
		'status' => false)));
}

//get role of a specified user
function get_role($database_handler, $username, $mysql_users_table) {
	if (($username === $_SESSION['username']) || ($username == '')) {
		exit(json_encode(array('action' => 'get_role',
			'status' => true,
			'username' => $_SESSION['username'],
			'role' => $_SESSION['role'])));
	}

	if ($_SESSION['role'] !== ROLES['ADMIN']) {
		exit(json_encode(array('action' => 'get_role',
			'error' => 'only admins can get the role of other users',
			'status' => false)));
	}

	$user_column = get_user_column($database_handler, $username, $mysql_users_table);
	exit(json_encode(array('action' => 'get_role',
		'username' => $username,
		'role' => $user_column['role'],
		'status' => true)));
}

function logout() {
	if (ini_get('session.use_cookies')) {
		$cookie_params = session_get_cookie_params();
		//destroy the session cookie
		setcookie(session_name(), '', time() - 99999,
			$cookie_params['path'], $cookie_params['domain'],
			$cookie_params['secure'], $cookie_params['httponly']);
	}
	session_unset();
	session_destroy();
	exit(json_encode(array('action' => 'logout', 'status' => true)));
}
?>
