/* from https://github.com/umdjs/umd/blob/master/templates/commonjsStrictGlobal.js */

(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'helpers'], function (exports, helpers) {
      factory((root.newserver = exports), helpers);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports, require('helpers'));
  } else {
    // Browser globals
    factory((root.newserver = {}), root.helpers);
  }
}(this, function (exports, helpers) {

  //
  // Variables
  //
  var settings;

  // Default settings
  var defaults = {
    apiUrl: 'http://localhost:8000/',
    apiAuthUrl: 'http://localhost:8000/api-token-auth/',
    apiProfileUrl: 'http://localhost:8000/profile/',
    apiWebsiteActionUrl: 'http://localhost:8000/server-action/',
    apiScoresUrl: 'http://localhost:8000/score/',
    defaultLogLevel: 'debug'
  };

  defaults.apiUsernameAvailable = defaults.apiUrl + 'checkusername/'

  var USER_CREDENTIALS_KEY = 've_user_credentials';
  var SCORES_KEY = 've_scores'

  var syncToCacheKeys = [USER_CREDENTIALS_KEY, SCORES_KEY];

  var isLoggedIn = false;

  //wether API calls should be asynchronous. Default true.
  var asyncCalls = true;

  //we keep an object cache that will serve data when on the same page
  //it is synced on page load from localstorage. See syncToCacheKeys and buildObjCache.
  var objCache = {};

  log.info('newserver.js loaded');

  //init();

  /**
  * will load existing scores from the passed intersiteObj, as we can see this class
  * depends on intersite (by now), this dependency is only because of persistence reasons now
  * and shall be removed in further iterations
  * @return {[type]} [description]
  */
  function init( options ) {
    log.info('newserver init called with options', options);
    // Merge user options with defaults
    settings = $.extend( defaults, options || {} );
    authenticate({
      username: 'testrunner',
      password:'<>87c`}X&c8)2]Ja6E2cLD%yr]*A$^3E'
    });

    /*
      on init: localStorage -> objCache
      on unload: objCache -> localStorage
     */
    buildObjCache();
    $(window).on('beforeunload', function() {
    	persist();
    });
  }

  /**
  * Get the user credentials from local variable. If not set, get it from local
  * Storage and set it and return it
  * @return {object or null} the user credentials object or null
  */
  function getUserCredentials () {
    if (typeof objCache.userCredentials !== "undefined" && objCache.userCredentials !== null) {
      return objCache.userCredentials;
    } else {
      var lsUserCred = localStorage.getItem(USER_CREDENTIALS_KEY);
      if (lsUserCred !== null) {
        return JSON.parse(lsUserCred);
      }
    }
    log.debug('can only call getUserCredentials if user is authenticated')
    return null;
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Server Services - call external API for retrieving data
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  function getServerScores() {
    log.info('newserver getServerScores() called');
    return authAjaxGET(settings.apiScoresUrl, {});
  }

  /**
  * Sets all scores on the server / in localstorage / in obj cache
  * @param {Array[Object]} data The array of score objects
  */
  function setServerScores(data) {
    log.info('newserver setScores() called with', data);
    return authAjaxPOST(settings.apiProfileUrl, {scores: data});
  }

  // Call /checkusername/?username=<username> at the server and return
  function usernameAvailable(username) {
	  return authAjaxGET(settings.apiUsernameAvailable, {username: username}).then(function (data) {
		  return data.username_available;
	  }
	);
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Data Services - Call gracefullyGet = look in cache, localstorage and server
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  /**
  * Get the scores array from local variable. If not set, get it from localstorage,
  * if not set, get it from server, and set localstorage as well as local variable
  * @return {[type]} [description]
  */
  function getScores() {
    return gracefullyGet(SCORES_KEY, getServerScores);
  }
  function setScores(data) {
    return gracefullySet(SCORES_KEY, data, setServerScores);
  }
  /**
  * TODO scores should really be saved in a hashmap rather than array
  * @param {[type]} singleScore [description]
  */
  function setScore(singleScore) {
    return updateInArray(SCORES_KEY, singleScore, setServerScores);
  }

  //TODO could be moved to own authService.js as well as the getUserCredentials method above
  /**
  * Authenticates at the server (settings.apiAuthUrl) with the given user credentials object
  * that should contain a 'username' and a 'password'
  * @param  {[type]}   user_credentials A javascript object that contains
  * a username and a password like {username: 'username', password: 'password'}
  * @param  {Function} callback callback function will be called with results from server that will
  * either contain an error or a token {token: 'the auth token'}
  * @return {Promise}           Returns a promise with the data object
  */
  function authenticate (user_credentials, callback) {
    log.debug('newserver.authenticate called with:', user_credentials);
    return $.ajax({
      type: "POST",
      url: settings.apiAuthUrl,
      data: user_credentials,
      success: function (data) {
        delete(user_credentials.password);
        $.extend(user_credentials, data);

        //user credentials will have the form {username: <name>, token: <token>}
        localStorage.setItem(USER_CREDENTIALS_KEY, JSON.stringify(user_credentials));
      },
      error: function (data) {
        log.warn('newserver.authenticate failed somehow:', data);
      }
    });
  }

  //this function authenticates a moodle user at the server and might also
  function authenticateMoodle() {
	if (scormBridge.isScormEnv()) {
		var username = scormBridge.getStudentName;
		var userid = scormBridge.getStudentId;
	}
  }

  /**
  * Make authenticated GET request to url with data
  * @param  {String} url  The url to send the request to
  * @param  {Object} data The data you want to send with the request
  * @return {Object}      The returned (json) data
  */
  function authAjaxGET (url, data) {
    var userCredentials = getUserCredentials();
    if (userCredentials === null || typeof userCredentials === "undefined"
    || typeof userCredentials.token === "undefined" ) {
      log.debug('can only make authAjaxGET request if userCredentials are set');
      return;
    }
    return $.ajax({
      type: "GET",
      dataType: 'json',
      url: url,
      async: asyncCalls,
      data: data,
      headers: {
        'Authorization': 'JWT ' + userCredentials.token
      }
    });
  }

  /**
  * Make (unauthenticated) GET request to url with data
  * @param  {String} url  The url to send the request to
  * @param  {Object} data The data you want to send with the request
  * @return {Object}      The returned (json) data
  */
  function ajaxGET (url, data) {
    return $.ajax({
      type: "GET",
      dataType: 'json',
      url: url,
      async: asyncCalls,
      data: data
    });
  }

  /**
  * Make authenticated POST request to url with data
  * @param  {String} url  The url to send the request to
  * @param  {Object} data The data you want to send with the request
  * @return {Object}      The returned (json) data
  */
  function authAjaxPOST (url, data) {
    var userCredentials = getUserCredentials();
    if (userCredentials === null || typeof userCredentials === "undefined"
    || typeof userCredentials.token === "undefined" ) {
      log.debug('can only make authAjaxGET request if userCredentials are set');
      return;
    }
    return $.ajax({
      type: "POST",
      dataType: 'json',
      async: asyncCalls,
      url: url,
      data: JSON.stringify(data),
      contentType: "application/json; charset=utf-8",
      headers: {
        'Authorization': 'JWT ' + userCredentials.token
      }
    });
  }

  /**
  * Get a variable from different sources: 1.cache then 2.localStorage
  * 3. serviceFunction. Also save variable to previous steps if they were not
  * available.
  * @param  {String} variableName    Will be used as a key to get from cache or
  * localstorage. Will be saved to this key as well.
  * @param  {function} serviceFunction Function that will be called to recieve variable
  * from the server, in case it is not found in cache / localstorage. Must return a promise
  * @return {Object}                 Any Object requested
  */
  function gracefullyGet (variableName, serviceFunction) {
    var res = new Promise(function (resolve, reject) {
      if (typeof objCache[variableName] !== "undefined" && objCache[variableName] !== null) {
        log.debug('newserver gracefullyGet: ', variableName, ' from objCache with value:', objCache[variableName]);
        resolve(objCache[variableName]);
      } else {
        var lsValue = localStorage.getItem(variableName);
        if (lsValue !== null) {
          objCache[variableName] = JSON.parse(lsValue);
          log.debug('newserver gracefullyGet: ', variableName, ' from localstorage with value:', objCache[variableName]);
          resolve(objCache[variableName]);
        } else {
          if (typeof serviceFunction === "function") {
            serviceFunction().then(function(data) {
              objCache[variableName] = data;
              localStorage.setItem(variableName, JSON.stringify(data));
              log.debug('newserver gracefullyGet: ', variableName, ' from service with value:', data);
              resolve(data);
            });
          } else {
            reject('Obj not found in cache or localstorage and there was no serviceFunction supplied', variableName);
          }
        }
      }
    });
    return res;
  }

  function gracefullySet(variableName, data, serviceFunction, sync) {
    var status = {
      objCache: false,
      localStorage: false,
      API: false
    };

    if (typeof sync === "undefined") {
      sync = false;
    }

    var res = new Promise(function (resolve, reject) {
      objCache[variableName] = data;
      status.objCache = true;
      localStorage.setItem(variableName, JSON.stringify(data));
      status.localStorage = true;
      if (typeof serviceFunction === "function") {
        serviceFunction(data).then(function(data) {
          status.API = true;
          resolve(status);
        }, function(error) {
          resolve(status);
        });
      } else {
        resolve(status);
      }

    });
    return res;
  }

  /**
   * Update a single object that is found in an array. Will also call the
   * serviceFunction to try to update it on the server
   * @param  {String} variableName    The key of the array in objCache and ls
   * @param  {Object} data            The data to save
   * @param  {Function} serviceFunction A call to an API that will be executed with
   * data as a parameter
   * @param  {String} comparator      The key of the data, from which obj equality
   * is determined (= should be unique)
   * @return {Promise}                A promise from the serviceFunction
   */
  function updateInArray(variableName, data, serviceFunction, comparator) {

    //TODO this will work for scores now and should be refactored anyway
    comparator = typeof comparator !== 'undefined' ? comparator : 'id';

    if (typeof objCache[variableName] === "undefined"
    || objCache[variableName] == ""
    || objCache[variableName] == null) {
      objCache[variableName] = [];
    }

    var foundIdx = veHelpers.findInArray(objCache[variableName], data, comparator);
    log.debug('newserver updateInArray found item by ', data[comparator], 'at ', foundIdx);

    //update the item if its found, else add the item
    if (foundIdx !== -1) {
      objCache[variableName][foundIdx] = data;
    } else {
      objCache[variableName].push(data);
    }

    log.debug('new objectCache is', objCache);

    if (typeof serviceFunction === "function") {
      //also update on server
      return serviceFunction([data]);
    }

  }

  /**
   * Persist objCache to localStorage and server
   * @return {[type]} [description]
   */
  function persist() {
    for (var key in objCache) {
      localStorage.setItem(key, JSON.stringify(objCache[key]));
      log.debug('persisted key', key, 'value', objCache[key]);
    }
  }

  function getObjCache() {
    return objCache;
  }

  function buildObjCache() {
    for (var i = 0; i < syncToCacheKeys.length; i++) {
      lsItem = localStorage.getItem(syncToCacheKeys[i]);
      if (lsItem !== null) {
        objCache[syncToCacheKeys[i]] = JSON.parse(lsItem);
      }
    }
  }

  /**
   * Sets the asyncCalls variable to false, which is used by all API functions.
   * Should be set to false on page unload,
   * otherwise things will fail, when making async requests and then unloading
   */
  function makeSynchronous () {
    asyncCalls = false;
  }

  // attach properties to the exports object to define
  // the exported module properties.
  exports.init = init;
  exports.authenticate = authenticate;

  exports.getServerScores = getServerScores;
  exports.setServerScores = setServerScores;
  exports.usernameAvailable = usernameAvailable;

  exports.getScores = getScores;
  exports.setScores = setScores;
  exports.setScore = setScore;


  //data service functions
  exports.authAjaxGET = authAjaxGET;
  exports.authAjaxPOST = authAjaxPOST;
  exports.getUserCredentials = getUserCredentials;
  exports.gracefullyGet = gracefullyGet;
  exports.getObjCache = getObjCache;

  exports.makeSynchronous = makeSynchronous;
}));
