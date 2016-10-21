/* from https://github.com/umdjs/umd/blob/master/templates/commonjsStrictGlobal.js */

(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'veHelpers', 'loglevel'], function (exports, veHelpers, log) {
      factory((root.dataService = exports), veHelpers, log);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports, require('veHelpers', 'loglevel'));
  } else {
    // Browser globals
    factory((root.dataService = {}), root.veHelpers, root.log);
  }
}(this, function (exports, veHelpers, log) {

  //
  // Variables
  //
  var settings;

  // Default settings
  var defaults = {
    apiUrl: 'http://localhost:8000/',
    apiAuthUrl: 'http://localhost:8000/api-token-auth/',
    apiProfileUrl: 'http://localhost:8000/profile/',
    apiWebsiteActionUrl: 'http://localhost:8000/server-action/',
    apiScoresUrl: 'http://localhost:8000/score/',
    defaultLogLevel: 'debug',
    //wether a call to SyncDown should also try to syncUp data if timestamps differ
    alwaysSynchronize : true
  };

  var storageServices = [];
  var storageServicesMap = {};
  var syncStrategies = ['timer', 'onunload']

  //the 'cache' for all userData
  var objCache = {
    scores: []
  };

  //stores the changed data, since objCache is always 'synced' but too large
  //this variable stores recent, unsynced changes and will be reset on successful
  //sync operation
  var changedData = {};


  /**
  * This is the concrete implementation that 'extends', storageService and
  * stores data in localStorage.
  */
  function localStorageService () {
    var storageKey = 'myStorageKey';
    return {
      name: 'localStorageService',
      saveUserData : function (data) {
        var result = new Promise(function (resolve, reject) {
          var oldData = JSON.parse(localStorage.getItem(storageKey)) || {};
          newData = mergeRecursive(oldData, data);
          newData.timestamp = new Date().getTime();
          localStorage.setItem(storageKey, JSON.stringify(newData));
          resolve(newData);
        });
        return result;
      },
      getUserData : function () {
        var result = new Promise(function (resolve, reject) {
          var data = JSON.parse(localStorage.getItem(storageKey));
          resolve(data);
        });
        return result;
      },
      getDataTimestamp: function () {
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
    }
  }

  /**
   * Will locally update userData and also the changedData object used for synchronizing
   * data.
   * @param  {Object} updatedData Complex Javascript object of updated Data (structure must
   * be conform to the structure used by the program)
   * @return {Object}             The updated user Data
   */
  function updateUserData(updatedData) {
    mergeRecursive(changedData, updatedData);
    return mergeRecursive(objCache, updatedData);
  }

  /**
   * Convenience function for updating only scores in userData
   * @param  {Array<Score>} updatedScores An array of updated scores
   * @return {[type]}               [description]
   */
  function updateScores(updatedScores) {
    if (Object.prototype.toString.call ( updatedScores ) !== '[object Array]') {
      console.warn('dataService: updateScores called with wrong parameter type, requires an Array');
      return null;
    }
    return updateUserData({scores: updatedScores});
  }

  function failService () {
    return {
      saveUserData : function () {
        return new Promise(function (resolve, reject) {
          reject(new TypeError('some getUsererror'));
        });
      },
      getUserData : function () {
        return new Promise(function (resolve, reject) {
          reject(new TypeError('some setUsererror'));
        });
      },
      name: 'failService',
      getDataTimestamp: function () {
        return Promise.reject(new TypeError('some get timestamp error'));
      }
    }
  }

  function latestStorageService () {
    var latestUserData = {}
    var evenNewerTimeStamp = 15576239654329;
    return {
      saveUserData : function (data) {
        // console.log('latestStorageService saveUserData called');
        var result = new Promise(function (resolve, reject) {
          setTimeout(function() {
            console.log('after 2 secs');
            latestUserData = data;
            resolve(latestUserData);
          }, 2000);
        });
        return result;
      },
      getUserData : function () {
        // console.log('latestStorageService getUserData called');
        var result = new Promise(function (resolve, reject) {
          setTimeout(function() {
            console.log('after 2 secs');
            latestUserData.timestamp = evenNewerTimeStamp;
            resolve(latestUserData);
          }, 2000);
        });
        return result;
      },
      getDataTimestamp: function () {
        return Promise.resolve(evenNewerTimeStamp);
      },
      name: 'latestStorageService'
    }
  }

  /**
   * This service will never be used for downSync as it can not store as detailed
   * data as the others. But only for syncUp. That is achieved by returning -1
   * in getDataTimestamp, so it will never contain the latest data. Refer to the
   * definition of @syncDown, which will compare timestamps.
   * @return {[type]} [description]
   */
  function scormStorageService () {

  }

  function djangoStorageService () {
    var djUserData = {}
    var newerTimeStamp = 15576239654328;
    return {
      saveUserData : function (data) {
        console.log('djangoStorageService saveUserData called');
        var result = new Promise(function (resolve, reject) {
          setTimeout(function() {
            console.log('after 2 secs');
            djUserData = data;
            resolve(djUserData);
          }, 2000);
        });
        return result;
      },
      getUserData : function () {
        console.log('djangoStorageService getUserData called');
        var result = new Promise(function (resolve, reject) {
          setTimeout(function() {
            console.log('after 2 secs');
            djUserData.timestamp = newerTimeStamp;
            resolve(djUserData);
          }, 2000);
        });
        return result;
      },
      getDataTimestamp: function () {
        return Promise.resolve(newerTimeStamp);
      },
      name: 'djangoStorageService'
    }
  }

  //sync on startup
  //on time
  //only the diff should be sent to server (whyever)
  //most recent version should be saved

  function subscribe (observable) {
    storageServices.push(observable);
    storageServicesMap[observable.name] = observable;
  }

  /**
  * [sync description]
  * @return {[type]} Muss auf alle faelle promise zurueckgeben
  */
  function sync () {
    var syncedDown = false;
    //TODO set this to 0
    var promiseCounter = 1;

    var status = {
      syncDown: 'error',
      syncUp: 'error'
    };


    var result = new Promise(function (resolve, reject) {
      // 1. if page is being loaded
      if (objCache.scores.length === 0) {

        getAllUserData().then(function (allResults) {
          if (Array.isArray(allResults) && allResults.length > 0) {
            allResults.sort(compareTimestamps);
            objCache = allResults[0].data;
            console.log('sync set objCache to', allResults[0].data, 'from ', allResults[0].serviceName);
            syncedDown = true;
            status.syncDown = 'success';
            status.syncFrom = allResults[0].serviceName;
            status.data = objCache;
          } else {
            console.log('getAllUserData did not return an array');
            status.syncDownErrorMessage = 'getAllUserData did not return an array';
            reject(status);
          }
        }).catch(function(error) {
          status.syncDownErrorMessage = error;
          reject(status);
        }).finally(function() {
          promiseCounter += 1;
          if (promiseCounter == 2) {
            resolve(status);
          }
        });

        //scorm ?

      } else {
        // 2. if page was already loaded and we just want to persist the data (which
        // might also happen if data from one server is more recent than from others)
        status.data = objCache
        resolve(status);
      }

      // 2. if page was already loaded and we just want to persist the data (which
      // might also happen if data from one server is more recent than from others)



      //beim seiten laden
      //sz #1. localstorage ist aelter als server version(en) oder nicht vorhanden
      //=> neuste serverstorage version -sync-> alle aelteren server storage versionen
      //=> und localstorage
      //
      //sz #2 localstorage ist neuer als server version(en)
      //=> localstorage -sync-> server storage(s)
      //
    });

    return result;

  }

  /**
   * Synchronizes data from servers / other storages to objCache. Will automatically
   * consider only the latest data for downloading.
   * @return {Promise} A promise holding the userData.
   */
  function syncDown() {
    //TODO should we consider objCache to also be an implementation of storageService?
    //pro: we would not have to handle the obj cache separately, does same things anyway (except sync)
    //contra: logically not the same as storage service, can we imagine working without objCache?

    if (storageServices.length === 0) {
      return Promise.reject(new TypeError('dataService: no registered storageServices to sync from'));
    }

    // log.debug('dataService: syncDown is calling getAllDataTimestamps');
    var promise = getAllDataTimestamps().then(function (successAllTimestamps) {
      if (Array.isArray(successAllTimestamps) && successAllTimestamps.length > 0) {
        successAllTimestamps.sort(compareTimestampsNew);
        // log.debug('services returned the timestamps:', successAllTimestamps);
        // log.debug('latest data was found at the service:', successAllTimestamps[0]);
        var latestTimestampData = successAllTimestamps[0];
        //return the userdata Promise from the service where the latest data was found
        //by comparing the timestamps
        return storageServicesMap[latestTimestampData.serviceName].getUserData();
      } else {
        reject(new TypeError('getAllDataTimestamps did not return an Array.'));
      }
    }).then(function(latestData) {
      objCache = latestData;
      //if there were localChanges merge them, so they are not lost
      if (!veHelpers.isEmpty(changedData)) {
        objCache = mergeRecursive(objCache, changedData);
      }
      // log.debug('latestData retrieved and objCache set to:', latestData);
      return objCache;
    });

    return promise;
  }

  /**
   * Synchronizes data from objCache to all registered storageServices
   * @return {Promise<Object>} A Promise holding the status of the sync process(es)
   */
  function syncUp() {
    // log.debug('dataService: syncUp called');

    if (veHelpers.isEmpty(changedData)) {
      // log.info('dataService: syncUp called without local changes');
      return Promise.resolve('dataService: syncUp called without local changes, will do nothing.');
    }

    if (veHelpers.isEmpty(storageServices)) {
      return Promise.resolve('dataService: synUp called withot subscribers, will do nothing.');
    }

    //if there are localChanges, syncUp copies changed local data -> all storageServices
    var totalResolved = 0;
    var totalRejected = 0;
    var status = {};

    var result = new Promise(function (resolve, reject) {
      storageServices.forEach(function (service) {
        service.saveUserData(changedData).then(function (successData) {
          totalResolved += 1;
          status[service.name] = {status: 'success', data: successData}
        }).catch(function (errorData) {
          totalRejected += 1;
          status[service.name] = {status: 'error', error: errorData}
        }).then(function (data) {
          if (totalResolved + totalRejected == storageServices.length) {
            changedData = {};
            resolve(status);
          }
        });
      });
    });
    return result;
  }

  /**
  * Compares two data objects by timestamp for sorting, i.e. finding the latest
  * data. Will sort by obj.data.timestemp descending. So when calling myArray.sort(compareTimestamp)
  * myArray[0] will be the latest data
  * @param  {[type]} storageResult1 [description]
  * @param  {[type]} storageResult2 [description]
  * @return {[type]}       [description]
  */
  function compareTimestamps(storageResult1, storageResult2) {
    //enable sorting if there is no timestamp
    storageResult1.data = storageResult1.data || {timestamp: 0};
    storageResult2.data = storageResult2.data|| {timestamp: 0};
    storageResult1.data.timestamp = storageResult1.data.timestamp || 0;
    storageResult2.data.timestamp = storageResult2.data.timestamp || 0;
    return storageResult2.data.timestamp - storageResult1.data.timestamp;
  }

  function compareTimestampsNew(data1, data2) {
    data1.timestamp = data1.timestamp || 0;
    data2.timestamp = data2.timestamp || 0;
    return data2.timestamp - data1.timestamp;
  }

  function test() {
    subscribe(new djangoStorageService());
    subscribe(new localStorageService());
    subscribe(new failService());
    subscribe(new latestStorageService());
    updateUserData(
      {
        test: 'somedata',
        timestamp: Date.now(),
        scores: [
          {"points":99,"siteuxid":"VBKM01_VariablenTerme","state":1,"maxpoints":4,"section":1,"id":"lol2","uxid":"ERX12","intest":false,"rawinput":"1/4*pi*x*x*x","value":0},
          {"points":999,"siteuxid":"VBKM01_VariablenTerme","state":1,"maxpoints":4,"section":1,"id":"lol1","uxid":"ERX12","intest":false,"rawinput":"1/4*pi*x*x*x","value":0}
        ]
      });
    return getAllUserData().then(function(allUserData) {
      return sync();
    });
  }

  function unsubscribe(observable) {
    for(var i = storageServices.length - 1; i >= 0; i--) {
        if(storageServices[i].name === observable.name) {
           storageServices.splice(i, 1);
        }
    }
    delete storageServicesMap[observable.name];
  }

function getAllUserData() {
  var returnedPromises = 0;
  var allUserData = [];

  var result = new Promise(function (resolve, reject) {
    if (storageServices.length == 0) {
      reject('no storageServices we could get the data from, register them first' 
      + ' by calling dataService.subscribe(yourStorageServiceName)');
    }
    storageServices.forEach(function (service) {
      service.getUserData().then(function (successData) {
        allUserData.push({
          status: 'success',
          data: successData,
          serviceName: service.name
        });
      }).catch(function (errorData) {
        allUserData.push({
          status: 'error',
          message: errorData,
          serviceName: service.name
        })
      }).then(function (data) {
        returnedPromises += 1;
        if (returnedPromises == storageServices.length) {
          resolve(allUserData);
        }
      });
    });
  });

  return result;
}


function getAllDataTimestamps() {
  var returnedPromises = 0;
  var failCount = 0;
  var successCount = 0;
  var allTimestamps = [];

  // var result = new Promise(function (resolve, reject) {
  //   if (storageServices.length == 0) {
  //     reject('no storageServices we could get the data from, register them first' 
  //     + ' by calling dataService.subscribe(yourStorageServiceName)');
  //   }
  if (storageServices.length == 0) {
    return Promise.reject(new TypeError('no storageServices we could get data from' +
      'register them by calling dataService.subscribe(yourStorageService)'));
  }
  // return Promise.all(storageServices.map(function(promise) {
  //   //will call getDataTimestamp and reflect will make rejected promises not reject but resolve
  //   //with error status
  //   return promise.getDataTimestamp().reflect();
  // }));
  var result = new Promise(function (resolve, reject) {
    storageServices.forEach(function (service) {
      // console.log('calling getDataTimestamp at', service.name);
      service.getDataTimestamp().then(function (successData) {
        // console.log('getDataTimestamp success:', service.name);
        successCount += 1;
        var status = {
          status: 'success',
          timestamp: successData,
          serviceName: service.name
        };
        allTimestamps.push(status);
        // console.log('successCount', successCount);
        return status;
      }, function (errorData) {
        failCount += 1;
        var status = {
          status: 'error',
          message: errorData,
          serviceName: service.name,
          //a timestamp of 0 is like very old data
          //TODO what if all error? then we have no data, anyhow localstorage will
          //not error usually...
          timestamp: 0
        };
        allTimestamps.push(status);
        // console.log('errorCount', failCount);
        return status;
      }).then(function (data) {
        returnedPromises += 1;
        // console.log('datadata', data);
        // console.log('returned promises:', returnedPromises);
        if (returnedPromises == storageServices.length) {
          if (failCount == storageServices.length) {
            //all requests failed
            reject(new TypeError('Requests to all registered storageServices failed in getAllDataTimestamps'));
          } else {
            resolve(allTimestamps);
          }
        }
      });
    });
  });

  return result;
}

/**
* Get the current User Data
* @return {Promise<Object>} A Promise containing the UserData Object
*/
function getUserData() {
  if (objCache !== null && !veHelpers.isEmpty(objCache)) {
    return Promise.resolve(objCache);
  } else {
    return syncDown().then(function(data) {
      return data;
    });
  }
}

var USER_CREDENTIALS_KEY = 've_user_credentials';
var SCORES_KEY = 've_scores'

init();

/**
* will load existing scores from the passed intersiteObj, as we can see this class
* depends on intersite (by now), this dependency is only because of persistence reasons now
* and shall be removed in further iterations
* @return {[type]} [description]
*/
function init( options ) {
  // Merge user options with defaults
  //settings = $.extend( defaults, options || {} );
}

/**
 * Recursively merges two objects (in place). Will insert respective objects from obj2 into
 * obj1 if the specified id is not present in obj1. Will update objects in obj1
 * if id is already present. Contains a switch for matching 'id' (on
 * scores) and 'uxid' (on sites).
 *
 * The heart of objCache storage.
 *
 * TODO: data model should be changed from js Array to js Object (better performance)
 * TODO: should this return the diff of the two objects? Would save one call to mergeRecursive
 * that is made again with localChanges
 *
 * @param  {Object} obj1 Complex Javascript object to be merged into.
 * @param  {Object} obj2 Complex Javascript object to be merged
 * @return {Object}      The merge result of obj1 and obj2, with updated/inserted
 * values
 */
function mergeRecursive(obj1, obj2, changedData) {
  if (Object.prototype.toString.call( obj1 ) === '[object Array]') {
    for (var i = 0; i < obj1.length; i++) {
      if (obj1[i].id == obj2.id) {
        //we update the object
        for(var key in obj2) {
          if(obj2.hasOwnProperty(key)) {
            obj1[i][key] = obj2[key];
          }
        }
        return obj1;
      }
    }
    //insert in array
    obj1.push(obj2);
    return obj1;
  }
  for (var p in obj2) {
    //merging array
    if (Object.prototype.toString.call( obj2[p] ) === '[object Array]') {
      obj1[p] = typeof obj1[p] === 'undefined' ? [] : obj1[p];
      obj2[p].forEach(function(arrayElement) {
        obj1[p] = mergeRecursive(obj1[p], arrayElement);
      });
    //merging object
    } else if (Object.prototype.toString.call ( obj2[p] ) === '[object Object]') {
      obj1[p] = typeof obj1[p] === 'undefined' ? {} : obj1[p];
      obj1[p] = mergeRecursive(obj1[p], obj2[p]);
    } else {
      obj1[p] = obj2[p];
    }
  }
  return obj1;
}

function getChangedData() {
  return changedData;
}
function getObjCache() {
  return objCache;
}

function mockLocalStorage() {
  var mock = (function() {
    var storage = {};
    return {
      setItem: function(key, value) {
        storage[key] = value || '';
      },
      getItem: function(key) {
        return storage[key] || null;
      },
      removeItem: function(key) {
        delete storage[key];
      },
      get length() {
        return Object.keys(storage).length;
      },
      key: function(i) {
        var keys = Object.keys(storage);
        return keys[i] || null;
      }
    };
  })();

  localStorage = mock;
}

// attach properties to the exports object to define
// the exported module properties.
exports.init = init;
exports.test = test;
exports.djangoStorageService = djangoStorageService;
exports.localStorageService = localStorageService;
exports.subscribe = subscribe;
exports.unsubscribe = unsubscribe;
exports.unsubscribeAll = function () { storageServices = []; storageServicesMap = {}; };
exports.getSubscribers = function () { return storageServices };
exports.getAllUserData = getAllUserData;
exports.getAllDataTimestamps = getAllDataTimestamps;
exports.getUserData = getUserData;
exports.sync = sync;
exports.syncDown = syncDown;
exports.syncUp = syncUp;
exports.updateUserData = updateUserData;
exports.updateScores = updateScores;
exports.getChangedData = getChangedData;
exports.emptyChangedData = function () { changedData = {}; };
exports.getObjCache = getObjCache;
exports.mergeRecursive = mergeRecursive;
exports.mockLocalStorage = mockLocalStorage;

}));
