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
  * Initialization logic for the user interface, called in veundmint after all
  * data models and controller logic was initialized. Document is already ready.
  * All functions here do not return values but change the user interface.
  */
  function init() {
    renderCourseData();

    $('#USER_UNAME').on('keyup', function(event) {
      delay(function() {
        checkUsername(event);
      }, 200);
    });

    $('input[name=password2]').on('keyup', function(event) {
      checkPasswordsMatch(event);
    });


    /**
    * AUTHENTICATION FUNCTIONALITY
    */

    //register a new user
    $('#btn-register').on('click', function(event) {
      var userCredentials = $('#form-user-register').serializeObject();
      dataService.registerUser(userCredentials).then(function(userData) {
        console.log('successfully registered', userData);
        opensite('index.html');
      }, function (error) {
        console.log(error);
      });
    });

    //login a user
    $('#btn-login').on('click', function(event) {
      var userCredentials = $('#form-user-login').serializeObject();
      dataService.authenticate(userCredentials).then(function(userData) {
        console.log('successfully signed in', userData);
        opensite('index.html');
      }, function (error) {
        console.log('error loggin in', error);
      })
    });

    //change user data
    $('#btn-change-user-data').on('click', function(event) {
      var userCredentials = $('#form-user-register').serializeObject();
      dataService.registerUser(userCredentials).then(function(userData) {
        console.log('successfully changed data to', userData);
      }, function (error) {
        console.log(error);
      });
    });

    //logout
    $('#li-logout > a').on('click', function(event) {
      event.preventDefault();
      dataService.logout().then(function(data) {
        log.debug('successfully logged out');
      }, function (error) {
        log.debug('error logging out', error);
      });
      opensite('index.html');
    });

    //set the body class to logged_in if logged in else set it to logged_out
    dataService.isAuthenticated().then(function (isAuthenticated) {
      if (isAuthenticated) {
        $('body').addClass('logged_in');
      } else {
        $('body').addClass('logged_out');
      }
    });

    //fill user form if logged in
    var $form = $('#form-user-register');
    if ($form.length) {
      dataService.getUserCredentials().then(function(data) {
        $form.populateForm(data.user);
      }, function(error) {
        log.debug('error populating form with user data');
      });
    }

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

  /**
  * Check dataService if username exists
  * @param  {Event} event The keyup event
  */
  function checkUsername (event) {
    dataService.usernameAvailable(event.target.value).then(function(data) {
      validateInput($(event.target), data.username_available);
      checkRegisterFormValid(event);
    });
  }

  function checkPasswordsMatch(event) {
    var $pass1 = $('input[name=password1]'),
    $pass2 = $('input[name=password2]');
    validateInput($pass2, $pass1.val() === $pass2.val());
    checkRegisterFormValid(event);
  }

  /**
  * Validate a userinput and give feedback by changing input color and icon
  * @param  {Object} event      The jquery event (mostly input keyup or similar)
  * @param  {[type]} element    [description]
  * @param  {[type]} comparator [description]
  * @return {[type]}            [description]
  */
  function validateInput(element, comparator) {
    var $inputParent = element.parents('.form-group');
    var $inputIcon = $inputParent.find('.glyphicon');
    if (comparator) {
      $inputParent.addClass('has-success');
      $inputParent.removeClass('has-error');
      $inputIcon.removeClass('glyphicon-remove');
      $inputIcon.addClass('glyphicon-ok');
    } else {
      $inputParent.addClass('has-error');
      $inputParent.removeClass('has-success');
      $inputIcon.removeClass('glyphicon-ok');
      $inputIcon.addClass('glyphicon-remove');
    }
  }
  /**
  * Check if register form is valid, that is if username is available,
  * password1 = password2 and password1 is secure
  * @param  {[type]} event [description]
  * @return {[type]}       [description]
  */
  function checkRegisterFormValid(event) {
    var $usernameInput = $('#USER_UNAME').parents('.form-group');
    var $pass2Input = $('input[name=password2]').parents('.form-group');
    var $registerButton = $('#btn-register');
    var formValid = $usernameInput.hasClass('has-success') && $pass2Input.hasClass('has-success') ;
    if (formValid) {
      $registerButton.removeClass('disabled');
    } else {
      $registerButton.addClass('disabled');
    }
  }


  /**
  * FUNCTIONS EXTENDING JQUERY FUNCTIONALITY
  */

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
  * A function for serializing forms to json in jquery
  */
  $.fn.serializeObject = function()
  {
    var o = {};
    var a = this.serializeArray();
    $.each(a, function() {
      if (o[this.name] !== undefined) {
        if (!o[this.name].push) {
          o[this.name] = [o[this.name]];
        }
        o[this.name].push(this.value || '');
      } else {
        o[this.name] = this.value || '';
      }
    });
    return o;
  };


  /**
  * Populate a form with json data - names in form and json keys must match
  * @param  {Object} data The json data to fill into the form
  */
  $.fn.populateForm = function (data) {
    $.each(data, function(key, value){
      var $ctrl = $('[name='+key+']', this);
      switch($ctrl.attr("type"))
      {
        case "text" :
        case "hidden":
        $ctrl.val(value);
        break;
        case "radio" : case "checkbox":
        $ctrl.each(function(){
          if($(this).attr('value') == value) {  $(this).attr("checked",value); } });
          break;
          default:
          $ctrl.val(value);
        }
      });
    }


    // attach properties to the exports object to define
    // the exported module properties.
    exports.init = init;
    exports.renderCourseData = renderCourseData;
  }));
