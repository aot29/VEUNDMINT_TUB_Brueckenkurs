(function (root, factory) {
  /* istanbul ignore next */
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'veSettings', 'IStorageService', 'veHelpers'], function (exports, IStorageService, veHelpers) {
      factory((root.LocalStorageService = exports), IStorageService, veHelpers);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports, require('../veSettings.js'), require('./IStorageService.js'), require('../veHelpers.js'));
  } else {
    // Browser globals
    factory((root.LocalStorageService = {}), root.veSettings, root.IStorageService, root.veHelpers);
  }
}(this, function (exports, veSettings, IStorageService, veHelpers) {

  var LocalStorageService = function () {
    var that = IStorageService.IStorageService();

    var storageKey = veSettings.courseId + '_user_data';
    that.name = 'LocalStorageService';

    that.saveUserData = function(data) {

      if (!localStorage) {
        return new Promise.reject(new TypeError('LocalStorageService: localStorage is not enabled'));
        }

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

      if (!localStorage) {
        return new Promise.reject(new TypeError('LocalStorageService: localStorage is not enabled'));
        }

      var result = new Promise(function (resolve, reject) {
        var data = JSON.parse(localStorage.getItem(storageKey));
        resolve(data);
      });
      return result;
    }

    that.getDataTimestamp = function() {

      if (!localStorage) {
        return new Promise.reject(new TypeError('LocalStorageService: localStorage is not enabled'));
        }

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

    that.logout = function() {
      if (!localStorage) {
        return new Promise.reject(new TypeError('LocalStorageService: localStorage is not enabled'));
        }

        localStorage.removeItem(storageKey);
	}

    return that;
  }

  exports.LocalStorageService = LocalStorageService;

}));
