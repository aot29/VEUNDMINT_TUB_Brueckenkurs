(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'loglevel'], function (exports, log) {
      factory((root.ui = exports), log);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports, require('loglevel'));
  } else {
    // Browser globals
    factory((root.ui = {}), root.log);
  }
}(this, function (exports, log) {

  log.debug('ui.js: loaded');
  //use b in some fashion.
  //
  //

  /**
  * Throttle the execution of functions by only allowing execution every
  * ms milliseconds
  */
  var delay = (function(){
    var timer = 0;
    return function(callback, ms){
      clearTimeout (timer);
      timer = setTimeout(callback, ms);
    };
  })();

  /**
   * Initialization logic for the user interface, called in veundmint after all
   * data models and controller logic was initialized. Document is already ready.
   */
  function init() {
    renderCourseData();

    $('#USER_UNAME').on('keyup', function(event) {
      delay(function() {
        checkUsername();
      }, 200);
    });
  }


  /**
  * Login functionality
  */


  function renderCourseData() {
    var e = document.getElementById("CDATAS");
    if (e == null) {
      return;
    }
    log.debug('dataservice', dataService);
    dataService.getUserData().then(function(userData) {

      var s = "";
      var p = [];
      var t = [];
      var si = [];
      for (k = 0; k < globalexpoints.length; k++) {
        p[k] = 0; t[k] = 0; si[k] = 0;
        var j = 0;
        for (j = 0; j < userData.scores.length; j++) {
          if ((userData.scores[j].section == (k+1)) && (userData.scores[j].siteuxid.slice(0,6) != "VBKMT_")) {
            p[k] += userData.scores[j].points;
            if (userData.scores[j].intest == true) { t[k] += userData.scores[j].points; }
          }
        }

        //TODO ns - this is not working: Insgesamt 0 von 15 Lerneinheiten des Moduls besucht.
        // for (j = 0; j < userData.sites.length; j++) {
        //   if (userData.sites[j].section == (k+1)) {
        //     si[k] += userData.sites[j].points;
        //   }
        // }
        s += "<strong>Kapitel " + (k+1) + ": " + globalsections[k] + "</strong><br />";

        var progressWidthGlobal = si[k] / globalsitepoints[k] * 100;
        s += $.i18n('msg-total-progress', si[k], globalsitepoints[k] ) + "<br />";//"Insgesamt " + si[k] + " von " + globalsitepoints[k] + " Lerneinheiten des Moduls besucht.";
        s += "<div class='progress'><div id='slidebar0_" + k + "' class='progress-bar progress-bar-striped active' role='progressbar' aria-valuenow='" + si[k] + "' aria-valuemax='" + globalsitepoints[k] + "' style='width: " + progressWidthGlobal + "%'><span class='sr-only'>" + progressWidthGlobal + "% Complete</span></div></div>";

        var progressWidthEx = p[k] / globalexpoints[k] * 100;
        s += $.i18n('msg-total-points', p[k], globalexpoints[k]) + "<br />";//"Insgesamt " + p[k] + " von " + globalexpoints[k] + " Punkten der Aufgaben erreicht.<br />";
        s += "<div class='progress'><div id='slidebar0_" + k + "' class='progress-bar progress-bar-striped active' role='progressbar' aria-valuenow='" + p[k] + "' aria-valuemax='" + globalexpoints[k] + "' style='width: " + progressWidthEx + "%'><span class='sr-only'>" + progressWidthEx + "% Complete</span></div></div>";

        var progressWidthTest = t[k] / globaltestpoints[k] * 100;
        s += $.i18n( 'msg-total-test', t[k], globaltestpoints[k] ) + "<br />";//"Insgesamt " + t[k] + " von " + globaltestpoints[k] + " Punkten im Abschlusstest erreicht.<br />";
        s += "<div class='progress'><div id='slidebar0_" + k + "' class='progress-bar progress-bar-striped active' role='progressbar' aria-valuenow='" + t[k] + "' aria-valuemax='" + globaltestpoints[k] + "' style='width: " + progressWidthTest + "%'><span class='sr-only'>" + progressWidthTest + "% Complete</span></div></div>";

        var ratio = t[k]/globaltestpoints[k];
        if (ratio < 0.9) {
          s += "<span style='color:#E00000'>" + $.i18n('msg-failed-test') + "</span>"; // Abschlusstest ist noch nicht bestanden.
        } else {
          s += "<span style='color:#00F000'>" + $.i18n('msg-passed-test') + "</span>"; // Abschlusstest ist BESTANDEN.
        }
        s += "<br /><br />";

      }
      e.innerHTML = s;
    });
  }

  function checkUsername () {
    dataService.usernameAvailable(event.target.value).then(function(data) {
      var $formParent = $(event.target).parents('.form-group');
      var $icon = $("#USER_UNAME_ICON");
      if (data.username_available) {
        $formParent.addClass('has-success');
        $formParent.removeClass('has-error');
        $icon.removeClass('glyphicon-remove');
        $icon.addClass('glyphicon-ok');
        $('#USER_UNAME_SUCCESS').show();
        $('#USER_UNAME_ERROR').hide();
      } else {
        $formParent.addClass('has-error');
        $formParent.removeClass('has-success');
        $icon.removeClass('glyphicon-ok');
        $icon.addClass('glyphicon-remove');
        $('#USER_UNAME_SUCCESS').hide();
        $('#USER_UNAME_ERROR').show();
      }
    });
  }


// attach properties to the exports object to define
// the exported module properties.
exports.init = init;
exports.renderCourseData = renderCourseData;
}));
