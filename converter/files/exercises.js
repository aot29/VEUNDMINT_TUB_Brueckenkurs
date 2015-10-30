/*
 * client side module for accessing the exercise database
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

//define this here until it is defined elsewhere, this should be removed later
if (typeof exerciseserver !== 'string') {
    exerciseserver = 'http://localhost/mint/server/exercises';
}
logMessage(DEBUGINFO, "exerciseserver = " + exerciseserver);

var exercises = (function (baseURL) {
    var exports = {};

    var url = baseURL + '/get.php';

    //TODO this is all copied from userdata.js, some common infrastructure would be nice
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

    /*
     * Get an exercise collection from a collection id.
     *
     * id: collection id
     * success: success callback
     *      function (data)
     * error: error callback
     *      function (errorMessage, data)
     *
     * See more about how the data is formatted in server/exercises/Dokumentation.md
     **/
    exports.getCollection = function (id, success, error) {
        $.ajax( url, {
            type: 'GET',
            async: true,
            cache: false,
            contentType: 'application/x-www-form-urlencoded',
            xhrFields: {
                withCredentials: true
            },
            crossDomain: true,
            data: {id: id},
            error: createErrorCallback(error),
            success: createSuccessCallback(success, error)
        });
    };

    exports.setURL = function (baseURL) {
        url = baseURL + '/get.php';
    };

    return exports;
})(exerciseserver);
