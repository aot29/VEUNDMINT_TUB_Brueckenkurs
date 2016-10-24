(function (root, factory) {
  /* istanbul ignore next */
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'IStorageService', 'veHelpers', 'request', 'request-promise'], function (exports, IStorageService, veHelpers, request, rp) {
      factory((root.DjangoStorageService = exports), IStorageService, veHelpers, request, rp);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports, require('./IStorageService.js'), require('../veHelpers.js'), require('request'), require('request-promise'));
  } else {
    // Browser globals
    factory((root.DjangoStorageService = {}), root.IStorageService, root.veHelpers, root.request, root.rp);
  }
}(this, function (exports, IStorageService, veHelpers, request, rp) {

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
    return rp.post({
      url: 'http://localhost:8000/api-token-auth/',
      body: user_credentials,
      json: true
    }).then(function(data) {

      if (typeof data.token !== undefined) {
        isAuthenticated = true;
        delete(user_credentials.password);
        userCredentials = user_credentials;
        userCredentials.token = data.token;
        //console.log('isAuthenticated set to true');
      }
      return data;
    });
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
      return;
    }
    return rp.get({
      uri: url,
      headers: {
        'Authorization': 'JWT ' + userCredentials.token
      },
      json: true
    });
  }
  exports.authenticate = authenticate;
  exports.getUserCredentials = getUserCredentials;
  exports.authAjaxGet = authAjaxGET;
  exports.isAuthenticated = function(){return isAuthenticated};
  exports.getToken = function() {return userCredentials.token || null};

}));
