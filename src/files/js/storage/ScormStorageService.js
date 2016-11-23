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
          
        if (!scormBridge.isScormEnv() || !scormBridge.isCustomAPI) {
            reject(new TypeError('No Scorm Env / API found'));
        }
          
        var oldData = scormBridge.getJSONData() || {};
        var newData = veHelpers.mergeRecursive(oldData, data);
        newData.timestamp = new Date().getTime();          
          
        var success = scormBridge.setJSONData(newData);
        success &= scormBridge.save();
        
        if (success) {
          resolve(newData);
        } else {
          reject(new TypeError('ScormStorageService errored setting user data'));
        }
      });
      return result;
    }

    that.getUserData = function () {
      var result = new Promise(function (resolve, reject) {
          
        if (!scormBridge.isScormEnv() || !scormBridge.isCustomAPI) {
            reject(new TypeError('No Scorm Env / API found'));
        }  
          
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
        
//       var scormUserData = scormBridge.getJSONData();
// 
//       var result = new Promise(function (resolve, reject) {
//         if (!scormBridge.isScormEnv() || !scormBridge.isCustomAPI) {
//             reject(new TypeError('No Scorm Env / API found'));
//         }             
//           
//         if (typeof scormUserData !== 'undefined' && scormUserData !== null) {
//           resolve(scormUserData.timestamp);
//         } else {
//           //return very old data timestamp
//           reject(new TypeError('ScormStorageService: Can not get data Timestamp from Scorm Data'));
//         }
//       });
//       return result;
        return Promise.resolve(12412575757757);
    }

    return that;
  }

  var instance = ScormStorageService();

  exports.getDataTimestamp = instance.getDataTimestamp;
  exports.getUserData = instance.getUserData;
  exports.saveUserData = instance.saveUserData;
  exports.name = instance.name;

}));
