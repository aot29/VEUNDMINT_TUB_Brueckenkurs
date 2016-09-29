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
	 * Class scormBridge
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

  const SCORM_OBJ_KEY = 'scormBridge';

	var apiInitialized = false;

  var scormBridge;

	var isScormEnv = false;
	var scormVersion = null;
	var scormData = {};


	function init() {

    scormBridge = localStorage.getItem(SCORM_OBJ_KEY);

		//find out if we are on scorm on initialization
		isScormEnvActive();
		getScormVersion();

		log.info('scormBridge.js initialization started');

    if (isScormEnvActive()) {
      $(window).on('beforeunload', function(event) {
        localStorage.setItem(SCORM_OBJ_KEY, JSON.stringify(pipwerks.SCORM));
      });
    }

		//initialization of pipwerks API
		pipwerks.SCORM.init(window);
	}

	/**
	 * Returns true if we are in an actime scorm Environemnt (e.g. moodle)
	 * and also true if we have the fake moodle env running (coming soon :)
	 */
	function isScormEnvActive() {

    //if there is an active connection we overwrite the pipwerks.SCORM API object
    //thet lets us communicate with the LMS
    if (scormBridge != null) {
      pipwerks.SCORM = JSON.parse(scormBridge);
    }

		//this should always be either true or false (see pipwerks)
		var _isScormEnv = pipwerks.SCORM.API.isFound;
		isScormEnv = _isScormEnv;
		return isScormEnv;
	}

	function getScormVersion() {
		if (isScormEnv) {
			_scormVersion = pipwerks.SCORM.version;
			scormVersion = _scormVersion;

			//this makes sure that pipwerks.SCORM.init is not called twice on 1.2 which results in errors over errors.
			if (scormVersion == "1.2") {
				pipwerks.SCORM.version = "1.2"
			}

		} else {
			log.warn('scormBridge.js: calling getScormVersion when not in scorm Environment');
		}
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
		return gracefullyGet('cmi.core.student_name', 'cmi.learner.name', 'name');
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
   * Private Functions
   */

  function initializeConnection() {

  }



  // attach properties to the exports object to define
  // the exported module properties.
  exports.init = init;
	exports.isScormEnv = isScormEnvActive;
	exports.getScormData = getScormData;
	exports.gracefullyGet = gracefullyGet;
	exports.getScormVersion = getScormVersion;
	exports.getStudentName = getStudentName;
	exports.getStudentId = getStudentId
}));
