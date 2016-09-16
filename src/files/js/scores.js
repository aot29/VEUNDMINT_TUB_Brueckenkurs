(function (root, factory) {
    if (typeof define === 'function' && define.amd) {
        // AMD. Register as an anonymous module.
        define(['exports'], function (exports) {
            factory((root.scores = exports));
        });
    } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
        // CommonJS
        factory(exports);
    } else {
        // Browser globals
        factory(root.scores = {});
    }
}(this, function (exports) {

    log.info('scores.js loaded');

    const SCORES_LS_KEY = 'veundmint_scores';

    var scoresObj;

    //init();

    /**
     * will load existing scores from the passed intersiteObj, as we can see this class
     * depends on intersite (by now), this dependency is only because of persistence reasons now
     * and shall be removed in further iterations
     * @return {[type]} [description]
     */
    function init() {

      //register handlers
      $(window).on('beforeunload', function(){
         alert('scores persisted');
      	 persist();
      });

      if (typeof scoresObj === "undefined") {
        var lsString = getScoresFromLocalStorage();
        scoresObj = JSON.parse(lsString);
        if (scoresObj === null) {
          scoresObj = {};
        }
      }
    }

    function getScoresFromLocalStorage() {
      return localStorage.getItem(SCORES_LS_KEY);
    }

    /**
     * PERSISTENCE is currently handled by each time setting the scores attribute of intersiteObj
     * to the scores. Later we would want to have many single objects in localstorage like (settings,
     * scores, profile) in order to not having to load the whole stuff always
     */
    function persist() {

    }

    /**
     * simply returns the scoresObj, later this should look first in attribute,
     * if empty in localStorage and if that is empty
     * send a request to the server
     * @return {[type]} [description]
     */
    function getAllScores() {
      return scoresObj;
    }

    /**
     * Get a scingle score by questionId, same applies than above
     * @param  {[type]} questionUxid Hopefully its the uxid that we need to pass
     * @return Either the score object or undefined if the key was not found
     */
    function getSingleScore(questionId) {
      log.debug('scores: getting single score for question id', questionId, ' on scoresObj', scoresObj);
      return scoresObj[questionId];
    }


    /**
     * Sets the score of a particular question to a new Value
     * @param  {[type]} questionId     [description]
     * @param  {[type]} singleScoreObj What was defined by DS as a complex object
     *                                 that stores complex data and looks e.g. like
     * {
        "uxid":"VBKM01_USR1",
        "maxpoints":4,
        "points":0,
        "siteuxid":"VBKM01_USBrueche",
        "section":1,
        "id":"QFELD_1.2.3.QF2",
        "intest":false,
        "value":0,
        "rawinput":"",
        "state":3
      }
     */
    function setSingleScore(questionId, singleScoreObj) {
      log.debug('scores: updateScore called for question', questionId, 'with single Score Obj', singleScoreObj);
      scoresObj[questionId] = singleScoreObj;

      /**
       * this is the part that should be removed when the persist() function is ready
       */
       localStorage.setItem(SCORES_LS_KEY, JSON.stringify(scoresObj));
    }

    /**
     * Sets all scores to a new object
     *
     * should actually not be used, in favor of adding scores for a certain chapter or exercise
     * @param {[type]} scores [description]
     */
    function setScores(scoresObj) {
      scoresObj = scoresObj;
    }

    /**
     * Return the number of scores currently saved
     * @return {[type]} [description]
     */
    function length() {
      return Object.keys(scoresObj).length;
    }

    // attach properties to the exports object to define
    // the exported module properties.
    exports.init = init;
    exports.getAllScores = getAllScores;
    exports.getSingleScore = getSingleScore;
    exports.setScores = setScores;
    exports.setSingleScore = setSingleScore;
    exports.length = length;
}));
