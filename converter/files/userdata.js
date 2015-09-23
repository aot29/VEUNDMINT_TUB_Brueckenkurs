//client side module for accessing the user management API on the server

//define this here until it is defined elsewhere, this should be removed later
if (typeof dataserver !== 'string') {
    dataserver = 'http://mintlx3.scc.kit.edu/dbtest';
}
logMessage(DEBUGINFO, "Benutzer dataserver = " + dataserver);

var userdata = (function (baseURL) {
    var exports = {};

    var url = baseURL + '/userdata.php';

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

	
	// Der folgende Code generiert SHA1-Warnungen sowie Crossover-policy violations trotz SSL und AllowOrigin = * von apache2,
	// ersetzt durch credential-free call, der aber die Session verliert, was zu dirty quickfix in authentication.php fuehrt (nur get/write)
//         $.ajax( url, {
//             type: type,
//             async: true,
//             cache: false,
//             contentType: 'application/x-www-form-urlencoded',
//             xhrFields: {
//                 withCredentials: true
//             },
//             headers: { 'Access-Control-Allow-Origin': '*' },
//             crossDomain: true,
//             data: data,
//             error: errorCallback,
//             success: successCallback,
//         });
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
     * The third argument is optional ( can be undefined )
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
     * The first argument is optional ( can be undefined )
     **/
    exports.writeData = function (async, username, data, success, error) {
        sendRequest(async, 'POST', {action: 'write_data', username: username, data: data},
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
     * The first argument is optional ( can be undefined )
     **/
    exports.getRole = function (async, username, success, error) {
        sendRequest(async, 'GET', {action: 'get_role', username: username},
                createSuccessCallback(success, error), createErrorCallback(error));
    };

    /**
     * Get the data of the current user
     *
     * The first argument is optional ( can be undefined )
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
    exports.delUser = function (async, username, success, error) {
        sendRequest(async, 'POST', {action: 'del_user', username: username},
                createSuccessCallback(success, error), createErrorCallback(error));
    };

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

    return exports;
})(dataserver);
