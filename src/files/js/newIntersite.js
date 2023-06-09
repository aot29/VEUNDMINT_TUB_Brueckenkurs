

//https://github.com/umdjs/umd/blob/master/templates/commonjsStrictGlobal.js

COLOR_INPUTBACKGROUND = "#70E0E0";
COLOR_INPUTCHANGED = "#E0C0C0";

(function (root, factory) {
    if (typeof define === 'function' && define.amd) {
        // AMD. Register as an anonymous module.
        define(['exports'], function (exports) {
            factory((root.intersite = exports));
        });
    } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
        // CommonJS
        factory(exports);
    } else {
        // Browser globals
        factory(root.intersite = {});
    }
}(this, function (exports) {
  log.info('newIntersite.js loaded');

  //what was formerly the obj is now obj
  var obj = {};

  var newIntersiteObj = {};

  //attributes
  var name = "";

  var active = false;

  var localStoragePresent = typeof(localStorage) !== "undefined";

  /**
   * The sent feedback get's documented here (the callbacks write into there)
   * This provides an overview of successfull and failed feedbacks.
   * @type {Array} follows
   * {
    *      success: true/false,
    *      status: string,
    *      feedback: string,
    *      timestamp: timestamp
    * }
   */
  var feedbackLog = [];

  /**
   * initialize intersite, will load the scores from localStorage
   * @return {[type]} [description]
   */
  function init () {

  }

  function getObj () {
    return obj;
  }

  function setObj (newObj) {
    obj = newObj;
    log.debug('intersite: obj updated to', newObj);
  }

  function getName () {
    return name;
  }

  function isActive () {
    return active;
  }

  /**
   * Sets up the intersite object
   * @param  {[type]} clearuser [description]
   * @param  {[type]} pulledstr [description]
   * @return {[type]}           [description]
   */
  function setup (clearuser, pulledstr) {
    log.debug('setup intersite', pulledstr);
    log.info( "SetupIntersite START");
    if (forceOffline == 1) {
        logMessage(CLIENTINFO, "Course is in OFFLINE mode");
    }
    var s_login = "";

    if (pulledstr != "") {
      obj = JSON.parse(pulledstr);
      log.debug("iso von pull geparsed, logintype = " + obj.login.type + ", username = " + obj.login.username);
      log.debug("Got an intersite object from " + obj.startertitle);
      active = true;
    } else {

    var scormcontinuation = false;

    //TODO: change but scorm should behave with scores like not scorm form now
    if (scormBridge.isScormEnv()) {
      // SCORM-pull: Skip LocalStorage and fetch data directly from the database server if possible, otherwise use new user with SCROM-ID and CID as login
      log.debug( "SCORM-pull forciert (SITE_PULL = " + SITE_PULL + "), SCORM-Version: " + expectedScormVersion);

      psres = scormBridge.getStudentId();
      if (psres == "null") {
        // no SCORM present, refuse to set up user
        alert( $.i18n( 'msg-failed-connection' ) ); // "Kommunikation der Lernplattform fehlgeschlagen, Kurs kann nur anonym bearbeitet werden!"
        obj = createobj();
        obj.active = true;
        obj.startertitle = document.title;
        obj.configuration.CF_LOCAL = "0";
        obj.configuration.CF_USAGE = "0";
        obj.configuration.CF_TESTS = "0";
        active = true;
        logMessage(CLIENTERROR,"Intersite setup WITHOUT STORAGE AND WITHOUT SCORM from scratch from " + obj.startertitle);
      } else {
        var s_id = psres;
        log.debug( "SCORM learner id = " + psres);

        psres = scormBridge.getStudentName();
        var s_name = psres;
        log.debug( "SCORM learner name = " + psres);
        psres = scormBridge.save();
        logMessage(DEBUGINFO, "SCORM save = " + psres);


        s_login = signature_CID + "_SCORM_" + s_id;
        logMessage(DEBUGINFO, "Assigned login name = " + s_login);

        obj = createIntersiteObjFromSCORM(s_login, s_name, "scpw" + s_id);
        obj.active = true;
        active = true;
        log.debug("Intersite setup from SCORM: " + s_login);

        var timestamp = +new Date();
        var cm = "SCORMLOGIN_PULL: " + "CID:" + signature_CID + ", user:" + obj.login.username + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
        // sendeFeedback( { statistics: cm },true );

        log.debug("Emitting pull request for this user!");
        //we need check_user_scorm_succes as it finally calls in scormdbread_success globalloadHandler(data.data);
        //which updates scores or loads scores
        //TODO this is a long intransparent dependency chain which should be altered
        userdata.checkUser(true, obj.login.username, check_user_scorm_success, check_user_scorm_error); // function emits in callbacks!
        log.debug("Pull request send");
      }
    } else {
      log.debug('no scorm use localstorage if available');
      // No SCORM: Use LocalStorage if available
      if (localStoragePresent == false) {
        obj = createobj();
        obj.active = true;
        obj.startertitle = document.title;
        obj.configuration.CF_LOCAL = "0";
        obj.configuration.CF_USAGE = "0";
        obj.configuration.CF_TESTS = "0";
        active = true;
        logMessage(CLIENTERROR,"Intersite setup WITHOUT STORAGE from scratch from " + obj.startertitle);
      } else {
        log.debug('localstorage is available');
        var iso = localStorage.getItem(getObjName());
        log.debug("iso aus localStorage geholt");
        if (clearuser == true) {
        if (active == true) {
          if (obj.configuration.CF_USAGE == "1") {
            var timestamp = +new Date();
            var cm = "USERRESET: " + "CID:" + signature_CID + ", user:" + obj.login.username + ", timestamp:" + timestamp;
            sendeFeedback( { statistics: cm }, true );
          }
        }
        iso = null;
        log.debug( "Userreset verlangt");
        }

        if (iso == "" || iso === "{}") {
      iso = null; // Falls localStorage von der JavaScript-Konsole aus resettet wurde
      log.debug( "iso = \"\" auf null gesetzt");
        }

        if (iso == null) {
      obj = createobj();
      obj.active = true;
      obj.startertitle = document.title;
      obj.configuration.CF_LOCAL = "1";
      obj.configuration.CF_USAGE = "1";
      obj.configuration.CF_TESTS = "1";
          active = true;
      log.debug( "Intersite setup with local storage from scratch from " + obj.startertitle);
      if ((obj.configuration.CF_USAGE == "1") && (clearuser == false)) {
          var timestamp = +new Date();
          var cm = "INTERSITEFIRST: " + "CID:" + signature_CID + ", user:" + obj.login.username + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
          sendeFeedback( { statistics: cm }, true );
      }
        } else {
      obj = JSON.parse(iso);
      log.debug("iso geparsed, logintype = " + obj.login.type + ", username = " + obj.login.username);
      log.debug("Got an intersite object from " + obj.startertitle);
      active = true;
        }
      }
    }
    } // pulledstr-test

    if (active == true) {
      // If user is online, ask for password, login and fetch data from server
      if ((obj.login.type == 2) || (obj.login.type == 3)) log.debug("Type=2,3, serverget missing");
    } else {
      alert( $.i18n( 'msg-failed-userdata' ) ); // "Ihre Benutzerdaten konnten nicht vom Server geladen werden, eine automatische eMail an den Administrator wurde verschickt. Sie können den Kurs trotzdem anonym bearbeiten, eingetragene Lösungen werden jedoch nicht gespeichert!"
      var timestamp = +new Date();
      var us = "(unknown)";
      if (scormBridge.isScormEnv()) {
          us = s_login;
      }
      var cm = "LOGINERROR: " + "CID:" + signature_CID + ", user:" + us + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
      sendeFeedback( { statistics: cm }, true );
      obj = createobj();
      obj.active = true;
      obj.startertitle = document.title;
      obj.configuration.CF_LOCAL = "1";
      obj.configuration.CF_USAGE = "1";
      obj.configuration.CF_TESTS = "1";
      active = true;
    }

    // Mark site as visited
    if ((active == true) && (SITE_UXID != "(unknown)")) {
      if (obj.configuration.CF_USAGE == "1") {
        var f = false;
        var j = 0;
        var sid = "SITE_" + SITE_UXID;
        if (typeof(obj.sites) == "undefined") { obj.sites = []; }
        for (j = 0; j<obj.sites.length; j++) {
          if (obj.sites[j].uxid == sid) {
            f = true;
            obj.sites[j].maxpoints = 1;
            obj.sites[j].points = 1;
            obj.sites[j].id = SITE_ID;
            obj.sites[j].intest = isTest;
            obj.sites[j].section = SECTION_ID;
            log.debug("Points for site " + sid + " modernized");
            }
          }
          if (f == false) {
            var k = obj.sites.length;
            obj.sites[k] = { uxid: sid };
            obj.sites[k].millis = 0;
            obj.sites[k].maxpoints = 1;
            obj.sites[k].points = 1;
            obj.sites[k].id = SITE_ID;
            obj.sites[k].intest = isTest;
            obj.sites[k].section = SECTION_ID;
            log.debug("Points for site " + sid + " ADDED at position " + k);
          }
       }
    }

    UpdateSpecials();
    log.info( "UpdateSpecials done");
    confHandlerISOLoad()
    if (active) {
        updateCommits(obj);
    }
    updateLoginfield();
    // updateLayoutState will be called from applyLayout()

    // Has to be called after UpdateSpecials, because that creates hrefs
    setupInterlinks()

    if (requestLogout == 1) {
        // we are on the logout page, we can do synced calls here
        log.debug( "Logout requested");
        pushISO(true);
        window.location.href="index.html";

    } else {
        log.debug( "No logout requested");
    }


    if (clearuser == true) {
        pushISO(false);
        ulreply_set(false,"");
    }
  }

  /**
   * creates a new object
   * @return {[type]} [description]
   */
  function createobj() {
    log.debug( "New obj created");
    var obj = {
      active: false,
      layout: { fontadd: 0, menuactive: true },
      configuration: { stylecolor: STYLEBLUE },
      scores: [],
      sites: [],
      favorites: [ veHelpers.createHelpFavorite() ],
      history: { globalmillis: 0, commits: [] }, // commits = array aus Arrays [ hexsha+cid, firstlogintimestamp, lastlogintimestamp ]
      login: { type: 0, vname: "", sname: "", username: "", password: "", email: "", variant: "std", sgang: "", uni: "" },
      signature: { main: signature_main, version: signature_version, localization: "DE-MINT" }
    };

    return obj;
  }

  /**
   * Writes all available data into the storage
   * @param  {[type]} synced if true => only do synchronous ajax calls (necessary when calling unload-Handler for example because the callback page would be gone when the request get's replied to)
   * @return {[type]}        [description]
   */
  function pushISO(synced) {
    log.debug("pushISO start (synced = " + synced + ")");
    var psres = "";
    var jso = JSON.stringify(obj);

    scormBridge.updateCourseScore(obj.scores);
	scormBridge.setLessonLocation(window.location.href);
	

    if (localStoragePresent == true) {
      localStorage.setItem(getObjName(), jso);
      if ((obj.login.type == 2) || (obj.login.type == 3)) {
          // Eintrag in Serverdatenbank aktualisieren
          log.debug("Aktualisiere DB-Server (synced = " + synced + ")");
          if (synced) {
            userdata.login(false, obj.login.username, obj.login.password, pushlogin_s_success, pushlogin_error); // sync-version of the success callbacks
          } else {
            userdata.login(true, obj.login.username, obj.login.password, pushlogin_success, pushlogin_error);
          }
      }
    }
    updateLoginfield();
    log.debug("pushISO finish");
  }

    /////////////////////////////////////////////////
    //////           private functions         //////
    /////////////////////////////////////////////////

    function setIntersiteType(t) {
      if (active == true) {
          if (t == obj.login.type) {
              logMessage(DEBUGINFO, "setIntersiteType with already existing type " + t + " called, doing nothing");
              return;
          }
          log.debug( "Set type=" + t);
          obj.login.type = t;
          if (t == 0) {
              // user becomes anonymous
              obj.login.vname = "";
              obj.login.sname = "";
              obj.login.username = "";
              obj.login.password = "";
              obj.login.email = "";
          }
      } else {
          logMessage(DEBUGINFO, "active == false");
      }
    }

    /**
     * Updates the history.commits array with present data
     * @param  {[type]} obj [description]
     * @return {[type]}     [description]
     */
    function updateCommits(obj) {
        var timestamp = Date.now();
        var s = "CHEX:" + signature_git_commit + "_CID:" + signature_CID;

        var j;
        var found = false;
        for (j = 0; ((j < obj.history.commits.length) && (!found)); j++) {
            if (obj.history.commits[j][0] == s) {
                found = true;
                obj.history.commits[j][2] = timestamp;
            }
        }
        if (!found) {
            n = obj.history.commits.length;
            obj.history.commits[n] = [ s, timestamp, timestamp ];
        }

        logMessage(DEBUGINFO, "Commit history:");
        for (j = 0; j < obj.history.commits.length; j++) {
            logMessage(DEBUGINFO, "  " + obj.history.commits[j][0] + ", " + veHelpers.convertTimestamp(obj.history.commits[j][1]) + ", " + veHelpers.convertTimestamp(obj.history.commits[j][2]));
        }
    }

    //TODO: move this to own service class feedback
    /**
     * Sends a feedback string to the feedback server to save it in the databse
     * The URL is taken from the global variable 'feedback_service'
     *
     * @param  {[type]} content
     *  {
     *      feedback: "feedback entered manually by the user",
     *      statistics: "autoamtic feedback for statistics"
     *  }
     * @param  {[type]} async   [description]
     * @return {[type]}         [description]
     */
    function sendeFeedback( content,async ) {
            //send feedback only if a feedbackserver has been specified
            if( feedback_service != "" ) {
                    veHelpers.sendCorsRequest( feedback_service, content,
                                    //success callback
                                    function( value ) {
                                            log.debug("SendeFeedback success callback: " + JSON.stringify(value));
                                            feedbackLog.push( { success: true, status: value, feedback: content, timestamp: (new Date).getTime() } );
                                    },
                                    //error callback
                                    function( httpRequest, textStatus, errorThrown ) {
                                            log.debug("SendeFeedback error callback: " + textStatus + ", thrown: " + JSON.stringify(errorThrown));
                                            feedbackLog.push( { success: false, status: textStatus, feedback: content, timestamp: (new Date).getTime() });
                                    }
                    ,async);
            }
    }

    /**
     * Updates all special pages (config.html, login.html, ...) depending on really many things in intersite class
     * TODO should be moved to own logic of jQuery elements that know how to change themselves instead of beeing changed
     * from somewhere
     */
    function UpdateSpecials() {
      // update div 'FAVORITELISTLONG' if present
      var e = document.getElementById("FAVORITELISTLONG");
      if (e != null) {
        // textarea exists only on the settings page, is created and prepared by the page before load happens
        if ((active==true) && (obj.configuration.CF_LOCAL == "0")) {
            e.innerHTML = $.i18n( 'msg-persistence-deactivated' );//"Datenspeicherung wurde durch Benutzer deaktiviert, es werden keine Kursdaten gespeichert.";
        } else {
          e.innerHTML = ((active==true) && (localStoragePresent==true)) ? veHelpers.generateLongFavoriteList(obj) : $.i18n( 'msg-failed-localpersistence' );//"Der Browser kann keine lokalen Daten speichern, Eingaben in Aufgabenfeldern werden nicht gespeichert.";
        }
      }

      // update element 'CHECKIS' if present
      var e = document.getElementById("CHECKIS");
      if (e != null) {
        // textarea exists only on the settings page, is created and prepared by the page before load happens
        if ((active==true) && (obj.configuration.CF_LOCAL == "0")) {
            e.innerHTML = $.i18n( 'msg-persistence-deactivated' );//"Datenspeicherung wurde durch Benutzer deaktiviert, es werden keine Kursdaten gespeichert.";
        } else {
          var mys = JSON.stringify(obj);
          if ( (active==true) && (localStoragePresent==true) ) {
              e.innerHTML = $.i18n( 'msg-successful-localpersistence',mys.length)

          } else {
              e.innerHTML = $.i18n( 'msg-failed-localpersistence' )
          } //"Der Browser kann die Kursdaten speichern,\nes werden momentan " + mys.length + " Bytes durch Kursdaten belegt.") : "Der Browser kann keine lokalen Daten speichern, Eingaben in Aufgabenfeldern werden nicht gespeichert."
        }
      }

      // update output field for 'obj' if it exists
      var e = document.getElementById("OBJOUT");
      if (e != null) {
        // textarea exists only on the settings page, is created and prepared by the page before load happens
        e.value = JSON.stringify(obj);
      }

      // update output field for 'obj' if it exists
      var e = document.getElementById("OBJARRAYS");
      if (e != null) {
        // textarea exists only on the settings page, is created and prepared by the page before load happens
        if (active == true) {
            e.value = "SITES:\n";
            var i = 0;
            for (i = 0; i < obj.sites.length; i++) {
                e.value += obj.sites[i].uxid + "\n";
            }
            e.value += "\nSCORES:\n";
            var i = 0;
            for (i = 0; i < obj.scores.length; i++) {
                e.value += obj.scores[i].siteuxid + "->" + obj.scores[i].uxid + ": " + obj.scores[i].points + "/" + obj.scores[i].maxpoints + "\n";
            }
        }
      }

      // update output field for course statistics if it exists
      var e = document.getElementById("CDATAS");
      if (e != null) {
        // textarea exists only on the settings page, is created and prepared by the page before load happens
        if ((active==true) && (obj.configuration.CF_LOCAL == "0")) {
            e.innerHTML = "Datenspeicherung wurde durch Benutzer deaktiviert, es werden keine Kursdaten gespeichert.";
        } else {
          if ((active==true) && (localStoragePresent==true)) {
            // scores.updateScoreBars()
            var s = "";
            var p = [];
            var t = [];
            var si = [];
            for (k = 0; k < globalexpoints.length; k++) {
              p[k] = 0; t[k] = 0; si[k] = 0;
              var j = 0;
              for (j = 0; j < obj.scores.length; j++) {
                if ((obj.scores[j].section == (k+1)) && (obj.scores[j].siteuxid.slice(0,6) != "VBKMT_")) {
                    p[k] += obj.scores[j].points;
                    if (obj.scores[j].intest == true) { t[k] += obj.scores[j].points; }
                }
              }

              for (j = 0; j < obj.sites.length; j++) {
                if (obj.sites[j].section == (k+1)) {
                    si[k] += obj.sites[j].points;
                }
              }
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
          } else {
            e.innerHTML = $.i18n('msg-change-localpersistence');//"Der Browser kann keine lokalen Daten speichern, Eingaben in Aufgabenfeldern werden nicht gespeichert. Modifizieren Sie ggf. die Auswahl auf der Einstellungsseite.";
          }
        }
      }
    }

    /**
     * Sets UI elements depending on values in obj
     * TODO should also be moved to UI Components own state logic
     * @return {[type]} [description]
     */
    function confHandlerISOLoad() {
      if (active == true) {
        if (obj.active == true) {
          var e;
          e = document.getElementById("CF_LOCAL");
          if (e != null) { e.checked = (obj.configuration.CF_LOCAL == "1") ? true : false; }
          e = document.getElementById("CF_USAGE");
          if (e != null) { e.checked = (obj.configuration.CF_USAGE == "1") ? true : false; }
          e = document.getElementById("CF_TESTS");
          if (e != null) { e.checked = (obj.configuration.CF_TESTS == "1") ? true : false; }
        }
      }
    }

     /**
      * Strangely updates fields concerning login logic (in old header and login.html)
      * @return {[type]} [description]
      * TODO should be moved to login component that knows its own state and renders itsself
      * accordingly
      */
     function updateLoginfield() {

       var s = "";

       var cl = "#FFFFFF";
       if (active == true) {
         switch (obj.login.type) {
           case 0: {
             s = $.i18n( 'ui-no-user' ); // "Kein Benutzer angemeldet"
             cl = "#E01010";
             $('#loginbutton').css("background-color","#FF5050");
             break;
           }
           case 1: {
             // workaround for local-only: don't display anything here
             s = $.i18n( 'ui-unknown-user', obj.login.username, obj.login.vname, obj.login.sname ); // "Benutzer " + obj.login.username + " (" + obj.login.vname + " " + obj.login.sname + "), nicht am Server angemeldet";
             s = "";
             cl = "#FFFF10";
             // $('#loginbutton').css("background-color","#FFFF50");
             $('#loginbutton').css("color","#FFFF20");
             break;
           }
           case 2: {
             s = $.i18n( 'ui-known-user', obj.login.username, obj.login.vname, obj.login.sname ); // "Benutzer " + obj.login.username + " (" + obj.login.vname + " " + obj.login.sname + ") ist am Server angemeldet";
             cl = "#FFFFFF";
             $('#loginbutton').css("background-color",$('#cdatabutton').css("background-color"));
             //$('#loginbutton').css("color","#80FFA0");
             if (scormBridge.isScormEnv()) {
                 // $('#loginbutton').prop("disabled", true);
             }
             break;
           }
           case 3: {
             s = $.i18n( 'ui-known-user', obj.login.username, obj.login.vname, obj.login.sname ); // "Benutzer " + obj.login.username + " (" + obj.login.vname + " " + obj.login.sname + ") ist am Server angemeldet";
             cl = "#FFFFFF";
             // $('#loginbutton').css("background-color",$('#cdatabutton').css("background-color"));
             $('#loginbutton').css("color","#80FFA0");
             break;
           }
           default: {
             logMessage(CLIENTERROR, "updateLoginfield, wrongtype=" + obj.login.type);
             s = $.i18n('msg-unavailable-login'); //"Keine Anmeldung möglich!";
             $('#loginbutton').css("color","#FF0000");
             break;
           }
         }
       }

       // Set headers
       // $('#LOGINROW').css("color",cl);
       // $('#LOGINROW').html(s);

       // Build login-only fields if they exist on the page
       e = document.getElementById("ONLYLOGINFIELD");
       if (e != null) {
           log.debug( "Einlogfeld gefunden");

           if (active == true) {

             e.innerHTML = s + "<br /><br />";
             e.innerHTML += "<table> <tr><td align=left>" + $.i18n('ui-username') + ":</td><td align=left><input id=\"OUSER_LOGIN\" type=\"text\" size=\"18\"></input></td></tr><tr><td align=left>" + $.i18n( 'ui-password' ) +  ":</td><td align=left><input id=\"OUSER_PW\" type=\"password\" size=\"18\"></input></td></tr></table><br /><button type =\"button\" onclick=\"intersite.userlogin_click();\">" + $.i18n('ui-login') + "</button>"; // Benutzername, Passwort, Benutzer anmelden
             e = document.getElementById("OUSER_LOGIN");
             if (e != null) {
                 e.style.backgroundColor = "#D0D0D0";
                 if ((obj.login.type == 2) || (obj.login.type == 3)) {
                     e.value = obj.login.username;
                 }
             }
             e = document.getElementById("OUSER_PW");
             if (e != null) e.style.backgroundColor = "#D0D0D0";
           } else logMessage(CLIENTERROR, "Login mangels intersite nicht moeglich");

       }


       var e = document.getElementById("LOGINFIELD");
       if (e != null) {
         var s = "";
         if (active == true) {
             if (obj.login != null) {
                 var sb = "";
                 if ((active == true) && (obj.configuration.CF_LOCAL == "1")) {
                     sb = $.i18n( 'msg-local-persistence' );// "Datenspeicherung nur in diesem Browser und diesem Rechner.";
                 } else {
                     sb = $.i18n( 'msg-no-persistence' ); // "Es werden keine Kursdaten gespeichert.";
                 }
                 var t = obj.login.type;
                 var cr = document.getElementById("CREATEBUTTON");
                 var unf = document.getElementById("USERNAMEFIELD");
                 var prefixs;
                 if (!scormBridge.isScormEnv()) {
                   prefixs = $.i18n( 'msg-long-username', obj.login.username, obj.login.vname, obj.login.sname ); //"Benutzername: " + obj.login.username;
                   if ((obj.login.vname != "") || (obj.login.sname != "")) {
                       prefixs += " (" + obj.login.vname + " " + obj.login.sname + ")";
                   }
                 } else {
                   // Username is id combination in the SCORM login modules
                   prefixs = $.i18n( 'msg-scorm-username', obj.login.vname, obj.login.sname); // "Benutzer: " + obj.login.vname + " " + obj.login.sname;
                 }
                 switch (t) {
                     case 0: {
                         s = $.i18n( 'msg-missing-userdata' ) + ",<br />" + sb; // "Noch keine Benutzerdaten vorhanden, Kurs wird anonym bearbeitet
                         if (cr != null) cr.disabled = false;
                         if (unf != null) unf.style.display = "inline";
                         break;
                     }

                     case 1: {
                         s = prefixs + ",<br />" + sb;
                         if (cr != null) cr.disabled = true;
                         if (unf != null) unf.style.display = "none";
                         break;
                     }

                     case 2: {
                         s = prefixs + ",<br />" + $.i18n( 'msg-persistence-both' ); //"Datenspeicherung in diesem Browser und auf Server "
                         if (cr != null) cr.disabled = true;
                         if (unf != null) unf.style.display = "none";
                         break;
                     }

                     case 3: {
                         // Doesn't display that it isn't up to date
                         s = prefixs + ",<br />" + $.i18n( 'msg-persistence-both' );//"Datenspeicherung in diesem Browser und auf Server ";
                         if (cr != null) cr.disabled = true;
                         if (unf != null) unf.style.display = "none";
                         break;
                     }

                     default: {
                         s = $.i18n( 'msg-failed-login' );//"Anmeldevorgang gescheitert!";
                         e.style.color = "#FF1111";
                         break;
                     }

                 }

                 if ((t == 2) || (t == 3)) { s += feedbackdesc; }

                 if (t != 0) {
                         var z = document.getElementById("USER_UNAME");
                         if (z != null) { z.value = obj.login.username; z.style.backgroundColor = COLOR_INPUTBACKGROUND; }
                         z = document.getElementById("USER_PW");
                         if (z != null) { z.value = obj.login.password; z.style.backgroundColor = COLOR_INPUTBACKGROUND; }
                         z = document.getElementById("USER_VNAME");
                         if (z != null) { z.value = obj.login.vname; z.style.backgroundColor = COLOR_INPUTBACKGROUND; }
                         z = document.getElementById("USER_SNAME");
                         if (z != null) { z.value = obj.login.sname; z.style.backgroundColor = COLOR_INPUTBACKGROUND; }
                         z = document.getElementById("USER_EMAIL");
                         if (z != null) { z.value = obj.login.email; z.style.backgroundColor = COLOR_INPUTBACKGROUND; }
                         z = document.getElementById("USER_SGANG");
                         if (z != null) { z.value = obj.login.sgang; z.style.backgroundColor = COLOR_INPUTBACKGROUND; }
                         z = document.getElementById("USER_UNI");
                         if (z != null) { z.value = obj.login.uni; z.style.backgroundColor = COLOR_INPUTBACKGROUND; }
                 } else {
                         var z = document.getElementById("USER_UNAME");
                         if (z != null) { z.value = ""; z.style.backgroundColor = COLOR_INPUTBACKGROUND; }
                         z = document.getElementById("USER_PW");
                         if (z != null) { z.value = ""; z.style.backgroundColor = COLOR_INPUTBACKGROUND; }
                         z = document.getElementById("USER_VNAME");
                         if (z != null) { z.value = ""; z.style.backgroundColor = COLOR_INPUTBACKGROUND; }
                         z = document.getElementById("USER_SNAME");
                         if (z != null) { z.value = ""; z.style.backgroundColor = COLOR_INPUTBACKGROUND; }
                         z = document.getElementById("USER_EMAIL");
                         if (z != null) { z.value = ""; z.style.backgroundColor = COLOR_INPUTBACKGROUND; }
                         z = document.getElementById("USER_SGANG");
                         if (z != null) { z.value = ""; z.style.backgroundColor = COLOR_INPUTBACKGROUND; }
                         z = document.getElementById("USER_UNI");
                         if (z != null) { z.value = ""; z.style.backgroundColor = COLOR_INPUTBACKGROUND; }
                 }
             } else s = $.i18n( 'msg-missing-logindata' );//"Keine Anmeldedaten gefunden!";
         } else s = $.i18n( 'msg-missing-browserdata' );//"Keine Anmeldedaten im Browser gespeichert!";
         $('#updatepdatabutton').css("visibility", "hidden");
         $('#updatepdatabutton').prop('disabled', true);
         e.style.color = "#000000";
         e.innerHTML = s;

         log.debug( "Userfield gesetzt");
       }
     }

     /**
      * does some ui manipulation
      * TODO also candidate for UI logic in component
      * @return {[type]} [description]
      */
     function setupInterlinks() {
       var links = document.getElementsByClassName("MINTERLINK");
       for (i=0; i<links.length; i++) {
           links[i].onclick = function() { opensite(this.href); return false;}
       }
     }

     /**
      * TODO move this function to UI Component
      * checks if the user already exists in the database (true) or not (false)
      * @return {[type]} [description]
      */
     function usercheck() {
         var e = document.getElementById("USER_UNAME");
         if (e == null) {
             logMessage(DEBUGINFO, "USER_UNAME-Feld nicht gefunden");
             return;
         }

         var una = e.value;
         var rt = veHelpers.allowedUsername(una);
         logMessage(DEBUGINFO, una +" "+ rt);
         if (rt != "") {
             ulreply_set(false,rt);
             $('#newUserButton').addClass('disabled');
             return;
         }
         ulreply_set(true,una); // set the input field display to checked
         userdata.checkUser(true, una, check_user_success, check_user_error);
     }

     /**
      * TODO move to ui component
      * does sooooome ui manipulation
      *
      * see mintscripts_bootstrap.displayFeedback
      *
      * @param {[type]} ok [description]
      * @param {[type]} m  [description]
      */
     function ulreply_set(ok, m) {
       var e;
       if (ok == false) {
         var s = "../../images/false.png";
         e = document.getElementById("USER_UNAME");
         if (e == null) return; else {
             if (e.value == "") {
                 e.style.backgroundColor = QCOLOR_NEUTRAL;
                 s = imagesPath + "/questionmark.png";
             } else {
                 e.style.backgroundColor = QCOLOR_FALSE;
             }
         }
         e = document.getElementById("checkuserimg");
         if (e == null) return; else e.src = s;
       } else {
         e = document.getElementById("USER_UNAME");
         if (e == null) return; else e.style.backgroundColor = QCOLOR_TRUE;
         e = document.getElementById("checkuserimg");
         if (e == null) return; else e.src = imagesPath + "/right.png";
       }
       e = document.getElementById("ulreply_p");
       if (e == null) return; else e.innerHTML = m;
     }

     /**
      * TODO move to ui component
      * @param  {[type]} data [description]
      * @return {[type]}      [description]
      */
     function check_user_success(data) {
         var e = document.getElementById("USER_UNAME");
         if (e == null) {
             log.debug( "USER_UNAME-Feld nicht gefunden");
             return;
         }

         if ((data.action == "check_user") && (data.status == true)) {

           if (data.user_exists == true) {
             ulreply_set(false, $.i18n( 'msg-unavailable-username' ) );//"Benutzername ist schon vergeben."
             $('#newUserButton').addClass('disabled');

           } else {
             ulreply_set(true, $.i18n('msg-available-username'));//"Dieser Benutzername ist verfügbar."
             $('#newUserButton').removeClass('disabled');
           }

         } else {
             log.debug( "checkuser success, status=false, data = " + JSON.stringify(data));
             ulreply_set(false, "Kommunikation mit Server (" + feedbackdesc + ") nicht möglich.");
             $('#newUserButton').addClass('disabled');
         }

     }

     /**
      * TODO move to ui component
      * @param  {[type]} message [description]
      * @param  {[type]} data    [description]
      * @return {[type]}         [description]
      */
     function check_user_error(message, data) {
       log.debug( "checkuser error:" + message + ", data = " + JSON.stringify(data));
       ulreply_set(false, $.i18n( 'msg-failed-server', feedbackdesc ) );//"Kommunikation mit Server (" + feedbackdesc + ") nicht möglich."
     }

     /**
      * TODO move to userdata or merge somehow into userdata and ui to ui component
      * Creates local user and does ui things
      * @param  {[type]} type type = 1 -> Create locally only, type = 2 -> create locally and immediately upgrade to server user
      * @return {[type]}      [description]
      */
     function usercreatelocal_click(type) {
         if (type==2) {
             // alert("In der Korrekturversion ist das Anlegen eines Netz-Benutzers nicht möglich um eine Verzerrung der Aufgaben- und Nutzerdatenauswertung zu vermeiden, bitte registrieren Sie sich nur innerhalb Ihres Browsers mit dem Button unten.");
             // return;
         }

         if (active == false) {
             alert( $.i18n( 'msg-failed-createuser' ) );//"Keine Datenspeicherung möglich, kann Benutzer nicht anlegen!"
             return;
         }

         if (obj.configuration.CV_LOCAL == "0") {
             alert( 'msg-activate-localpersistence' );//"Keine Datenspeicherung möglich, lokale Datenspeicherung muss zuerst in den Einstellungen aktiviert werden.");
             return;
         }


         var un = document.getElementById("USER_UNAME");
         var vn = document.getElementById("USER_VNAME");
         var sn = document.getElementById("USER_SNAME");
         var em = document.getElementById("USER_EMAIL");
         var sgang = document.getElementById("USER_SGANG");
         var uni = document.getElementById("USER_UNI");
         var una = un.value;

         var rt = veHelpers.allowedUsername(una);
         if (rt != "") {
             alert(rt);
             return;
         }

         var pws = "";
         if (scormBridge.isScormEnv()) {
             logMessage(CLIENTINFO, "Tried to set username in SCORM mode");
             return;
         } else {
           // normal version: password requested from user
           pws = prompt( $.i18n('msg-prompt', una) ); //"Geben Sie ein Passwort für den Benutzer " + una + " ein:"
           if (pws == null) return; // user has pressed abort
           rt = veHelpers.allowedPassword(pws);
           if (rt != "") {
               alert(rt);
               return;
           }

           var pws2 = prompt( $.i18n('msg-repeat-prompt') );//"Geben Sie das Passwort zur Sicherheit nochmal ein:"
           if (pws2 == null) return; // user has pressed abort
           if (pws2 != pws) {
               alert( $.i18n('msg-inconsistent-password') ); //"Die Passwörter stimmen nicht überein."
               return;
           }
         }


         logMessage(CLIENTINFO, "User set to local for username " + una);
         logMessage(CLIENTINFO, "User was previously on type=" + obj.login.type);
         setIntersiteType(1);
         obj.login.username = una;
         obj.login.password = pws;
         obj.login.vname = vn.value;
         obj.login.sname = sn.value;
         obj.login.email = em.value;
         obj.login.sgang = sgang.value;
         obj.login.uni = uni.value;

         updateLoginfield();
         applyLayout(false);

         log.debug( "Neuen Benutzer " + obj.login.username + " angelegt.");

         if (obj.configuration.CF_USAGE == "1") {
               var timestamp = +new Date();
               var cm = "USERCREATE: " + "CID:" + signature_CID + ", user:" + una + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
               sendeFeedback( { statistics: cm }, true );
         }

         if (type == 2) {
             log.debug( "User elevated to type 2");
             userdata.addUser(true, obj.login.username, obj.login.password, undefined, register_success, register_error);
         }
     }

     /**
      * TODO move ui to ui and logic to userdata
      * callback if register was successfull
      * @param  {[type]} data [description]
      * @return {[type]}      [description]
      */
     function register_success(data) {
       log.debug( "Register success, data = " + JSON.stringify(data));
       var na;
       na = (scormBridge.isScormEnv()) ? (obj.login.sname) : (obj.login.username);
       if (data.status == true) {
           setIntersiteType(3);
           pushISO(false);
           if (obj.configuration.CF_USAGE == "1") {
             var timestamp = +new Date();
             var cm = "USERREGISTER: " + "CID:" + signature_CID + ", user:" + obj.login.username + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
             sendeFeedback( { statistics: cm }, true );
           }
           // alert("Benutzer " + na + " wurde erfolgreich angelegt\n(" + feedbackdesc + ")");
       } else {
           if (obj.configuration.CF_USAGE == "1") {
             var timestamp = +new Date();
             var cm = "USERREGISTERERROR: " + "CID:" + signature_CID + ", user:" + una + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent + ", data=" + JSON.stringify(data);
             sendeFeedback( { statistics: cm }, true );
           }
           setIntersiteType(1);
           if (data.error == "user already exists") {
               alert( $.i18n( 'msg-duplicate-username', na ) );//"Benutzer " + na + " existiert schon auf dem Server, bitte geben Sie einen neuen Benutzernamen ein."
           } else {
               alert( $.i18n( 'msg-failed-createuser', na ) );//"Benutzer " + na + " konnte nicht angelegt werden, versuchen Sie es zu einem anderen Zeitpunkt nochmal. Der Benutzer wird nur im Browser angelegt."
           }
       }
     }

     /**
      * TODO move ui to ui and logic to userdata
      * @param  {[type]} message [description]
      * @param  {[type]} data    [description]
      * @return {[type]}         [description]
      */
     function register_error(message, data) {
       log.debug( "Register error: " + message + ", data = " + JSON.stringify(data));
       var na;
       na = (scormBridge.isScormEnv()) ? (obj.login.sname) : (obj.login.username);
       alert( $.i18n( 'msg-failed-createuser', na ));// "Benutzer " + na + " konnte nicht angelegt oder der Server nicht erreicht werden, versuchen Sie es zu einem anderen Zeitpunkt nochmal. Der Benutzer wird nur im Browser angelegt.");
       setIntersiteType(0);
     }

     // callbacks for pushlogin

     function pushlogin_s_success(data) {
         // hotfix: parallel code in pushlogin_success !!!
         log.debug( "login success, data = " + JSON.stringify(data));
         if (data.status == false) { pushlogin_error("Login gescheitert", null); return; }
         log.debug( "Login ok, role = " + data.role);


         // store data
         var datastring = JSON.stringify(obj);
         userdata.writeData(false, obj.login.username, datastring, pushwrite_success, pushwrite_error); // logout is done by the write callbacks
     }

     function pushlogin_success(data) {
         log.debug( "login success, data = " + JSON.stringify(data));
         if (data.status == false) { pushlogin_error("Login gescheitert", null); return; }
         log.debug( "Login ok, role = " + data.role);


         // store data
         var datastring = JSON.stringify(obj);
         userdata.writeData(true, obj.login.username, datastring, pushwrite_success, pushwrite_error); // logout is done by the write callbacks

         window.location.href="index.html";

     }

     //TODO move all of these to some ui component
     function pushlogin_error(message, data) {
       logMessage(CLIENTERROR, "Konnte Daten nicht auf Server ablegen: " + message + ", data = " + JSON.stringify(data));
       logMessage(CLIENTONLY, "Server nicht erreichbar, speichere Daten im Browser und aktualisiere Server sobald Verbindung wieder hergestellt ist");
       setIntersiteType(3); // we are now in mode local>server
     }

     function pushlogout_success(data) {
       log.debug("pushlogout success");
     }

     function pushlogout_error(message, data) {
       log.debug("pushlogout error: " + message + ", data = " + JSON.stringify(data));
     }

     function pushwrite_success(data) {
       log.debug("pushwrite success, data = " + JSON.stringify(data));
       setIntersiteType(2); // server is now up to date
       userdata.logout(false, pushlogout_success, pushlogout_error);
     }

     function pushwrite_error(message, data) {
       log.debug("pushwrite error: " + message + ", data = " + JSON.stringify(data) + ", versuche logout...");
       userdata.logout(false, pushlogout_success, pushlogout_error);
     }

     function userlogin_click() {
       log.debug( "userlogin geklickt");

       // handle the user that's already logged in:
       // type = 0: anonymous, discard data
       // type = 1: local, ask user beforehand
       // type = 2: server is up to data, discard local data
       // type = 3: try to save everything beforehand

       var user_login = "";
       var user_pw = "";
       var e = document.getElementById("OUSER_LOGIN");
       if (e != null) { user_login = e.value; } else return;
       e = document.getElementById("OUSER_PW");
       if (e != null) { user_pw = e.value; } else return;

       var rt = veHelpers.allowedUsername(user_login);
       if (rt != "") { alert(rt); return; }
       rt = veHelpers.allowedPassword(user_pw);
       if (rt != "") { alert(rt); return; }

       log.debug( "Starte Login " + user_login);

       // Try loggin in to the server.
       userdata.login(true, user_login, user_pw, userlogin_success, userlogin_error);
       // continue with callbacks
     }

     function userlogin_success(data) {
         log.debug( "userlogin success");
         if (data.status == false) { userlogin_error("Login gescheitert", null); return; }
         log.debug( "Login ok, username = " + data.username + ", role = " + data.role);
         // need to send username
         userdata.getData(true, data.username, loginread_success, loginread_error); // logout is done by the write callbacks
       // continue with callbacks
     }

     function userlogin_error(message, data) {
       if (typeof(data) == "object") {
           if (data.error == "invalid password") {
             alert( $.i18n('msg-repeat-login') ); // "Benutzername oder Passwort sind nicht korrekt, bitte versuchen Sie es nochmal."
             log.debug( "Login wegen fehlerhaftem Benutzernamen/Passwort nicht akzeptiert");
             return;
           }
       }
       logMessage(CLIENTERROR, "Login gescheitert: " + message + ", data = " + JSON.stringify(data));
     }

     function loginread_success(data) {
       if (data.status == false) {
           log.debug( "login read successm but status error: " + data.error);
           return;
       }

       log.debug("loginread success");
       var iso = JSON.parse(data.data);

       log.debug( "iso = " + JSON.stringify(iso));

       obj = iso;
       setIntersiteType(2); // are now synchronous

       // TODO: belongs to quickfix, should be removed
       userdata.logout(true, pushlogout_success, pushlogout_error);
       window.location.href="index.html";
     }

     function loginread_error(message, data) {
       logMessage(CLIENTERROR, "loginread error: " + message + ", data = " + JSON.stringify(data) + ", trying logout...");
       logMessage(CLIENTONLY, "Konnte Benutzerdaten nicht von Server uebertragen!");
       userdata.logout(true, pushlogout_success, pushlogout_error);
     }


     function userreset_click() {
       log.debug( "userreset_click");
       var s = " ";
       if (active == true) {
           if (obj.config != null) {
               if (obj.config.type > 0) {
                   s += "(Benutzername " + obj.config.username + ") ";
               }
           }
       }
       if (confirm( $.i18n('msg-confirm-reset', s) ) == true) SetupIntersite(true);//// "Wirklich alle Kursdaten "..."löschen? Dieser Vorgang kann nicht rückgängig gemacht werden!"
     }

     function userdelete_click() {
       log.debug( "userreset_click");
       var s = "Wirklich alle Benutzer- und Kursdaten ";
       if (active == true) {
           if (obj.config != null) {
               if (obj.config.type > 0) {
                   s += "(Benutzername " + obj.config.username + ") ";
               }
           }
       }
       s += "löschen? Dieser Vorgang kann nicht rückgängig gemacht werden!";
       if (confirm(s) == true) {
           alert("Diese Funktion steht noch nicht zur Verfügung!");
       }
     }

     function getNameDescription() {
    	    if (active == false) return "";
    	    if (obj.login.type == 0) return "Anonym";
    	    if (obj.login.sname != "") return obj.login.sname;
    	    return obj.login.vname;
    	}

      function createIntersiteObjFromSCORM(s_login, s_name, s_pw) {
        logMessage(VERBOSEINFO,"New IntersiteObj for scormlogin created");
        var obj = createobj();
        obj.login.type = 1; // starting locally

        obj.login.vname = "";

        var turn = false;
        var spl = " ";
        // there's no end as to how LMS present a simple name
        if (s_name.indexOf(", ") != -1) {
            turn = true;
            spl = ", ";
        } else {
            if (s_name.indexOf(",") != -1) {
                turn = true;
                spl = ",";
            }
        }
        var sp = s_name.split(spl);
        for (var e = 0; e < (sp.length - 1); e++) {
          if (e != 0) obj.login.vname += " ";
          obj.login.vname += sp[e];
        }
        obj.login.sname = sp[sp.length - 1];
        if (turn) {
            var z = obj.login.sname;
            obj.login.sname = obj.login.vname;
            obj.login.vname = z;
        }
        logMessage(VERBOSEINFO,"Decomposed name " + s_name + " into vname=\"" + obj.login.vname + "\", sname=\"" + obj.login.sname + "\"");

        obj.login.username = s_login;
        obj.login.password = s_pw;
        obj.login.email = "";
        obj.startertitle = document.title;
        obj.configuration.CF_LOCAL = "1";
        obj.configuration.CF_USAGE = "1";
        obj.configuration.CF_TESTS = "1";
        return obj;
      }

      // Callbacks for createIntersiteObjFormSCORM
      function check_user_scorm_success(data) {
        logMessage(VERBOSEINFO, "checkuser_scorm success: data = " + JSON.stringify(data));

        if (data.user_exists == false) {
          logMessage(VERBOSEINFO, "User does not exist, adding user to database with initial data push");
          userdata.addUser(true, obj.login.username, obj.login.password, undefined, register_success, register_error);
          // continue with register callbacks
        } else {
          logMessage(VERBOSEINFO, "User is present in database, emitting data pull request");
          userdata.login(true, obj.login.username, obj.login.password, scormlogin_success, scormlogin_error);
          // continue with login callbacks
        }
      }

      function check_user_scorm_error(message, data) {
        log.warn("checkuser_scorm error:" + message + ", data = " + JSON.stringify(data) + ", trying backup from LocalStorage...");

        // Retrieve old userdata from LocalStorage, if not present continue to use newly created obj from first pull start
        //this will happen if cross site scripting is denied from server but we want to continue
        //with the userdata (especially scores from intersite obj)
        //TODO


      }

      function scormlogin_error(message, data) {
        log.warn("Konnte user nicht am Server einloggen: " + message + ", data = " + JSON.stringify(data));
        logMessage(CLIENTONLY, "Server nicht erreichbar, speichere Daten im Browser und aktualisiere Server sobald Verbindung wieder hergestellt ist");
        setIntersiteType(1); // Work locally for now so as not to destruct more up to date data in the database

        // Retrieve old userdata from LocalStorage, if not present continue to use newly created obj from first pull start
        // ...
      }

      function scormlogin_success(data) {
          logMessage(VERBOSEINFO, "login success, data = " + JSON.stringify(data));
          if (data.status == false) { scormlogin_error("Login gescheitert", null); return; }
          logMessage(VERBOSEINFO, "Login ok, role = " + data.role);

          // get data, continue with 'scrombread' callbacks
          logMessage(VERBOSEINFO, "i-name = " + obj.login.username);
          userdata.getData(true, obj.login.username, scormdbread_success, scormdbread_error);
      }

      function scormdbread_error(message, data) {
        logMessage(CLIENTERROR, "Konnte user-Daten nicht vom Server abfragen: " + message + ", data = " + JSON.stringify(data));
        logMessage(CLIENTONLY, "Server nicht erreichbar, speichere Daten im Browser und aktualisiere Server sobald Verbindung wieder hergestellt ist");
        setIntersiteType(1); // Work locally for now so as not to destruct more up to date data in the database

        // Inform the user here?

        userdata.logout(true, scormlogout_success, scormlogout_error);


        // Retrieve old userdata from LocalStorage, if not present continue to use newly created obj from first pull start
        // ...
        globalloadHandler(JSON.stringify(intersite.getObj()));
      }

      function scormdbread_success(data) {
          logMessage(VERBOSEINFO, "data get success");
          if (data.status == false) { scormdbread_error("Data get gescheitert", null); return; }
          userdata.logout(true, scormlogout_success, scormlogout_error);
          globalloadHandler(data.data);
      }

      function scormlogout_success(data) {
          logMessage(VERBOSEINFO, "logout success, data = " + JSON.stringify(data));
      }

      function scormlogout_error(message, data) {
          logMessage(CLIENTERROR, "SCORM-Pull-Logout unmoeglich: " + message + ", data = " + JSON.stringify(data));
      }

      /**
       * Sets the scrolltop position to the intersite obj, which is persisted,
       * so that it can be recalled on site url change
       * @param {[type]} scrollTop [description]
       */
      function setScrollTop(scrollTop) {
        obj.scrollTop = scrollTop;
      }

      /**
       * gets the scrollTop value from the intersite obj which is needed, when
       * user changes language and should be redirected to same scrollTop position
       * @return {[type]} [description]
       */
      function getScrollTop() {
          return obj.scrollTop;
      }

      /**
       * determines the local storage name of the intersite object
       * @return {[type]} [description]
       */
      function getObjName() {
          s = "isobj_" + signature_main;
          logMessage(DEBUGINFO, "Loading user object with id " + s);
          return s; // Important: same object even for different versions
      }

     // attach properties to the exports object to define
     // the exported module properties.
     //
     // functions
     exports.init = init;
     exports.setup = setup;
     exports.pushIso = pushISO;
     exports.createobj = createobj;
     exports.usercheck = usercheck;
     exports.usercreatelocal_click = usercreatelocal_click;
     exports.sendeFeedback = sendeFeedback;
     exports.userlogin_click = userlogin_click;
     exports.getObj = getObj;
     exports.setObj = setObj;
     exports.getName = getName;
     exports.isActive = isActive;
     exports.getNameDescription = getNameDescription;
     exports.updateSpecials = UpdateSpecials;
     exports.setScrollTop = setScrollTop;
     exports.getScrollTop = getScrollTop;

}));
