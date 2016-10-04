//https://github.com/umdjs/umd/blob/master/templates/commonjsStrictGlobal.js

(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'b'], function (exports) {
      factory(root.scormBridge = exports);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports);
  } else {
    // Browser globals
    factory(root.scormBridge = {});
  }
}(this, function (exports) {

  /*
  * Module scormBridge
  *
  * Handles Scorm API connection initialization and makes sure that the API is not called when not
  * initialized. Offers many helper functions for working with the scorm API.
  *
  * There was no findable other way than storing the pipwerks object in localstorage to prevent
  * calling connection.initialize multiple times which would error. We so can keep the connection
  * alive even between page changes (basically a persisted singleton)
  *
  */

  log.info('scormBridge.js loaded');

  //stores if we are in an scorm environment
  var isScormEnv = false;

  var scormVersion = null;
  var scormData = {};

  /**
  * Initializes the scormBridge only aftwards calling pipwerks API is safe.
  *
  * Note: The process of initializing in scorm 1.2 is quite stupidly designed and was not easy to
  * get working, as there are no pipwerks API examples and the API is not well designed either.
  * We first need to set the handle to the result of pipwerks.SCORM.API.get(), otherwise later things
  * will fail, then wee need to call the function LMSInitialize() as it is the only found function
  * capable of not failing and destroying the API when called if already initialized before...
  * The way it is solved is a hack (altering the pipwerks object all the time), but was still easier than
  * writing our own API, which should be done. I hope that this will also work with SCORM 2004, maybe it
  * is just an issue of scorm 1.2 which is outdated anyway and only used by matet.
  */
  function init() {
    log.setLevel('debug');

    //search for the API first, here we have to use get because find did not set the API.isFound to true (no comment)
    pipwerks.SCORM.API.handle = pipwerks.SCORM.API.get();


    if (pipwerks.SCORM.API.isFound) {
      log.info('scormBridge.js init: SCORM API found');

      // the function LMSInitialize will return "true" if it was called for the first time, i.e. it was just initialized
      // afterwards it is always active which pipwerks does not know so we have to tell it manually
      var initializedAgain;
      if (pipwerks.SCORM.version == "2004") {
        initializedAgain = JSON.parse(pipwerks.SCORM.API.handle.Initialize(""));
      } else if (pipwerks.SCORM.version == '1.2') {
        initializedAgain = JSON.parse(pipwerks.SCORM.API.handle.LMSInitialize(""));
      }

      pipwerks.SCORM.connection.isActive = true;
      scormVersion = pipwerks.SCORM.version;

      if (initializedAgain == true) {
        log.info('scormBridge.js init: LMS connection was initialized and is now active');
      } else {
        log.info('scormBridge.js init: LMS connection was already active');
      }

      isScormEnv = true;


    } else {
      log.info('scormBridge.js init: SCORM API NOT found');
      isScormEnv = false;
    }
  }

  /**
  * Returns true if we are in an active scorm Environemnt (e.g. moodle)
  * and also true if we have the fake moodle env running (coming soon :)
  */
  function isScormEnvActive() {
    return isScormEnv;
  }

  function getScormVersion() {
    return scormVersion;
  }

  function getScormData() {
    return scormData;
  }

  /**
  * Getter functions
  */
  function getStudentId() {
    return gracefullyGet('cmi.core.student_id', 'cmi.learner_id', 'id');
  }

  function getStudentName() {
    return gracefullyGet('cmi.core.student_name', 'cmi.learner_name', 'name');
  }


  /**
  * Helper function to get a scorm value, update the local scorm object and log to the console
  */
  function gracefullyGet(scorm12parameter, scorm2004parameter, localObjectId) {
    var result;
    var apiParameter = '';
    if (isScormEnv) {
      if (scormVersion == "2004") {
        apiParameter = scorm2004parameter;
      } else if (scormVersion == "1.2") {
        apiParameter = scorm12parameter;
      } else {
        log. warn('scormBridge.js: gracefullyGet called on unknown Scorm version with parameters:', scorm12parameter, ", ", scorm2004parameter);
      }
      result = pipwerks.SCORM.get(apiParameter);

      if (typeof localObjectId !== "undefined") {
        scormData[localObjectId] = result;
      } else {
        scormData[apiParameter] = result;
      }
    } else {
      log.warn('scormBridge.js: calling gracefullyGet with parameters:', scorm12parameter, scorm2004parameter, ' when not in scorm Environment');
    }
    return result;
  }

  /**
  * Send the updated user scores to SCORM, called in intersite.pushIso when site is unloaded.
  * @param  {Object} scoreobj The updated (recent) scores object that should be used for
  * updateing SCORM
  * @return {Boolean} true if the updateProcess was successful
  */
  function updateCourseScore(scoreObj) {
    log.debug( "scormBridge.js: updateCourseScore called with scoreObj:", scoreObj);

    updateSuccessful = false;

    if (isScormEnv) {
      log.debug( "Updating SCORM transfer object");
      nmax = 0;
      ngot = 0;

      //take all scores from exercices that were defined to
      //be in tests (intest) and add them together.
      for (j = 0; j < scoreObj.length; j++) {
        if (scoreObj[j].intest) {
          nmax += scoreObj[j].maxpoints;
          ngot += scoreObj[j].points;
        }
      }

      //update corresponding course data in SCORM
      updateSuccessful = set("cmi.core.score.raw", ngot);
      log.debug( "SCORM set points to " + ngot + ": " + updateSuccessful);

      updateSuccessful &= set("cmi.core.score.min", 0);
      log.debug( "SCORM set min points to 0: " + updateSuccessful);

      updateSuccessful &= set("cmi.core.score.max", nmax);
      log.debug( "SCORM set max points to " + nmax + ": " + updateSuccessful);

      var s = "browsed";
      if (ngot > 0) {
        if (ngot == nmax) {
          s = "completed";
        } else {
          s = "incomplete";
        }
      }
      psres = set("cmi.core.lesson_status", s);
      log.debug( "SCORM set status to " + s + ": " + psres);
    }

    return updateSuccessful;
  }

  // attach properties to the exports object to define
  // the exported module properties (publicly callable)
  exports.init = init;
  exports.isScormEnv = isScormEnvActive;

  exports.getScormData = getScormData;
  exports.gracefullyGet = gracefullyGet;
  exports.get = pipwerks.SCORM.get;
  exports.set = pipwerks.SCORM.set;
  exports.getScormVersion = getScormVersion;
  exports.getStudentName = getStudentName;
  exports.getStudentId = getStudentId;

  exports.updateCourseScore = updateCourseScore;

}));
