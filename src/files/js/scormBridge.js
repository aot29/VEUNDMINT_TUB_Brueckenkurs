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

  //define relations between scorm 1.2 and 2004 api parameters.
  //WARNINT: THE SET IS NOT COMPLETE. ONLY
  //PARAMETERS USED BY VEUNDMINT ARE CURRENTLY LISTED HERE.
  //ADD NEW PARAMETERS HERE IF YOU
  //WANT TO USE THE GRACEFULLY FUNCTIONS BELOW.
  var scormActionParameters = {
    '1.2': [
      'cmi.core.student_id',
      'cmi.core.student_name',
      'cmi.core.score.raw',
      'cmi.core.score.min',
      'cmi.core.score.max',
      'cmi.core.lesson_status'
    ],
    '2004': [
      'cmi.learner_id',
      'cmi.learner_name',
      'cmi.score.raw',
      'cmi.score.min',
      'cmi.score.max',
      'cmi.completion_status'
    ]
  }

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
    return gracefullyGet('cmi.core.student_id');
  }

  function getStudentName() {
    return gracefullyGet('cmi.core.student_name');
  }


  /**
  * Get the a value from the SCORM LMS with the id: id.
  * @param  {String} id The id you want to fetch
  * @return {String}    The value the id has
  */
  function gracefullyGet(id) {
    var result;
    var versionedParameter = getVersionedParameter(id);
    if (isScormEnv) {
      result = pipwerks.SCORM.get(versionedParameter);
    }
    return result;
  }

  /**
  * Set the parameter with id to value. This function is graceful in terms of
  * automatically selecting the correct SCORM parameter depending on the active
  * scorm version. If this function is called when not in SCORM environment, it will
  * return false and log a warning, true otherwise.
  * @param  {String} id    The scorm api parameter you want to set
  * @param  {Object} value The value you want to set it to
  * @return {Boolean}      true if successful, false otherwise
  */
  function gracefullySet(id, value) {
    var result = false;
    var versionedParameter = getVersionedParameter(id);
    if (isScormEnv) {
      result = pipwerks.SCORM.set(versionedParameter, value);
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
      updateSuccessful = gracefullySet("cmi.core.score.raw", ngot);
      log.debug( "SCORM set points to " + ngot + ": " + updateSuccessful);

      updateSuccessful &= gracefullySet("cmi.core.score.min", 0);
      log.debug( "SCORM set min points to 0: " + updateSuccessful);

      updateSuccessful &= gracefullySet("cmi.core.score.max", nmax);
      log.debug( "SCORM set max points to " + nmax + ": " + updateSuccessful);

      var s = "not attempted";
      if (ngot > 0) {
        if (ngot == nmax) {
          s = "completed";
        } else {
          s = "incomplete";
        }
      }
      psres = gracefullySet("cmi.core.lesson_status", s);
      log.debug( "SCORM set status to " + s + ": " + psres);
    }

    return Boolean(updateSuccessful);
  }

  /**
   * [sendFinalTestResults description]
   * @param  {[type]} nPoints    [description]
   * @param  {[type]} nMinPoints [description]
   * @param  {[type]} nMaxPoints [description]
   * @return {[type]}            [description]
   */
  function sendFinalTestResults(nPoints, nMinPoints, nMaxPoints) {
    log.trace("ENTRYTEST geht an SCORM");
    var mx = 0;
    var mi = 0;
    var av = 0;

    psres = gracefullyGet("cmi.learner_id");
    log.trace("SCORM learner id = " + psres);
    psres = gracefullyGet("cmi.learner_name");
    log.trace("SCORM learner name = " + psres);
    psres = gracefullySet("cmi.interactions.0.id","TEST");
    log.trace("SCORM set interact_id = " + psres);
    psres = gracefullySet("cmi.interactions.0.learner_response",nPoints);
    log.trace("SCORM set interact_lr = " + psres); // false im KIT-ILIAS
    psres = gracefullySet("cmi.interactions.0.result",true);
    log.trace("SCORM set interact_res = " + psres); // false im KIT-ILIAS
    psres = gracefullySet("cmi.score.raw",nPoints);
    log.trace("SCORM set rawpoints = " + psres);
    psres = gracefullySet("cmi.score.min",nMinPoints);
    log.trace("SCORM set minpoints = " + psres);
    psres = gracefullySet("cmi.score.max",nMaxPoints);
    log.trace("SCORM set maxpoints = " + psres);
    psres = gracefullySet("cmi.score.scaled",(nPoints/nMaxPoints));
    log.trace("SCORM set scaled points = " + psres);

    psres = gracefullySet("cmi.objectives.0.id","Abschlusstests");
    log.trace("SCORM set objectives = " + psres);
    psres = gracefullySet("cmi.objectives.0.raw",nPoints);
    log.trace("SCORM set obrawpoints = " + psres); // false im KIT-ILIAS
    psres = gracefullySet("cmi.objectives.0.min",nMinPoints);
    log.trace("SCORM set obminpoints = " + psres); // false im KIT-ILIAS
    psres = gracefullySet("cmi.objectives.0.max",nMaxPoints);
    log.trace("SCORM set obmaxpoints = " + psres); // false im KIT-ILIAS
    psres = gracefullySet("cmi.objectives.0.scaled",(nPoints/nMaxPoints));
    log.trace("SCORM set obscaled = " + psres); // false im KIT-ILIAS
    psres = gracefullySet("cmi.objectives.0.completion_status", (nPoints>=nMinPoints) ? ("completed") : ("incomplete") );
    log.trace("SCORM set obcompletion " + psres);

    psres = gracefullySet("cmi.scaled_passed_score", nMinPoints/nMaxPoints);
    log.trace("SCORM set obscossc " + psres); // false im KIT-ILIAS
    psres = gracefullySet("cmi.score", nPoints/nMaxPoints );
    log.trace("SCORM set obscore " + psres); // false im KIT-ILIAS


    psres = gracefullySet("cmi.progress_measure",(nPoints/nMaxPoints));
    log.trace("SCORM set progress measure = " + psres); // false im KIT-ILIAS
    psres = gracefullySet("cmi.success_status", (nPoints>=nMinPoints) ? ("passed") : ("failed") );
    log.trace("SCORM set obcomp = " + psres); // false im KIT-ILIAS
    psres = gracefullySet("cmi.completion_status", (nPoints>=nMinPoints) ? ("completed") : ("incomplete") );
    log.trace("SCORM set completion " + psres);
    psres = pipwerks.SCORM.save();
    log.debug("SCORM save = " + psres);

    if (psres) {
      return $.i18n("msg-transfered-result")+"\n"; // Die Punktzahl wurde zur statistischen Auswertung übertragen
    }
  }


  /*************************
  ******** private functions
  *************************/


  /**
  * Get the SCORM parameter of the active scorm version automatically. Used
  * by gracefullyGet and gracefullySet functions.
  * @param  {String} parameter The unversioned scorm api parameter
  * @return {String}           The versioned scorm api parameter
  */
  function getVersionedParameter (parameter) {

    //return early
    if (scormVersion === null || ['2004', '1.2'].indexOf(scormVersion) === -1) {
      log.warn('scormBridge.js getVersionedParameter: called with unsupported or not active scormVersion');
      return null;
    }

    var found = false;

    //this will be returned, so if the parameter is not in the scormActionParamters array above
    //it will still return the supplied parameter
    var versionedParameter = parameter;

    var idxInActiveVersion = scormActionParameters[scormVersion].indexOf(parameter);

    if ( idxInActiveVersion === -1 ) {
      //if not found in active version look if it's in inactiveVersion
      var otherScormVersion = scormVersion === '2004' ? '1.2' : '2004';
      var idxInOtherVersion = scormActionParameters[otherScormVersion].indexOf(parameter);
      if (idxInOtherVersion !== -1) {
        //it was found in the other scorm version but uses the wrong api Parameter version, so use the right one
        versionedParameter = scormActionParameters[scormVersion][idxInOtherVersion];
        log.info('scormBridge.js: getVersionedParameter changed parameter from:', parameter, ' to:', versionedParameter);
        found = true;
      }
    } else {
      found = true;
    }

    if (!found) {
      log.warn('scormBridge.js: getVersionedParameter called with unknown parameter:', parameter);
    }
    return versionedParameter;
  }

  // attach properties to the exports object to define
  // the exported module properties.
  exports.init = init;
  exports.isScormEnv = isScormEnvActive;
  exports.getScormData = getScormData;
  exports.gracefullyGet = gracefullyGet;
  exports.gracefullySet = gracefullySet;
  exports.get = pipwerks.SCORM.get;
  exports.set = pipwerks.SCORM.set;
  exports.save = pipwerks.SCORM.save;
  exports.getScormVersion = getScormVersion;
  exports.getStudentName = getStudentName;
  exports.getStudentId = getStudentId;

  exports.updateCourseScore = updateCourseScore;

  exports.getVersionedParameter = getVersionedParameter;
}));
