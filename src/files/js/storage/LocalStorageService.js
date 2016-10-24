(function (root, factory) {
  /* istanbul ignore next */
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'IStorageService', 'veHelpers'], function (exports, IStorageService, veHelpers) {
      factory((root.LocalStorageService = exports), IStorageService, veHelpers);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports, require('./IStorageService.js'), require('../veHelpers.js'));
  } else {
    // Browser globals
    factory((root.LocalStorageService = {}), root.IStorageService, root.veHelpers);
  }
}(this, function (exports, IStorageService, veHelpers) {

  var LocalStorageService = function () {
    var that = IStorageService.IStorageService();

    var storageKey = 'myStorageKey';
    that.name = 'LocalStorageService';

    that.saveUserData = function(data) {
      var result = new Promise(function (resolve, reject) {
        var oldData = JSON.parse(localStorage.getItem(storageKey)) || {};
        newData = veHelpers.mergeRecursive(oldData, data);
        newData.timestamp = new Date().getTime();
        localStorage.setItem(storageKey, JSON.stringify(newData));
        resolve(newData);
      });
      return result;
    }

    that.getUserData = function () {
      var result = new Promise(function (resolve, reject) {
        var data = JSON.parse(localStorage.getItem(storageKey));
        resolve(data);
      });
      return result;
    }

    that.getDataTimestamp = function() {
      var data = JSON.parse(localStorage.getItem(storageKey));

      var result = new Promise(function (resolve, reject) {
        if (typeof data !== 'undefined' && data !== null) {
          resolve(data.timestamp);
        } else {
          //return very old data timestamp
          reject(new TypeError('localStorageService: Can not get data Timestamp from localstorage'));
        }
      });
      return result;
    }

    return that;
  }

  exports.LocalStorageService = LocalStorageService;

}));
