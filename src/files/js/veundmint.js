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

	var veundmint = {}; // Object for public APIs
	var supports = !!document.querySelector && !!root.addEventListener; // Feature test
	var settings, eventTimeout;

  var currentUser = {};
  var isLoggedIn = false;

	// Default settings
	var defaults = {
		apiUrl: 'http://localhost:8000',
    apiAuthUrl: 'http://localhost:8000/api-token-auth/',
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

	/**
	 * Get the closest matching element up the DOM tree
	 * @param {Element} elem Starting element
	 * @param {String} selector Selector to match against (class, ID, or data attribute)
	 * @return {Boolean|Element} Returns false if not match found
	 */
	var getClosest = function (elem, selector) {
		var firstChar = selector.charAt(0);
		for ( ; elem && elem !== document; elem = elem.parentNode ) {
			if ( firstChar === '.' ) {
				if ( elem.classList.contains( selector.substr(1) ) ) {
					return elem;
				}
			} else if ( firstChar === '#' ) {
				if ( elem.id === selector.substr(1) ) {
					return elem;
				}
			} else if ( firstChar === '[' ) {
				if ( elem.hasAttribute( selector.substr(1, selector.length - 2) ) ) {
					return elem;
				}
			}
		}
		return false;
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
		eventTimeout = null;

	};

	/**
	 * On window scroll and resize, only run events at a rate of 15fps for better performance
	 * @private
	 * @param  {Function} eventTimeout Timeout function
	 * @param  {Object} settings
	 */
	var eventThrottler = function () {
		if ( !eventTimeout ) {
			eventTimeout = setTimeout(function() {
				eventTimeout = null;
				actualMethod( settings );
			}, 66);
		}
	};

	/**
	 * Initialize Plugin
	 * @public
	 * @param {Object} options User settings
	 */
	veundmint.init = function ( options ) {

		// feature test
		if ( !supports ) return;

		// Destroy any existing initializations
		veundmint.destroy();

		// Merge user options with defaults
		settings = extend( defaults, options || {} );

		// @todo Do something...

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
      success: store_credentials
    });
    // save answer from server in object
    var auth_result = '';
    if (typeof callback === "function") {
    // Call it, since we have confirmed it is callable​
        callback(auth_result);
    }
    console.log('veundmint.authenticate called with:', user_credentials);

		store_credentials = function(credentials) {
			console.log(credentials);
		}
    return auth_result;
  }

  /**
   * Logs the user out from the server (serverLogoutUrl)
   * @param  {Function} callback [description]
   * @return {[type]}            [description]
   */
  veundmint.logout = function (callback) {
    //log out of the server
    // << call server api logout here >>
    var logout_result = '';
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
    //
    console.log('veundmint.sendWebsiteAction called with object', object);
  }

	return veundmint;

});
