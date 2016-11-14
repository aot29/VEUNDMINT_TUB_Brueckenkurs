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
    alwaysSynchronize : true,
    USER_DATA_CACHE_KEY: 've_user_data'
  };

  var doAsyncCalls = 'true';

  var storageServices = [];
  var storageServicesMap = {};
  var syncStrategies = ['timer', 'onunload']

  //the 'cache' for all userData
  var objCache = {
    scores: []
  };

  /**
   * We use a cache for promises, too. By that we can return pending promises, instead
   * of having to make new calls each time. Example: input A and input B request
   * the userData in order to set the input value depending on previously entered text.
   * input A calls getUserData, and input B as well. Instead of issuing two (expensive)
   * requests, we can just return the promise from the cache, if it is there.
   * Should not be used by other modules.
   * @type {Object}
   */
  var promiseCache = {};

  /**
   * Stores the changed data, since objCache is always 'synced' but too large
   * this variable stores recent, unsynced changes and will be reset on successful
   * sync operation
   * @type {Object}
   */
  var changedData = {};

	/**
	* Will load existing scores from the passed intersiteObj, as we can see this class
	* depends on intersite (by now), this dependency is only because of persistence reasons now
	* and shall be removed in further iterations
	* @return {[type]} [description]
	*/
	function init( options ) {
    importUserData();
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

  /**
   * Add a storage service to the list of subscribed storageServices. All subscribers
   * will be called if userData is resolved / updated. Also all subscribers will be called
   * when feedback is sent.
   * @param  {[type]} observable [description]
   * @return {[type]}            [description]
   */
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
    var userDataPromise = getAllDataTimestamps().then(function (successAllTimestamps) {

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
      if (null !== latestData) {
        syncUp(objCache);
      }

      //empty the promise cache for user data
      delete promiseCache[defaults.USER_DATA_CACHE_KEY];
      return objCache;
    }, function(error) {
      return new TypeError(error);
    });

    //put the promise in the cache
    promiseCache[defaults.USER_DATA_CACHE_KEY] = userDataPromise;

    return userDataPromise;
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

    if (veHelpers.isEmpty(storageServices)) {
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

function getAllDataTimestamps() {
  var returnedPromises = 0;
  var failCount = 0;
  var successCount = 0;
  var allTimestamps = [];

  if (storageServices.length == 0) {
    return Promise.reject(new TypeError('no storageServices we could get data from' +
      'register them by calling dataService.subscribe(yourStorageService)'));
  }

  var result = new Promise(function (resolve, reject) {
    storageServices.forEach(function (service) {
      service.getDataTimestamp().then(function (successData) {
        successCount += 1;
        var status = {
          status: 'success',
          timestamp: successData,
          serviceName: service.name
        };
        allTimestamps.push(status);
        return status;
      }, function (errorData) {
        failCount += 1;
        var status = {
          status: 'error',
          message: errorData,
          serviceName: service.name,
          timestamp: 0
        };
        allTimestamps.push(status);
        return status;
      }).then(function (data) {
        returnedPromises += 1;
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
* Get the current User Data. Returns a promise that either holds userData directly
* from objCache if available, else it looks if a promise is pending in promiseCache
* and returns that if it is. Else it returns the promise of syncdown;
* @return {Promise<Object>} A Promise containing the UserData Object
*/
function getUserData() {
  log.debug('getUserData objCache is', objCache);
  if (objCache !== null && !veHelpers.isEmpty(objCache) && !veHelpers.isEmpty(objCache.scores)) {
    return Promise.resolve(objCache);
  } else {
    if (veHelpers.isEmpty(promiseCache[defaults.USER_DATA_CACHE_KEY])) {
      return syncDown().then(function(data) {
        return data;
      });
    } else {
      return promiseCache[defaults.USER_DATA_CACHE_KEY];
    }
  }
}

/**
 * Send user feedback to all subscribed storageServices. Calls 'sendUserFeedback'
 * function on all subscribed services.
 * @param  {Object} data The feedback data to send.
 * @return {void}
 */
function sendUserFeedback(data) {
  storageServices.forEach(function (service) {
    //TODO this should actually call the super function as soon as we implement
    //real inheritance
    if (typeof service.sendUserFeedback !== "undefined") {
      service.sendUserFeedback(data);
    }
  });
}

/**
 * Check at the subscribed storageService if a username is available. Will
 * consider the service in storageServices with the lowest index, that offers
 * the 'usernameAvailable' function
 * @return {Boolean} true if username is available, false if already taken
 */
function usernameAvailable(username) {
  var result = new Promise(function (resolve, reject) {
    storageServices.forEach(function (service) {
      if (typeof service.usernameAvailable !== "undefined") {
        resolve(service.usernameAvailable(username));
      }
    });
    reject(new TypeError('No service found with usernameAvailable function'));
  })
  return result;
}


/**
 * Imports old userdata (which was stored under a different key or had a different datastructure)
 * into the dataservice and persists it to all registered subscribers
 * @return {Object} An object giving information about the status of the import
 */
function importUserData() {
  //first try to find old userData which was either stored in localStorage
  //under an empty keyname or a keyname depending on the course
  var key1 = "";
  try {
    var key2 = "isobj_" + signature_main;
  } catch (err) {
    //we dont have global signature_main in test only in browser, assume test
    var key2 = "isobj_MFR-TUB";
  }

  if (typeof(localStorage) === "undefined") {
    return {status: 'error', message: 'no localstorage'};
  }

  oldUserData1 = localStorage.getItem(key1);
  oldUserData2 = localStorage.getItem(key2);

  //check the structure
  if (oldUserData1 !== null) {
    oldUserData1.correctStructure = checkUserDataStructure(oldUserData1);
  }
  if (oldUserData2 !== null) {
    oldUserData2.correctStructure = checkUserDataStructure(oldUserData2);
  }

  if(oldUserData1 && oldUserData2 && oldUserData1.correctStructure && oldUserData2.correctStructure) {
    //we chose to pick the user data with more saved scores, as that eventually is
    //the metric users are interested in
    var importableData = oldUserData1.scores.length > oldUserData2.scores.length ? oldUserData1 : oldUserData2;
  } else if (oldUserData1 && oldUserData1.correctStructure) {
    importableData = oldUserData1;
  } else if (oldUserData2 && oldUserData2.correctStructure) {
    importableData = oldUserData2;
  } else {
    return {
      status: 'success',
      message: 'no obj found for import'
    }
  }

  //construct an object of data we are interested in
  var objToImport = {
    scores:[]
  }

  for (var i = 0; i < importableData.scores.length; i++) {
    objToImport.scores.push(importableData.scores[i]);
  }

  //import it
  mergeRecursive(changedData, objToImport);

  //delete the old object that it is not imported again
  localStorage.removeItem(key1);
  localStorage.removeItem(key2);

  return {
    status: 'success',
    imported: objToImport,
    found: {
      key1: oldUserData1,
      key2: oldUserData2
    }
  }
}

/**
 * Private function that checks if the userData has the correct structure
 * @param  {Object} userData The user data Object to check
 * @return {Boolean}         true if it has the correct structure
 */
function checkUserDataStructure(userData) {
  if (userData === null || typeof (userData) === "undefined") {
    return false;
  }
  try {
    if (userData.scores.length !== 0 &&
        userData.login &&
        userData.history) {
          return true;
      }
  } catch (err) {
    return false
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

/**
 * Mocks the browsers localstorage. Used in non browser Environments (e.g. node tests)
 * @return {[type]} [description]
 */
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
  return localStorage;
}

/**
 * Make all calls synchronous instead of asynchronous
 * @return {[type]} [description]
 */
function makeSynchronous() {
  doAsyncCalls = false;
}

// attach properties to the exports object to define
// the exported (public) module properties.
exports.init = init;
exports.makeSynchronous = makeSynchronous;
exports.subscribe = subscribe;
exports.unsubscribe = unsubscribe;
exports.unsubscribeAll = function () { storageServices = []; storageServicesMap = {}; };
exports.getSubscribers = function () { return storageServices };
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
exports.sendUserFeedback = sendUserFeedback;
exports.usernameAvailable = usernameAvailable;
exports.importUserData = importUserData;

}));
