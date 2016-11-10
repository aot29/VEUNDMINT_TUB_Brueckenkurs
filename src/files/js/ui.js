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

  /**
   * Throttle the execution of functions by only allowing execution every
   * ms milliseconds
   */
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

  //user register form - check username available on keyup
  $('#USER_UNAME').on('keyup', function(event) {
    delay(function() {
      dataService.usernameAvailable(event.target.value).then(function(data) {
        var $formParent = $(event.target).parents('.form-group');
        var $icon = $("#USER_UNAME_ICON");
        if (data.username_available) {
          $formParent.addClass('has-success');
          $formParent.removeClass('has-error');
          $icon.removeClass('glyphicon-remove');
          $icon.addClass('glyphicon-ok');
          $('#USER_UNAME_SUCCESS').show();
          $('#USER_UNAME_ERROR').hide();
        } else {
          $formParent.addClass('has-error');
          $formParent.removeClass('has-success');
          $icon.removeClass('glyphicon-ok');
          $icon.addClass('glyphicon-remove');
          $('#USER_UNAME_SUCCESS').hide();
          $('#USER_UNAME_ERROR').show();
        }
      });
    }, 200);
  });

  // attach properties to the exports object to define
  // the exported module properties.
  exports.action = function () {};
}));
