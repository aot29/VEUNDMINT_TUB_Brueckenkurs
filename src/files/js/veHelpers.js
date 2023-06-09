(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'loglevel', 'XMLHttpRequest'], function (exports, log, XMLHttpRequest) {
      factory((root.veHelpers = exports), log);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports, require('loglevel'), require("xmlhttprequest").XMLHttpRequest);
  } else {
    // Browser globals
    factory((root.veHelpers = {}), root.log, root.XMLHttpRequest);
  }
}(this, function (exports, log, XMLHttpRequest) {

  log.info('veHelpers.js loaded');

  /*
  * Module veHelpers
  *
  * Define helper functions that are needed by other moduless.
  *
  * USAGE:
  * Do not put methods here that depend on other js modules. This file is
  * loaded in the very beginning, and therefore calls to other modules will
  * fail as they will not be loaded by then. Exception: $.i18 will be available
  *
  */

  /**
  * Convert a timestamp to some other format
  * e.g. 1472046906162 -> "24.08.2016 - 13:55:02"
  * @param  {Object} stamp the result of Date.now() e.g.
  * @return {String}       A formated Date string
  */
  function convertTimestamp(stamp) {
    date = new Date(stamp),
    d = [
      date.getUTCFullYear(),
      date.getUTCMonth()+1,
      date.getUTCDate(),
      date.getUTCHours(),
      date.getUTCMinutes(),
      date.getUTCSeconds(),
    ];

    for (j = 0; j < d.length; j++) {
      d[j] = "" + d[j];
      if (d[j].length == 1) d[j] = "0" + d[j];
    }

    return d[2] + "." + d[1] + "." + d[0] + " - " + d[3] + ":" + d[4] + ":" + d[5];
  }

  /**
  * Compare two objects to create a diff, for debugging
  * and testing, should be moved to helper class
  * @param  {[type]} obj1 [description]
  * @param  {[type]} obj2 [description]
  * @return {[type]}      [description]
  */
  function compareJSON (obj1, obj2) {
    log.debug('comparing', obj1, ' -- to -- ', obj2);
    var ret = {};
    for(var i in obj2) {
      if(!obj1.hasOwnProperty(i) || obj2[i] !== obj1[i]) {
        ret[i] = obj2[i];
      }
    }
    return ret;
  };

  /**
  * Check if a username is allowed
  * @param  {String} username The username in question
  * @return {String}          "" for valid usernames, error string otherwise
  */
  function allowedUsername(username) {
    if ((username.length < 6) || (username.length > 18)) {
      return $.i18n( 'msg-badlength-username' );//"Der Loginname muss mindestens 6 und höchstens 18 Zeichen enthalten";
    }

    if (RegExp('[^a-z0-9\\-\\+_]', 'i').test(username)) {
      return $.i18n( 'msg-badchars-username' ); //"Im Loginnamen sind nur lateinische Buchstaben und Zahlen sowie die Sonderzeichen _ - + erlaubt.";
    }

    return "";
  }

  /**
  * Check if a password is allowed
  * @param  {String} password The password in question
  * @return {String}          "" for valid passwords, error string otherwise
  */
  function allowedPassword(password) {
    if ((password.length < 6) || (password.length > 18)) {
      return $.i18n( 'msg-badlength-password' );//"Das Passwort muss mindestens 6 und höchstens 18 Zeichen enthalten";
    }

    if (RegExp('[^a-z0-9\\-\\+_]', 'i').test(password)) {
      return $.i18n( 'msg-badchars-password' );//"Im Passwort sind nur lateinische Buchstaben und Zahlen sowie die Sonderzeichen _ - + erlaubt.";
    }

    return "";
  }

  /*
  * Sends an object to the given URL via CORS request
  *
  * url: URL the object is sent to
  * data: object that should be sent
  * success: callback that get's called in case of success. Input as follows:
  *      function( response ) {}
  * error: Callback, der im Fehlerfall ausgefuehrt wird, eine Funktion der Form:
  * error: callback that get's called in case of errors. Input as follows:
  *      function( errorMessage ) {}
  * */
  //TODO Should be merged with function from userdata.js
  function sendCorsRequest( url, data, success, error, async ) {
    log.debug( "veHelpersjs.sendCorsRequest: called, type = POST, url = " + url + ", async = " + async + ", data = " + JSON.stringify(data));
    if (forceOffline == 1) {
      log.debug( "veHelpersjs.sendCorsRequest: Send request omittet, course is in offline mode")
    }
    $.ajax( url, {
      type: 'POST',
      async: async,
      cache: false,
      contentType: 'application/x-www-form-urlencoded',
      crossDomain: true,
      data: data,
      //dataType: 'html', //Data type that's requeset for the response
      error: error,
      success: success
      //statusCode: {}, //list of handlers for various HTTP status codes
      //timout: 1000, //Timeout in ms
    });
  }

  /**
  * Create a new favorite
  * @return {[type]} The new help favorite object
  */
  function createHelpFavorite() {
    var fav = {
      type: "Tipp",
      color: "00FF00",
      text: "Eingangstest probieren",
      pid: "html/sectionx2.1.0.html",
      icon: "test01.png"
    };
    log.debug( "veHelpers.js: New HelpFavorite created");
    return fav;
  }

  /**
  * creates a short list of favorites
  * @return {[type]} [description]
  */
  function generateShortFavoriteList(obj) {
    if (active == false) {
      return "Datenspeicherung nicht möglich";
    }

    if (typeof(obj.favorites) != "object") {
      obj.favorites = new Array();
    }

    var i;
    var s = "";
    for (i = 0; i < obj.favorites.length; i++) {
      if (i > 0) {
        s += "<br />";
      }
      s += "<img src=\"" + linkPath + "images/" + obj.favorites[i].icon + "\" style=\"width:20px;height:20px\">&nbsp;&nbsp;";
      s += "<a class='MINTERLINK' href='" + linkPath + obj.favorites[i].pid + "' >" + obj.favorites[i].text + "</a>";
    }

    return s;
  }

  /**
  * generates a long (large) list of favorites
  * @return {[type]} [description]
  */
  function generateLongFavoriteList(obj) {
    if (active == false) {
      return "Datenspeicherung nicht möglich";
    }

    if (typeof(obj.favorites) != "object") {
      obj.favorites = new Array();
    }

    var i;
    var s = "";
    for (i = 0; i < obj.favorites.length; i++) {
      s += "<img src=\"" + linkPath + "images/" + obj.favorites[i].icon + "\" style=\"width:48px;height:48px\">&nbsp;&nbsp;";
      s += "<a href=\"\" >" + obj.favorites[i].text + "</a><br />";
    }

    return s;
  }

  /**
  * Return the index of the element in an array. Compared by comparator.
  * @param  {Array} array      The array where we are looking for the element
  * @param  {Object} data       The datum to find
  * @param  {function} comparator A comparator (attribute) to compare against
  * @return {Integer}            The index of the element in the array or -1
  * if element was not found.
  */
  function findInArray(array, data, comparator){
    var foundIdx = -1;
    $.each(array, function(index, item){
      if(item[comparator] == data[comparator]){
        foundIdx = index;
        return false;     // breaks the $.each() loop
      }
    });
    return foundIdx;
  }

  /**
  * Update an element in an array. Makes use of the
  * @param  {[type]} array      [description]
  * @param  {[type]} data       [description]
  * @param  {[type]} comparator [description]
  * @return {Object}            obj.updated is true/false, if updated, obj.data
  * will contain the updated data.
  */
  function updateOrInsertInArray(array, data, comparator) {
    var result = {};
    var indexInArray = findInArray(array, data, comparator);
    if (indexInArray !== -1) {
      array[indexInArray] = data;
      result.data = array[indexInArray];
      result.status = 'update';
    } else {
      array.push(data);
      result.data = array[array.length-1]
      result.status = 'insert';
    }
    return result;
  };

  /**
  * Gets the function / classname of an object or function if it can.  Otherwise returns the provided default.
  *
  * Getting the name of a function is not a standard feature, so while this will work in many
  * cases, it should not be relied upon except for informational messages (e.g. logging and Error
  * messages).
  */
  function getFunctionName(object, defaultName) {
    var result = "";
    var nameFromToStringRegex = /^function\s?([^\s(]*)/;
    defaultName = defaultName || 'notAFunction'
    if (typeof object === 'function') {
      result = object.name || object.toString().match(nameFromToStringRegex)[1];
    } else if (typeof object.constructor === 'function') {
      result = className(object.constructor, defaultName);
    }
    return result || defaultName;
  }

  /**
  * Helper function to test if an object or arrayis empty
  * @param  {Object}  obj Complex javascript object, or array
  * @return {Boolean}    Obj: True if obj === {}, false otherwise; Array: true if arr === [], false otherwise
  */
  function isEmpty(obj) {
    if (Object.prototype.toString.call( obj ) === '[object Object]') {
      for(var prop in obj) {
        if(obj.hasOwnProperty(prop))
        return false;
      }
      return true && JSON.stringify(obj) === JSON.stringify({});
    }
    if (Object.prototype.toString.call( obj ) === '[object Array]') {
      return !Boolean(obj.length);
    }
  }

  /**
   * Recursively merges two objects (in place). Will insert respective objects from obj2 into
   * obj1 if the specified id is not present in obj1. Will update objects in obj1
   * if id is already present. Contains a switch for matching 'id' (on
   * scores) and 'uxid' (on sites).
   *
   * The heart of objCache storage.
   *
   * TODO: data model should be changed from js Array to js Object (better performance)
   * TODO: should this return the diff of the two objects? Would save one call to mergeRecursive
   * that is made again with localChanges
   *
   * @param  {Object} obj1 Complex Javascript object to be merged into.
   * @param  {Object} obj2 Complex Javascript object to be merged
   * @return {Object}      The merge result of obj1 and obj2, with updated/inserted
   * values
   */
  function mergeRecursive(obj1, obj2, changedData) {
    if (Object.prototype.toString.call( obj1 ) === '[object Array]') {
      for (var i = 0; i < obj1.length; i++) {
        if (obj1[i].id == obj2.id) {
          //we update the object
          for(var key in obj2) {
            if(obj2.hasOwnProperty(key)) {
              obj1[i][key] = obj2[key];
            }
          }
          return obj1;
        }
      }
      //insert in array
      obj1.push(obj2);
      return obj1;
    }
    for (var p in obj2) {
      //merging array
      if (Object.prototype.toString.call( obj2[p] ) === '[object Array]') {
        obj1[p] = typeof obj1[p] === 'undefined' ? [] : obj1[p];
        obj2[p].forEach(function(arrayElement) {
          obj1[p] = mergeRecursive(obj1[p], arrayElement);
        });
      //merging object
      } else if (Object.prototype.toString.call ( obj2[p] ) === '[object Object]') {
        obj1[p] = typeof obj1[p] === 'undefined' ? {} : obj1[p];
        obj1[p] = mergeRecursive(obj1[p], obj2[p]);
      } else {
        obj1[p] = obj2[p];
      }
    }
    return obj1;
  }

  var ajax = {};
ajax.x = function () {
    if (typeof XMLHttpRequest !== 'undefined') {
        return new XMLHttpRequest();
    }
    var versions = [
        "MSXML2.XmlHttp.6.0",
        "MSXML2.XmlHttp.5.0",
        "MSXML2.XmlHttp.4.0",
        "MSXML2.XmlHttp.3.0",
        "MSXML2.XmlHttp.2.0",
        "Microsoft.XmlHttp"
    ];

    var xhr;
    for (var i = 0; i < versions.length; i++) {
        try {
            xhr = new ActiveXObject(versions[i]);
            break;
        } catch (e) {
        }
    }
    return xhr;
};

ajax.send = function (url, callback, method, data, async) {
    if (async === undefined) {
        async = true;
    }
    var x = ajax.x();
    x.open(method, url, async);
    x.onreadystatechange = function () {
        if (x.readyState == 4) {
            callback(x.responseText)
        }
    };
    if (method == 'POST') {
        x.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    }
    x.send(data)
};

ajax.get = function (url, data, callback, async) {
    var query = [];
    for (var key in data) {
        query.push(encodeURIComponent(key) + '=' + encodeURIComponent(data[key]));
    }
    ajax.send(url + (query.length ? '?' + query.join('&') : ''), callback, 'GET', null, async)
};

ajax.post = function (url, data, callback, async) {
    var query = [];
    for (var key in data) {
        query.push(encodeURIComponent(key) + '=' + encodeURIComponent(data[key]));
    }
    ajax.send(url, callback, 'POST', query.join('&'), async)
};

  exports.convertTimestamp = convertTimestamp;
  exports.compareJSON = compareJSON;
  exports.allowedUsername = allowedUsername;
  exports.allowedPassword = allowedPassword;
  exports.sendCorsRequest = sendCorsRequest;
  exports.createHelpFavorite = createHelpFavorite;
  exports.generateShortFavoriteList = generateShortFavoriteList;
  exports.generateLongFavoriteList = generateLongFavoriteList;
  exports.findInArray = findInArray;
  exports.getFunctionName = getFunctionName;
  exports.updateOrInsertInArray = updateOrInsertInArray;
  exports.isEmpty = isEmpty;
  exports.mergeRecursive = mergeRecursive;
  exports.ajax = ajax;

}));
