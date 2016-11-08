/* from https://github.com/umdjs/umd/blob/master/templates/commonjsStrictGlobal.js */

(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'veHelpers', 'loglevel'], function (exports, veHelpers, log) {
      factory((root.dataService = exports), veHelpers, log);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports, require('./veHelpers.js'), require('loglevel'));
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

  var doAsyncCalls = 'true';

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

	init();

	/**
	* will load existing scores from the passed intersiteObj, as we can see this class
	* depends on intersite (by now), this dependency is only because of persistence reasons now
	* and shall be removed in further iterations
	* @return {[type]} [description]
	*/
	function init( options ) {
// 		subscribe(LocalStorageService.LocalStorageService());
// 		subscribe(DjangoStorageService.DjangoStorageService());

// 		DjangoAuthService.authenticate({
// 			username: 'testrunner',
// 			password:'<>87c`}X&c8)2]Ja6E2cLD%yr]*A$^3E'
// 		});
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

  //sync on startup
  //on time
  //only the diff should be sent to server (whyever)
  //most recent version should be saved

  function subscribe (observable) {
    storageServices.push(observable);
    storageServicesMap[observable.name] = observable;
  }

  /**
   * Synchronizes data from servers / other storages to objCache. Will automatically
   * consider only the latest data for downloading.
   * @return {Promise} A promise holding the userData.
   */
  function syncDown() {

    if (storageServices.length === 0) {
      return Promise.resolve('dataService: synDown called without subscribers, will do nothing.');
    }

    log.debug('dataService: syncDown is calling getAllDataTimestamps');
    var promise = getAllDataTimestamps().then(function (successAllTimestamps) {

      if (Array.isArray(successAllTimestamps) && successAllTimestamps.length > 0) {
        successAllTimestamps.sort(compareTimestamps);

        log.debug('services returned the timestamps:', successAllTimestamps);
        log.debug('latest data was found at the service:', successAllTimestamps[0]);
        var latestTimestampData = successAllTimestamps[0];
        //return the userdata Promise from the service where the latest data was found
        //by comparing the timestamps
        return storageServicesMap[latestTimestampData.serviceName].getUserData();
      } else {
        return Promise.reject(new TypeError('getAllDataTimestamps did not return an Array.'));
      }
    }).then(function(latestData) {
      objCache = latestData;
      //if there were localChanges merge them, so they are not lost
      if (!veHelpers.isEmpty(changedData)) {
        objCache = mergeRecursive(objCache, changedData);
      }
      log.debug('latestData retrieved and objCache set to:', latestData);

      //trigger an asynchronous call to replicate obj cache to other storages
      //TODO only if they are empty (by timestamp)
      syncUp(objCache);

      return objCache;
    }, function(error) {
      return new TypeError(error);
    });

    return promise;
  }

  /**
   * Synchronizes data from objCache to all registered storageServices
   * @param  {Object} data If data is set, it will be the data that is synced,
   * default is changedData, in some cases we might however want to sync e.g.
   * the whole object cache. We can pass it to sync up as data parameter.
   * @return {Promise<Object>} A Promise holding the status of the sync process(es)
   */
  function syncUp(data) {

    data = typeof data !== "undefined" ? data : changedData;

    log.debug('syncUp called data:', data);

    if (veHelpers.isEmpty(data)) {
      // log.info('dataService: syncUp called without local changes');
      return Promise.resolve('dataService: syncUp called without local changes, will do nothing.');
    }

    if (veHelpers.isEmpty(data)) {
      return Promise.resolve('dataService: synUp called withot subscribers, will do nothing.');
    }

    //if there are localChanges, syncUp copies changed local data -> all storageServices
    var totalResolved = 0;
    var totalRejected = 0;
    var status = {};

    var result = new Promise(function (resolve, reject) {
      storageServices.forEach(function (service) {
        service.saveUserData(data, doAsyncCalls).then(function (successData) {
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
  * data. Will sort by data.timestemp descending. So when calling myArray.sort(compareTimestamps)
  * myArray[0] will be the latest data
  * @param  {[type]} storageResult1 [description]
  * @param  {[type]} storageResult2 [description]
  * @return {[type]}       [description]
  */
  function compareTimestamps(data1, data2) {
    data1.timestamp = data1.timestamp || 0;
    data2.timestamp = data2.timestamp || 0;
    return data2.timestamp - data1.timestamp;
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

function makeSynchronous() {
  doAsyncCalls = false;
}

// attach properties to the exports object to define
// the exported module properties.
exports.init = init;
exports.makeSynchronous = makeSynchronous;
exports.subscribe = subscribe;
exports.unsubscribe = unsubscribe;
exports.unsubscribeAll = function () { storageServices = []; storageServicesMap = {}; };
exports.getSubscribers = function () { return storageServices };
exports.getAllUserData = getAllUserData;
exports.getAllDataTimestamps = getAllDataTimestamps;
exports.getUserData = getUserData;
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
