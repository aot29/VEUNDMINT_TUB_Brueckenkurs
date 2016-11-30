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

  //  if (intersite.isActive() == true) {
  //    if (intersite.getObj().configuration.CF_USAGE == "1") {
     //
  //      var timestamp = +new Date();
  //      var cm = "OPENSITE: " + "CID:" + signature_CID + ", user:" + intersite.getObj().login.username + ", timestamp:" + timestamp + ", SITEUXID:" + SITE_UXID + ", localurl:" + localurl;
  //      intersite.sendeFeedback( { statistics: cm }, false ); // synced, otherwise the page with callbacks is gone when the request is completed
  //    }
  //  }
  //TODO ns send feedback to server

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
        defaultLogLevel: 'error',
        storageServices: [LocalStorageService.LocalStorageService(), DjangoStorageService.DjangoStorageService(), ScormStorageService],
        localStorageKey: signature_main + '_user_data'
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
     * Initialize Plugin, called on document ready at startpage
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


        log.setDefaultLevel(settings.defaultLogLevel);
        
        //register storageServices
        for (var i = 0; i < settings.storageServices.length; i++) {
            dataService.subscribe(settings.storageServices[i]);
        }     

        scormBridge.init();
        //intersite.init(); is now
        dataService.init();

        globalreadyHandler("");
        globalloadHandler("");
        ui.init();


        $('[data-toggle="offcanvas"]').click(function () {
            $('.row-offcanvas').toggleClass('active')
        });

        //call syncDown once onLoad to get most recent userData
        dataService.syncDown();

        //hook up data synchronization on unload
        $(window).on('beforeunload', function(){
            dataService.makeSynchronous();
            dataService.syncUp().then(function(data) {
                console.log(data);
            });
        });

        // set up components
        veundmint.languageChooser($('#languageChooser'));

        //remove logout button on scorm
        if (scormBridge.isScormEnv()) {
            $('#li-logout').remove();
        }

        //if we came from the same url in another language, return to the scroll position
        dataService.getUserData().then(function(userData) {
           if (userData) {
               if (userdata.scrollTop !== 0) {
                $('html, body').animate({scrollTop: userData.scrollTop}, 1000);
                dataService.updateUserData({scrollTop: 0});
               }
           }
        });
        
        // footer at bottom of column
        // don't use navbar-fixed-bottom, as it doesn't play well with offcanvas
        $(window).resize( veundmint.positionFooter );
        veundmint.positionFooter();

        // on the logout page
        if( requestLogout ) {
            localStorage.clear();
        }

        veundmint.addReadyElementToPage();

    };


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
            dataService.updateUserData({scrollTop: oldScrollTop});

      var newUrl = url.replace('/' + ownLanguage + '/', '/' + this.value + '/');
      window.location.href = newUrl;
    });
  }

    veundmint.positionFooter = function () {
        var docHeight = $(window).height();
        var offsetHeight = $( "#navbarTop" ).height() + $( "#subtoc" ).height() + $( "#footer" ).height() * 2;
        $( "#pageContents" ).css( "minHeight", docHeight - offsetHeight + "px" );
    }

    /**
     * Adds an element to the body to indicate that veundmint.init() and therefore
     * all other init methods are ready. Selenium can then check for that element and
     * continue if its available.
     */
    veundmint.addReadyElementToPage = function () {
        $('body').append('<div id="veundmint_ready" style="display:none;"></div>')
    }

    veundmint.settings = function () {
        return settings;
    }

    return veundmint;

});
