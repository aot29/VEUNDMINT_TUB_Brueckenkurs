/*
 * client side module for accessing the user management API on the server
 *
 * Copyright (C) 2015 KIT (www.kit.edu), Author: Max Bruckner (FSMaxB)
 *
 *  This file is part of the VE&MINT program compilation
 *  (see www.ve-und-mint.de).
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 3 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 * */

var userdata = (function (serviceURL) {
    var exports = {};
    var url = serviceURL;

    logMessage(DEBUGINFO, "Benutzer dataserver " + data_server_description + " bei " + url);
    if (url == "") {
      logMessage(CLIENTERROR, "Kein dataserver deklariert!");
    }

    /**
     * PRIVATE FUNCTION
     * Create a success callback for jquery's ajax requests.
     *
     * success: Callback from the user that's called
     *  when the request was successful and the api call was
     *  sucessful
     *      success(data);
     * error: Callback from the user that's called when
     *  the request failed or if the api call wasn't successful
     *      error(errorMessage, data/exception);
     **/
    function createSuccessCallback(success, error) {
        return function (data, status) {
            if (typeof(data) == "string") {
                data = JSON.parse(data);
            } else {
                if (typeof(data) == "object") {
                    logMessage(DEBUGINFO, "createSuccessCallback: data is already an object (NOT OK)");
                } else {
                    logMessage(DEBUGINFO, "createSuccessCallback: data is not a valid type (NOT OK)");
                    data = { status: false, error: "invalid data object" };
                }
            }

            if (data.status === true) { //API call was successful --> call success callback
                return success(data);
            }
            return error(data.error, data); //API call failed --> call error callback
        };
    }

    /**
     * PRIVATE FUNCTION
     * Create an error callback for jquery's ajax requests
     *
     * error: Callback from the user that's called when
     *  the request failed or if the api call wasn't successful
     *      error(errorMessage, data/exception);
     **/
    function createErrorCallback(error) {
        return function (jqXHR, errorMessage, exception) {
            return error(errorMessage, exception);
        };
    }

    /**
     * PRIVATE FUNCTION
     * Sends a CORS request to a server
     *
     * type: type of the request (GET, POST)
     * data: object containing the data that should be sent
     * successCallback
     * errorCallback
     **/
    function sendRequest(async, type, data, successCallback, errorCallback) {
// vereinfachte Version ohne credentials
        logMessage(VERBOSEINFO, "userdata.sendRequest called, url = " + url + ", type = " + type + ", data = " + JSON.stringify(data));
	if (forceOffline == 1) {
	    logMessage(VERBOSEINFO, "sendRequest omitted, course is in offline mode");
	}
        $.ajax( url, {
		type: type,
		async: async,
		cache: false,
		contentType: 'application/x-www-form-urlencoded',
		crossDomain: true,
		data: data,
		//dataType: 'html', //Erwarteter Datentyp der Antwort
		error: errorCallback,
		success: successCallback
		//statusCode: {}, //Liste von Handlern fuer verschiedene HTTP status codes
		//timout: 1000,	//Timeout in ms
	});
    }

    /**
     * Check if a given user exists
     **/
    exports.checkUser = function (async, username, success, error) {
        sendRequest(async, 'GET', {action: 'check_user', username: username},
                createSuccessCallback(success, error), createErrorCallback(error));
    };

    /**
     * Add user
     *
     * The 'role' argument is optional ( can be undefined )
     **/
    exports.addUser = function (async, username, password, role, success, error) {
        role = (role == '') ? undefined : role; //use undefined if role is an empty string
        sendRequest(async, 'POST', {action: 'add_user', username: username, password: password, role: role},
                createSuccessCallback(success, error), createErrorCallback(error));
    };

    /**
     * Log in
     **/
    exports.login = function (async, username, password, success, error) {
        sendRequest(async, 'POST', {action: 'login', username: username, password: password},
                createSuccessCallback(success, error), createErrorCallback(error));
    };

    /**
     * Log out
     **/
    exports.logout = function (async, success, error) {
        sendRequest(async, 'POST', {action: 'logout'},
                createSuccessCallback(success, error), createErrorCallback(error));
    };

    /**
     * Write data
     *
     * The 'username' argument is optional ( can be undefined )
     **/
    exports.writeData = function (async, username, data, overwrite, success, error) {
        if (overwrite == true) {
            overwrite = 'true';
        }
        sendRequest(async, 'POST', {action: 'write_data', username: username, data: data, overwrite: overwrite},
                createSuccessCallback(success, error), createErrorCallback(error));
    };

    /**
     * Get the name of the currently logged in user
     **/
    exports.getUsername = function (async, success, error) {
        sendRequest(async, 'GET', {action: 'get_username'},
                createSuccessCallback(success, error), createErrorCallback(error));
    };

    /**
     * Get the role of the currently logged in user
     *
     * The 'username' argument is optional ( can be undefined )
     **/
    exports.getRole = function (async, username, success, error) {
        sendRequest(async, 'GET', {action: 'get_role', username: username},
                createSuccessCallback(success, error), createErrorCallback(error));
    };

    /**
     * Get the data of the current user
     *
     * The 'username' argument is optional ( can be undefined )
     **/
    exports.getData = function (async, username, success, error) {
        sendRequest(async, 'GET', {action: 'get_data', username: username},
                createSuccessCallback(success, error), createErrorCallback(error));
    };

    /**
     * Get login data for a user
     **/
    exports.getLoginData = function (async, username, success, error) {
        sendRequest(async, 'GET', {action: 'get_login_data', username: username},
                createSuccessCallback(success, error), createErrorCallback(error));
    };

    /**
     * Delete a user
     **/
    exports.delUser = function (async, username, password, success, error) {
        sendRequest(async, 'POST', {action: 'del_user', username: username, password: password},
                createSuccessCallback(success, error), createErrorCallback(error));
    };

    /**
     * deletes the user in local storage and on the server
     * @return {[type]} [description]
     */
    exports.deleteAllUserData = function () {

      if (exports.isLoggedIn()) {
        //first delete the user on the server
        var intersiteObj = intersite.getObj();
        var loginData = intersiteObj.login;
        exports.delUser(true, loginData.username, loginData.password, function (success) {
          //user deletion success on server, continue locally
          localStorage.clear();
          console.log( "Logout requested");
          //a hack for overwriting intersite obj = logout
          intersite.init();
          window.location.href="index.html";
        }, function(error) {
          console.log("userdata deletion failed on the server, quitting");
        });
      } else {
        console.log("we can only delete our user if we are logged in");
      }
    }

    /**
     * Change the password of a user
     **/
    exports.changePwd = function (async, username, oldPassword, newPassword, success, error) {
        sendRequest(async, 'POST', {action: 'change_pwd', username: username, old_password: oldPassword, password: newPassword},
                createSuccessCallback(success, error), createErrorCallback(error));
    };

    /**
     * Change the role of a user
     **/
    exports.changeRole = function (async, username, role, success, error) {
        sendRequest(async, 'POST', {action: 'change_role', username: username, role: role},
                createSuccessCallback(success, error), createErrorCallback(error));
    };

    exports.setURL = function (baseURL) {
        url = baseURL + '/userdata.php';
    };

    exports.isLoggedIn = function () {
      if (typeof intersite !== undefined &&
        typeof intersite.getObj() !== undefined &&
        typeof intersite.getObj().login !== undefined) {
          return intersite.getObj().login.type !== 0;
      } else {
        return false;
      }
    }

    return exports;
})(data_server_user);
