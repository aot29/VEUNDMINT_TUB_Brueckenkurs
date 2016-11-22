(function (root, factory) {
  /* istanbul ignore next */
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'IStorageService', 'veHelpers', 'scormBridge'], function (exports, IStorageService, veHelpers, scormBridge) {
      factory((root.ScormStorageService = exports), IStorageService, veHelpers, scormBridge);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports, require('./IStorageService.js'), require('../veHelpers.js'), require('../scormBridge.js'));
  } else {
    // Browser globals
    factory((root.ScormStorageService = {}), root.IStorageService, root.veHelpers, root.scormBridge);
  }
}(this, function (exports, IStorageService, veHelpers, scormBridge) {

  var ScormStorageService = function () {
    var that = IStorageService.IStorageService();

    that.name = 'ScormStorageService';

    that.saveUserData = function(data) {
      var result = new Promise(function (resolve, reject) {
        var success = scormBridge.setJSONData(data);
        if (success) {
          resolve(data);
        } else {
          reject(new TypeError('ScormStorageService errored setting user data'));
        }
      });
      return result;
    }

    that.getUserData = function () {
      var result = new Promise(function (resolve, reject) {
        var data = scormBridge.getJSONData();
        if (data) {
          resolve(data);
        } else {
          reject(new TypeError('ScormStorageService errored getting user data'));
        }
      });
      return result;
    }

    /**
     * By returning -1 this data is NEVER considered for syncing down of data
     * until we find a way to store it in scorm -1 should be correct
     * @return {Promise<int>} The timestamp of the data in a Promise
     */
    that.getDataTimestamp = function() {
      return Promise.resolve(-1);
    }

    return that;
  }

  var instance = ScormStorageService();

  exports.getDataTimestamp = instance.getDataTimestamp;
  exports.getUserData = instance.getUserData;
  exports.saveUserData = instance.saveUserData;
  exports.name = instance.name;

}));
