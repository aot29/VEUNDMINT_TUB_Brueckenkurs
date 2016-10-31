(function (root, factory) {
  /* istanbul ignore next */
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'IStorageService', 'veHelpers', 'jQuery'], function (exports, IStorageService, veHelpers, $) {
      factory((root.DjangoAuthService = exports), IStorageService, veHelpers, jQuery);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports, require('./IStorageService.js'), require('../veHelpers.js'), require('jQuery'));
  } else {
    // Browser globals
    factory((root.DjangoAuthService = {}), root.IStorageService, root.veHelpers, root.$);
  }
}(this, function (exports, IStorageService, veHelpers, $) {

  var USER_CREDENTIALS_KEY = 've_user_credentials';
  var userCredentials = {};
  var isAuthenticated = false;

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
    //console.log('DjangoAuthService.authenticate called with:', user_credentials);
   return $.ajax({
      url: 'http://localhost:8000/api-token-auth/',
      method: 'POST',
      data: user_credentials,
      dataType: 'json',
      headers: {
        'Authorization': 'JWT ' + userCredentials.token
      },
      timeout: 3000,
    }).then(function(data) {
      if (typeof data.token !== undefined) {
        isAuthenticated = true;
        delete(user_credentials.password);
        userCredentials = user_credentials;
        userCredentials.token = data.token;
        //console.log('isAuthenticated set to true');
      }
      return data;
    }, function(error) {
      return 'there was an error authenticating at django';
    });
  }

  /**
   * Logs the user out, by deleting their token and user credentials
   * @return {Boolean} true if successful logout, false otherwise
   */
  function logout() {
    userCredentials = {};
    isAuthenticated = false;
  }

  /**
  * Get the user credentials from local variable. If not set, get it from local
  * Storage and set it and return it
  * @return {object or null} the user credentials object or null
  */
  function getUserCredentials () {
    if (typeof userCredentials !== "undefined" && userCredentials !== null) {
      return userCredentials;
    }
    //console.log('can only call getUserCredentials if user is authenticated')
    return null;
  }

  /**
  * Make authenticated GET request to url with data
  * @param  {String} url  The url to send the request to
  * @param  {Object} data The data you want to send with the request
  * @return {Object}      The returned (json) data
  */
  function authAjaxGET (url, data) {
    //console.log('calling authajax get with url', url);
    var userCredentials = getUserCredentials();
    //console.log('and user credentials is', userCredentials);
    if (userCredentials === null || typeof userCredentials === "undefined"
    || typeof userCredentials.token === "undefined" ) {
      //console.log('can only make authAjaxGET request if userCredentials are set');
      return Promise.reject('notAuthenticated');
    }

    return $.ajax({
      url: url,
      method: 'GET',
      dataType: 'json',
      headers: {
        'Authorization': 'JWT ' + userCredentials.token
      }
    });

    //we use jquery instead now
    // return rp.get({
    //   uri: url,
    //   headers: {
    //     'Authorization': 'JWT ' + userCredentials.token
    //   },
    //   json: true
    // });
  }

  /**
  * Make authenticated POST request to url with data
  * @param  {String} url  The url to send the request to
  * @param  {Object} data The data you want to send with the request
  * @return {Object}      The returned (json) data
  */
  function authAjaxPOST (url, data) {
    //console.log('calling authajax get with url', url);
    var userCredentials = getUserCredentials();
    //console.log('and user credentials is', userCredentials);
    if (userCredentials === null || typeof userCredentials === "undefined"
    || typeof userCredentials.token === "undefined" ) {
      //console.log('can only make authAjaxGET request if userCredentials are set');
      return Promise.reject('notAuthenticated');
    }

    return $.ajax({
      url: url,
      method: 'POST',
      data: JSON.stringify(data),
      datatype: 'json',
      contentType: 'application/json; charset=utf-8',
      headers: {
        'Authorization': 'JWT ' + userCredentials.token
      }
    });

    // return rp.post({
    //   url: url,
    //   body: data,
    //   headers: {
    //     'Authorization': 'JWT ' + userCredentials.token
    //   },
    //   json: true
    // });
  }

  exports.authenticate = authenticate;
  exports.logout = logout;
  exports.getUserCredentials = getUserCredentials;
  exports.authAjaxGet = authAjaxGET;
  exports.authAjaxPost = authAjaxPOST;
  exports.isAuthenticated = function(){return isAuthenticated};
  exports.getToken = function() {return userCredentials.token || null};


}));
