/* from https://github.com/umdjs/umd/blob/master/templates/commonjsStrictGlobal.js */

(function (root, factory) {
  /* istanbul ignore next */
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports'], function (exports) {
      factory((root.IStorageService = exports));
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports);
  } else {
    // Browser globals
    factory(root.IStorageService = {});
  }
}(this, function (exports) {

  /**
  * This is a hack for a super class from
  * http://www.bolinfest.com/javascript/inheritance.php
  * until we move to typescript
  * @return {Object} An object with interface functions that can be extended
  * by doing myService = function () { var that = IStorageService(); ... }
  */

  var IStorageService = function() {
    var that = {};

    that.name = 'I DO NOT HAVE A NAME YET';

    that.saveUserData = function() {
      return Promise.reject('NOT YET IMPLEMENTED');
    }

    that.getUserData = function() {
      return Promise.reject('NOT YET IMPLEMENTED');
    }

    that.getDataTimestamp = function() {
      return Promise.reject('NOT YET IMPLEMENTED');
    }

    return that;
  }

  exports.IStorageService = IStorageService;

}));
