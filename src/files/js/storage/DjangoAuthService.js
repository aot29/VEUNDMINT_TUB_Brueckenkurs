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
    return Promise.resolve(
      $.ajax({
        url: 'http://localhost:8000/api-token-auth/',
        method: 'POST',
        data: JSON.stringify(user_credentials),
        dataType: 'json',
        contentType: 'application/json; charset=utf-8',
        timeout: 3000,
      })).then(function(data) {
        return storeUserCredentials(data);
    }, function(error) {
      return new TypeError(error);
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
   * Make unauthenticated GET request to url with data
   * @param  {String} url  The url to send the request to
   * @param  {Object} data The data you want to send with the request
   * @return {Object}      The returned (json) data
   */
  function ajaxGET (url, data, async) {
    return Promise.resolve(
      $.ajax({
        url: url,
        method: 'GET',
        data: data,
        dataType: 'json',
        contentType: 'application/json; charset=utf-8'
      })
    );
  }

  /**
   * Make unauthenticated POST request to url with data
   * @param  {String} url  The url to send the request to
   * @param  {Object} data The data you want to send with the request
   * @return {Object}      The returned (json) data
   */
  function ajaxPOST (url, data, async) {
    return Promise.resolve(
      $.ajax({
        url: url,
        method: 'POST',
        data: JSON.stringify(data),
        dataType: 'json',
        contentType: 'application/json; charset=utf-8'
      })
    );
  }

  function authAjaxGET (url, data, async) {
    return authAjaxRequest (url, data, async, 'GET');
  }
  function authAjaxPOST (url, data, async) {
    return authAjaxRequest (url, data, async, 'POST');
  }

  /**
  * Make authenticated request to url with data and method
  * @param  {String} url  The url to send the request to
  * @param  {Object} data The data you want to send with the request
  * @param  {Object} async Wether request should be async, default true
  * @param  {Object} method The http method of the request ('GET', 'POST', 'PUT', 'PATCH', 'DELETE');
  * @return {Object}      The returned (json) data
  */
  function authAjaxRequest (url, data, async, method) {

        async = typeof async !== 'undefined' ? async : true;

        //make POST requests default method
        method = typeof method !== 'undefined' ? method : 'POST';

        var userCredentials = getUserCredentials();
        //console.log('and user credentials is', userCredentials);
        if (userCredentials === null || typeof userCredentials === "undefined"
        || typeof userCredentials.token === "undefined" ) {
          //console.log('can only make authAjaxGET request if userCredentials are set');
          return Promise.reject(new TypeError('not authenticated'));
        }
        return Promise.resolve(
          $.ajax({
            url: url,
            method: method,
            async: async,
            data: JSON.stringify(data),
            dataType: 'json',
            contentType: 'application/json; charset=utf-8',
            headers: {
              'Authorization': 'JWT ' + userCredentials.token
            }
          })
        );
  }

  /**
   * Check django server if username is available
   * @param  {String} username A username to check
   * @return {Promise<Boolean>} A promise resolving to true or false
   */
  function usernameAvailable(username) {
    return ajaxGET('http://localhost:8000/checkusername/', {username:username});
  }

  /**
   * Register a new user at django server
   * @param  {Object} userCredentials json object with required fields
   * @return {Promise<Object>} Resolves with user data, rejects with validation errors
   */
  function registerUser(userCredentials) {
    return ajaxPOST('http://localhost:8000/rest-auth/registration/', userCredentials).then(function (successData) {
      //if successfully registered
      return storeUserCredentials(successData);
    });
  }

  /**
   * Change the userdata of a registered user
   * @param  {Object} userData the changed user data
   * @return {Promise<Object>} resolves with the changed user data
   */
  function changeUserData(userData) {
    return authAjaxRequest('http://localhost:8000/rest-auth/user/', userData, true, 'PUT');
  }

  /**
   * Store the user credentials in localStorage
   * @return {[type]} [description]
   */
  function storeUserCredentials(userCredentials) {
    if (typeof userCredentials.token !== undefined) {
      isAuthenticated = true;

      //never store a password
      delete(userCredentials.password);
      //never store the primary key
      if (userCredentials.user && userCredentials.user.pk) {
        delete(userCredentials.user.pk);
      }

      localStorage.setItem(USER_CREDENTIALS_KEY, JSON.stringify(userCredentials));
    }
    return userCredentials;
  }


  exports.initJquery = initJquery;
  exports.authenticate = authenticate;
  exports.logout = logout;
  exports.getUserCredentials = getUserCredentials;
  exports.authAjaxRequest = authAjaxRequest;
  exports.authAjaxGet = authAjaxGET;
  exports.authAjaxPost = authAjaxPOST;
  exports.isAuthenticated = isUserAuthenticated;
  exports.getToken = function() {return userCredentials.token || null};
  exports.usernameAvailable = usernameAvailable;
  exports.registerUser = registerUser;
  exports.changeUserData = changeUserData;

}));
