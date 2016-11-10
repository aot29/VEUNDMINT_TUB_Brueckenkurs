(function (root, factory) {
    if (typeof define === 'function' && define.amd) {
        // AMD. Register as an anonymous module.
        define(['exports', 'loglevel'], function (exports, log) {
            factory((root.commonJsStrictGlobal = exports), log);
        });
    } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
        // CommonJS
        factory(exports, require('loglevel'));
    } else {
        // Browser globals
        factory((root.commonJsStrictGlobal = {}), root.log);
    }
}(this, function (exports, log) {

    log.debug('ui.js: loaded');
    //use b in some fashion.
    //
    //

    var delay = (function(){
      var timer = 0;
      return function(callback, ms){
        clearTimeout (timer);
        timer = setTimeout(callback, ms);
      };
    })();


    /**
     * Login functionality
     */

    $('#USER_UNAME').on('keyup', function(event) {
      delay(function() {
        console.log('keyup', event.target.value);
        dataService.usernameAvailable(event.target.value).then(function(data) {
          console.log(data);
        });
      }, 200);
    });

    // attach properties to the exports object to define
    // the exported module properties.
    exports.action = function () {};
}));
