/* this should actually go to a different file, but where i did not decide yet
it is responsible for the document loaded action that was befor in the body onload and onunload
onload="loadHandler()" onunload="unloadHandler()" */

$(window).on('beforeunload', function(){
	globalunloadHandler();
 });


//TODO this should definately go somewhere totally else
 // Opens a new webpage (from the local packet) in a new browser tab
 // localurl sollte direkt aus dem href-Attribut bei anchors genommen werden TODO: Translation
 // Marks the page as visited in 'intersite.getObj()'
 function opensite(localurl) {
   //window.location.href = localurl; // fetches the new page

   // pushISO(); is now called on the pages by beforeunload

   if (intersite.isActive() == true) {
     if (intersite.getObj().configuration.CF_USAGE == "1") {

       var timestamp = +new Date();
       var cm = "OPENSITE: " + "CID:" + signature_CID + ", user:" + intersite.getObj().login.username + ", timestamp:" + timestamp + ", SITEUXID:" + SITE_UXID + ", localurl:" + localurl;
       intersite.sendeFeedback( { statistics: cm }, false ); // synced, otherwise the page with callbacks is gone when the request is completed
     }
   }

   window.open(localurl,"_self");
 }

//UMD JS Modules Starter template taken from https://gist.github.com/cferdinandi/ece94569aefcffa5f7fa

(function (root, factory) {
	if ( typeof define === 'function' && define.amd ) {
		define([], factory(root));
	} else if ( typeof exports === 'object' ) {
		module.exports = factory(root);
	} else {
		root.veundmint = factory(root);
	}
})(typeof global !== "undefined" ? global : this.window || this.global, function (root) {

	'use strict';

	//
	// Variables
	//
	var USER_CREDENTIALS_KEY = 'user_credentials';

	var veundmint = {}; // Object for public APIs
	var supports = !!document.querySelector && !!root.addEventListener; // Feature test
	var settings, eventTimeout;

  var isLoggedIn = false;

	var userCredentials;

	// Default settings
	var defaults = {
		apiUrl: 'http://localhost:8000',
    apiAuthUrl: 'http://localhost:8000/api-token-auth/',
		apiProfileUrl: 'http://localhost:8000/whoami/',
		apiWebsiteActionUrl: 'http://localhost:8000/server-action/',
		initClass: 'js-myplugin',
		callbackBefore: function () {},
		callbackAfter: function () {}
	};


	//
	// Methods
	//

	/**
	 * A simple forEach() implementation for Arrays, Objects and NodeLists
	 * @private
	 * @param {Array|Object|NodeList} collection Collection of items to iterate
	 * @param {Function} callback Callback function for each iteration
	 * @param {Array|Object|NodeList} scope Object/NodeList/Array that forEach is iterating over (aka `this`)
	 */
	var forEach = function (collection, callback, scope) {
		if (Object.prototype.toString.call(collection) === '[object Object]') {
			for (var prop in collection) {
				if (Object.prototype.hasOwnProperty.call(collection, prop)) {
					callback.call(scope, collection[prop], prop, collection);
				}
			}
		} else {
			for (var i = 0, len = collection.length; i < len; i++) {
				callback.call(scope, collection[i], i, collection);
			}
		}
	};

	/**
	 * Merge defaults with user options
	 * @private
	 * @param {Object} defaults Default settings
	 * @param {Object} options User options
	 * @returns {Object} Merged values of defaults and options
	 */
	var extend = function ( defaults, options ) {
		var extended = {};
		forEach(defaults, function (value, prop) {
			extended[prop] = defaults[prop];
		});
		forEach(options, function (value, prop) {
			extended[prop] = options[prop];
		});
		return extended;
	};

	/**
	 * Convert data-options attribute into an object of key/value pairs
	 * @private
	 * @param {String} options Link-specific options as a data attribute string
	 * @returns {Object}
	 */
	var getDataOptions = function ( options ) {
		return !options || !(typeof JSON === 'object' && typeof JSON.parse === 'function') ? {} : JSON.parse( options );
	};

	// @todo Do something...

	/**
	 * Destroy the current initialization.
	 * @public
	 */
	veundmint.destroy = function () {

		// If plugin isn't already initialized, stop
		if ( !settings ) return;


		// @todo Undo any other init functions...

		// Reset variables
		settings = null;

	};

	/**
	 * Initialize Plugin, called on document redy at startpage
	 * execution order of several commands is critical (by now) DO NOT CHANGE
	 * unless you know what you are doing
	 * @param {Object} options User settings
	 */
	veundmint.init = function ( options ) {

		// feature test
		if ( !supports ) return;

		// Destroy any existing initializations
		veundmint.destroy();

		// Merge user options with defaults
		settings = extend( defaults, options || {} );


    $('[data-toggle="offcanvas"]').click(function () {
      $('.row-offcanvas').toggleClass('active')
    });

  	intersite.init();
    globalreadyHandler("");
  	globalloadHandler("");

		// set up components
		veundmint.languageChooser($('#languageChooser'));

    //remove logout button on scorm
    if (intersite.isScormEnv()) {
      $('#li-logout').remove();
    }

		//if we came from the same url in another language, return to the scroll position
		var oldScrollTop = intersite.getScrollTop();
		if (oldScrollTop !== 0) {
	  	$(document).scrollTop(oldScrollTop);
			intersite.setScrollTop(0);
		}


	};


	//
	// Public APIs
	//

  /**
   * Authenticates at the server (apiAuthUrl) with the given user credentials object
   * that should contain a 'username' and a 'password'
   * @param  {[type]}   user_credentials A javascript object that contains
   * a username and a password like {username: 'username', password: 'password'}
   * @param  {Function} callback callback function will be called with results from server that will
   * either contain an error or a token {token: 'the auth token'}
   * @return {[type]}            [description]
   */
  veundmint.authenticate = function (user_credentials, callback) {
    // log in to the server
    $.ajax({
      type: "POST",
      url: settings.apiAuthUrl,
      data: user_credentials,
      success: function (data) {
				delete(user_credentials.password);
				$.extend(user_credentials, data);
				//user credentials will have the form {username: <name>, token: <token>}
				localStorage.setItem(USER_CREDENTIALS_KEY, JSON.stringify(user_credentials));
			}
    });
    // save answer from server in object
    var auth_result = '';
    if (typeof callback === "function") {
    // Call it, since we have confirmed it is callable​
        callback(auth_result);
    }
    console.log('veundmint.authenticate called with:', user_credentials);

    return auth_result;
  }

	veundmint.getMyUserProfile = function() {
		veundmint.authAjaxGET(settings.apiProfileUrl, {}, function (data) {
			console.log(data);
		});
	}

  /**
   * Logs the user out from the server (serverLogoutUrl)
   * @param  {Function} callback [description]
   * @return {[type]}            [description]
   */
  veundmint.logout = function (callback) {
    userCredentials = null;
		localStorage.removeItem(USER_CREDENTIALS_KEY);
    if (typeof callback === "function") {
    // Call it, since we have confirmed it is callable​
      callback(logout_result);
    }

    console.log('veundmint.logout called');
  }

  /**
   * Sends feedback about a user action to the server
   * @param  {json} object [description]
   * @return {json}        the json result from the server
   */
  veundmint.sendWebsiteAction = function (object) {

    console.log('veundmint.sendWebsiteAction called with object', object);

		if (typeof settings.apiWebsiteActionUrl === "undefined") {
			console.log('apiWebsiteActionUrl is not set, will not call sendWebsiteAction()');
			return null;
		}

		$.ajax({
			type: "POST",
			url: settings.apiWebsiteActionUrl,
			data: object,
			success: function (data) {
				console.log(data);
			}
		});
  }

	/**
	 * Get the user credentials from local variable. If not set, get it from local
	 * Storage and set it and return it
	 * @return {object or null} the user credentials object or null
	 */
	veundmint.getUserCredentials = function () {
		if (typeof userCredentials !== "undefined" && userCredentials !== null) {
			return userCredentials;
		} else {
			var lsUserCred = localStorage.getItem(USER_CREDENTIALS_KEY);
			if (lsUserCred !== null) {
				return JSON.parse(lsUserCred);
			}
		}
		console.log('can only call getUserCredentials if user is authenticated')
		return null;
	}

	veundmint.authAjaxGET = function (url, data, onSuccess) {
		var userCredentials = veundmint.getUserCredentials();
		if (userCredentials === null || typeof userCredentials === "undefined"
			|| typeof userCredentials.token === "undefined" ) {
				console.log('can only make authAjaxGET request if userCredentials are set');
				return;
		}
		$.ajax({
      type: "GET",
			dataType: 'json',
      url: url,
      data: data,
      success: onSuccess,
			headers: {
				'Authorization': 'JWT ' + userCredentials.token
			}
    });
	}

  /**
   * sets up element to be a languageChooser
   * @param  {[type]} element the jquery element to transform
   */
  veundmint.languageChooser = function (element) {
    var languages = ["de", "en"];

    var url = window.location.href;
    var ownLanguage = $('html').attr('lang');
    var otherLanguages = languages.slice(languages.indexOf(ownLanguage),1);
    var htmlString =  '<form class="navbar-form navbar-right"><select id="selectLanguage" class="form-control">';
    languages.forEach(function(langString, index) {
      if (langString === ownLanguage) {
        htmlString += '<option selected="selected">' + langString + '</option>';
      } else {
        htmlString += '<option>' + langString + '</option>';
      }
    });
    htmlString += '</select></form>';

    element.replaceWith(htmlString);

    $('body').on('change', '#selectLanguage', function() {
			//store the scroll Top for next site, will be set in veundmint.init()
			var oldScrollTop = $(document).scrollTop();
			intersite.setScrollTop(oldScrollTop);

      var newUrl = url.replace('/' + ownLanguage + '/', '/' + this.value + '/');
      window.location.href = newUrl;
    });
  }

	return veundmint;

});
