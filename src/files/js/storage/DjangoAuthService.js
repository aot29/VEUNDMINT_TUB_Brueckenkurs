(function (root, factory) {
  /* istanbul ignore next */
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'IStorageService', 'veHelpers', 'jquery', 'bluebird'], function (exports, IStorageService, veHelpers, $, bluebird) {
      factory((root.DjangoAuthService = exports), IStorageService, veHelpers, jQuery, bluebird);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports, require('./IStorageService.js'), require('../veHelpers.js'), require('jquery'), require('bluebird'));
  } else {
    // Browser globals
    factory((root.DjangoAuthService = {}), root.IStorageService, root.veHelpers, root.$, root.Promise);
  }
}(this, function (exports, IStorageService, veHelpers, $, Promise) {

  var USER_CREDENTIALS_KEY = 've_user_credentials';
  var userCredentials = {};
  var isAuthenticated = false;

  var doAsyncCalls = true;

  function initJquery(jqueryRef) {
	  $ = jqueryRef;
  }

  /**
  * Get the user credentials from local variable. If not set, get it from local
  * Storage and set it and return it
  * @return {object or null} the user credentials object or null
  */
  function getUserCredentials () {
    if (typeof userCredentials !== "undefined" && userCredentials !== null && !veHelpers.isEmpty(userCredentials)) {
		isAuthenticated = true;
      return userCredentials;
    } else {
      var lsUserCred = localStorage.getItem(USER_CREDENTIALS_KEY);
      if (lsUserCred !== null) {
		isAuthenticated = true;
        return JSON.parse(lsUserCred);
      }
    }
    //log.debug('can only call getUserCredentials if user is authenticated')
    return null;
  }

	/**
	 * Check if user is authenticated. If yes, userCredentials will also be available
	 * @return {Boolean} true if yes, false if not.
	 */
	function isUserAuthenticated() {
		var userCredentials = getUserCredentials();
		if (userCredentials !== null) {
			isAuthenticated = true;
		}
		return isAuthenticated;
	}

  /**
  * Authenticates at the server (settings.apiAuthUrl) with the given user credentials object
  * that should contain a 'username' and a 'password'
  * @param  {Object}   user_credentials A javascript object that contains
  * a username and a password like {username: 'username', password: 'password'}
  * @param  {Function} callback callback function will be called with results from server that will
  * either contain an error or a token {token: 'the auth token'}
  * @return {Promise}           Returns a promise with the data object
  */
  function authenticate (user_credentials) {
	 //console.log('calling authenticate with', user_credentials);
   return new Promise(function(resolve, reject) {
     return $.ajax({
        url: 'http://localhost:8000/api-token-auth/',
        method: 'POST',
        data: JSON.stringify(user_credentials),
        dataType: 'json',
      contentType: 'application/json; charset=utf-8',
        timeout: 3000,
      }).done(resolve).fail(reject);
   }).then(function(data) {
      if (typeof data.token !== undefined) {
        isAuthenticated = true;
        delete(user_credentials.password);
        userCredentials = user_credentials;
        userCredentials.token = data.token;

		localStorage.setItem(USER_CREDENTIALS_KEY, JSON.stringify(userCredentials));
        //console.log('isAuthenticated set to true');
      }
      return data;
    }, function(error) {
      return error;
    });
  }

  /**
   * Logs the user out, by deleting their token and user credentials
   * @return {Boolean} true if successful logout, false otherwise
   */
  function logout() {
    userCredentials = {};
    localStorage.removeItem(USER_CREDENTIALS_KEY);
    isAuthenticated = false;
  }

  /**
  * Make authenticated GET request to url with data
  * @param  {String} url  The url to send the request to
  * @param  {Object} data The data you want to send with the request
  * @return {Object}      The returned (json) data
  */
  function authAjaxGET (url, data, async) {
    //console.log('calling authajax get with url', url);
    var userCredentials = getUserCredentials();
    //console.log('and user credentials is', userCredentials);
    if (userCredentials === null || typeof userCredentials === "undefined"
    || typeof userCredentials.token === "undefined" ) {
      //console.log('can only make authAjaxGET request if userCredentials are set');
      return Promise.reject('not authenticated');
    }

    return Promise.resolve(
      $.ajax({
        url: url,
        method: 'GET',
        dataType: 'json',
        contentType: 'application/json; charset=utf-8',
        headers: {
          'Authorization': 'JWT ' + userCredentials.token
        }
      })
    );
  }

  /**
  * Make authenticated POST request to url with data
  * @param  {String} url  The url to send the request to
  * @param  {Object} data The data you want to send with the request
  * @return {Object}      The returned (json) data
  */
  function authAjaxPOST (url, data, async) {

    console.log('calling authajax get with url', url, 'data', data, 'async', async);

    async = typeof async !== 'undefined' ? async : true;

    var userCredentials = getUserCredentials();
    //console.log('and user credentials is', userCredentials);
    if (userCredentials === null || typeof userCredentials === "undefined"
    || typeof userCredentials.token === "undefined" ) {
      //console.log('can only make authAjaxGET request if userCredentials are set');
      return Promise.reject('not authenticated');
    }
    return Promise.resolve(
      $.ajax({
        url: url,
        method: 'POST',
        async: async,
        data: JSON.stringify(data),
        dataType: 'json',
        contentType: 'application/json; charset=utf-8',
        headers: {
          'Authorization': 'JWT ' + userCredentials.token
        }
      })
    );


    // return rp.post({
    //   url: url,
    //   body: data,
    //   headers: {
    //     'Authorization': 'JWT ' + userCredentials.token
    //   },
    //   json: true
    // });
  }


  exports.initJquery = initJquery;
  exports.authenticate = authenticate;
  exports.logout = logout;
  exports.getUserCredentials = getUserCredentials;
  exports.authAjaxGet = authAjaxGET;
  exports.authAjaxPost = authAjaxPOST;
  exports.isAuthenticated = isUserAuthenticated;
  exports.getToken = function() {return userCredentials.token || null};


}));
