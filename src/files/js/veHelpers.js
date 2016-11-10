(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports'], function (exports) {
      factory(root.veHelpers = exports);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports);
  } else {
    // Browser globals
    factory(root.veHelpers = {});
  }
}(this, function (exports) {

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

  exports.convertTimestamp = convertTimestamp;
  exports.compareJSON = compareJSON;
  exports.allowedUsername = allowedUsername;
  exports.allowedPassword = allowedPassword;
  exports.sendCorsRequest = sendCorsRequest;
  exports.createHelpFavorite = createHelpFavorite;
  exports.generateShortFavoriteList = generateShortFavoriteList;
  exports.generateLongFavoriteList = generateLongFavoriteList;

}));