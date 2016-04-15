/*
 * Copyright (C) 2015 KIT (www.kit.edu), Author: Daniel Haase
 *
 *  This file is part of the VE&MINT program compilation
 *  (see www.ve-und-mint.de).
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 3 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 * */

// determines the local storage name of the intersite object
function getObjName() {
    return "isobj_" + signature_main; // Important: same object even for different versions
}

// login types:
// type -1: No LocalStorage available, nothing can be stored
//        - Data in 'intersiteobj' do exist, but nothing can be added
//        - Every pageload creates an entirely new 'intersiteobj'
// type 0: anonymous, local:
//        - Strings in the 'login' subobject are empty, user is anonymous
//        - 'depending' on the flags, 'intersiteobj' get's stored in LocalStorage
// type 1: personalized, local:
//        - Strings in the 'login' subobject contain user data but the password is empty
//        - 'depending' on the flags, 'intersiteobj' get's stored in LocalStorage
// type 2: personalized, server sync: (the two types are the only valid when 'scormLogin == true')
//        - Strings in the 'login' subobject' contain user data and the user exists on the server with the given data pair (username,password).
//        - Data on the server is in sync with 'intersiteobj' so it doesn't need to be pushed.
// Typ  3: personalized, server async:
//        - Strings in the 'login' subobject' contain user data and the user exists on the server with the given data pair (username,password).
//        - Data in 'intersiteobj' can be more up to data than the data on the server and still needs to be pushed.



function createIntersiteObj() {
  logMessage(VERBOSEINFO, "New IntersiteObj created");
  var obj = {
    active: false,
    layout: { fontadd: 0, menuactive: true },
    configuration: { stylecolor: STYLEBLUE },
    scores: [],
    sites: [],
    favorites: [ createHelpFavorite() ],
    login: { type: 0, vname: "", sname: "", username: "", password: "", email: "" }
  };
  return obj;
}

function createIntersiteObjFromSCORM(s_login, s_name, s_pw) {
  logMessage(VERBOSEINFO,"New IntersiteObj for scormlogin created");
  var obj = createIntersiteObj();
  obj.login.type = 1; // starting locally

  obj.login.vname = "";
  var sp = s_name.split(" ");
  for (var e = 0; e < (sp.length - 1); e++) {
    if (e != 0) obj.login.vname += " ";
    obj.login.vname += sp[e];
  }
  obj.login.sname = sp[sp.length - 1];
  logMessage(VERBOSEINFO,"Decomposed name " + s_name + " into vname=\"" + obj.login.vname + "\", sname = \"" + obj.login.sname + "\"");

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
    userdata.addUser(true, intersiteobj.login.username, intersiteobj.login.password, undefined, register_success, register_error);
    intersiteobj.type = 3;
    // continue with register callbacks
  } else {
    logMessage(VERBOSEINFO, "User is present in database, emitting data pull request");
    userdata.login(true, intersiteobj.login.username, intersiteobj.login.password, scormlogin_success, scormlogin_error);
    // continue with login callbacks
  }
}

function check_user_scorm_error(message, data) {
  logMessage(CLIENTERROR, "checkuser_scorm error:" + message + ", data = " + JSON.stringify(data) + ", trying backup from LocalStorage...");

  // Retrieve old userdata from LocalStorage, if not present continue to use newly created intersiteobj from first pull start
  // ...
}

function scormlogin_error(message, data) {
  logMessage(CLIENTERROR, "Konnte user nicht am Server einloggen: " + message + ", data = " + JSON.stringify(data));
  logMessage(CLIENTONLY, "Server nicht erreichbar, speichere Daten im Browser und aktualisiere Server sobald Verbindung wieder hergestellt ist");
  setIntersiteType(1); // Work locally for now so as not to destruct more up to date data in the database

  // Retrieve old userdata from LocalStorage, if not present continue to use newly created intersiteobj from first pull start
  // ...
}

function scormlogin_success(data) {
    logMessage(VERBOSEINFO, "login success, data = " + JSON.stringify(data));
    if (data.status == false) { scormlogin_error("Login gescheitert", null); return; }
    logMessage(VERBOSEINFO, "Login ok, role = " + data.role);

    // get data, continue with 'scrombread' callbacks
    logMessage(VERBOSEINFO, "i-name = " + intersiteobj.login.username);
    userdata.getData(true, intersiteobj.login.username, scormdbread_success, scormdbread_error);
}

function scormdbread_error(message, data) {
  logMessage(CLIENTERROR, "Konnte user-Daten nicht vom Server abfragen: " + message + ", data = " + JSON.stringify(data));
  logMessage(CLIENTONLY, "Server nicht erreichbar, speichere Daten im Browser und aktualisiere Server sobald Verbindung wieder hergestellt ist");
  setIntersiteType(1); // Work locally for now so as not to destruct more up to date data in the database

  // Inform the user here?

  userdata.logout(true, scormlogout_success, scormlogout_error);


  // Retrieve old userdata from LocalStorage, if not present continue to use newly created intersiteobj from first pull start
  // ...
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


// Helper function for recursive cloning of simple objects in JS
function objClone(obj) {
  // return JSON.parse(JSON.stringify(obj));
    if(obj == null || typeof(obj) != 'object')
        return obj;

    var temp = obj.constructor();
    if ((typeof temp) != "object") logMessage(DEBUGINFO, "PROBLEM with object" + JSON.stringify(obj));

    for(var key in obj) {
        if(obj.hasOwnProperty(key)) {
            temp[key] = objClone(obj[key]);
        }
    }
    return temp;
}

// Initialises the intersite object, if 'update == true', existing data get's overwritten, if 'scormLogin == true' the user id is used from SCORM instead of localStorage (this doesn't include 'clearuser')
// pulledstr = JSON-String from db for user-obj, otherwise "" if nothing needs to be pulled.
function SetupIntersite(clearuser, pulledstr) {
  logMessage(VERBOSEINFO, "SetupIntersite START");
  if (forceOffline == 1) {
      logMessage(CLIENTINFO, "Course is in OFFLINE mode");
  }
  var s_login = "";

  if (pulledstr != "") {
    intersiteobj = JSON.parse(pulledstr);
    logMessage(VERBOSEINFO,"iso von pull geparsed, logintype = " + intersiteobj.login.type + ", username = " + intersiteobj.login.username);
    logMessage(VERBOSEINFO,"Got an intersite object from " + intersiteobj.startertitle);
    intersiteactive = true;
  } else {

  var ls = ""; // local SCORM data if present
  // Only access LocalStorage if 'loginscrom == 0)
  if (typeof(localStorage) !== "undefined") {
    localStoragePresent = true;
    logMessage(VERBOSEINFO, "localStorage found");
    if (doScorm == 1) {
      ls = localStorage.getItem("LOCALSCORM");
    }
  } else {
    localStoragePresent = false;
    logMessage(CLIENTERROR,"localStorage NOT found");
    var stor = window.localStorage;
    if (typeof(stor) !== "undefined") {
      logMessage(CLIENTERROR,"window.localStorage as stor found!");
    }
  }

  if (doScorm == 1) {
    if ((ls == "") || (ls == "CLEARED")) {
      // reinitialize SCORM
      logMessage(VERBOSEINFO, "pipwerks.SCORM start");
    } else {
      // SCORM is already active, inherit state of the pipwerks object
      var sobj = JSON.parse(ls);
      if (sobj != null) {
        pipwerks.scormdata = sobj;
        logMessage(VERBOSEINFO, "pipwerks.SCORM continuation");
      } else {
        logMessage(VERBOSEINFO, "pipwerks.SCORM-Uebertragungsobjekt beschaedigt");
      }
    }
  }

  if ((scormLogin == 1) && (SITE_PULL == 1)) {
    // SCORM-pull: Skip LocalStorage an fetch data directly from the database server if possible, otherwise use new user with SCROM-ID and CID as login
    logMessage(VERBOSEINFO, "SCORM-pull forciert (SITE_PULL = " + SITE_PULL + ")");

    var psres = pipwerks.SCORM.init();
    logMessage(VERBOSEINFO, "SCORM init = " + psres + " (remember duplicate SCORM inits return false but do not hurt)");
    psres = pipwerks.SCORM.get("cmi.learner_id");
    if (psres == "null") {
      // no SCORM present, refuse to set up user
      alert("Kommunikation der Lernplattform fehlgeschlagen, Kurs kann nur anonym bearbeitet werden!");
      intersiteobj = createIntersiteObj();
      intersiteobj.active = true;
      intersiteobj.startertitle = document.title;
      intersiteobj.configuration.CF_LOCAL = "0";
      intersiteobj.configuration.CF_USAGE = "0";
      intersiteobj.configuration.CF_TESTS = "0";
      intersiteactive = true;
      logMessage(CLIENTERROR,"Intersite setup WITHOUT STORAGE AND WITHOUT SCORM from scratch from " + intersiteobj.startertitle);
    } else {
      var s_id = psres;
      logMessage(VERBOSEINFO, "SCORM learner id = " + psres);
      psres = pipwerks.SCORM.get("cmi.learner_name");
      var s_name = psres;
      logMessage(VERBOSEINFO, "SCORM learner name = " + psres);
      psres = pipwerks.SCORM.save();
      logMessage(DEBUGINFO, "SCORM save = " + psres);


      s_login = signature_CID + "_SCORM_" + s_id;
      logMessage(DEBUGINFO, "Assigned login name = " + s_login);

      intersiteobj = createIntersiteObjFromSCORM(s_login, s_name, "scpw" + s_id);
      intersiteobj.active = true;
      intersiteactive = true;
      logMessage(VERBOSEINFO,"Intersite setup from SCORM: " + s_login);

      var timestamp = +new Date();
      var cm = "SCORMLOGIN_PULL: " + "CID:" + signature_CID + ", user:" + intersiteobj.login.username + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
      // sendeFeedback( { statistics: cm },true );

      logMessage(VERBOSEINFO,"Emitting pull request for this user!");
      userdata.checkUser(true, intersiteobj.login.username, check_user_scorm_success, check_user_scorm_error); // function emits in callbacks!
      logMessage(VERBOSEINFO,"Pull request send");
    }
  } else {
    // No SCORM: Use LocalStorage if available
    if (localStoragePresent == false) {
      intersiteobj = createIntersiteObj();
      intersiteobj.active = true;
      intersiteobj.startertitle = document.title;
      intersiteobj.configuration.CF_LOCAL = "0";
      intersiteobj.configuration.CF_USAGE = "0";
      intersiteobj.configuration.CF_TESTS = "0";
      intersiteactive = true;
      logMessage(CLIENTERROR,"Intersite setup WITHOUT STORAGE from scratch from " + intersiteobj.startertitle);
    } else {
      var iso = localStorage.getItem(getObjName());
      logMessage(VERBOSEINFO,"iso aus localStorage geholt");
      if (clearuser == true) {
	  if (intersiteactive == true) {
	    if (intersiteobj.configuration.CF_USAGE == "1") {
	      var timestamp = +new Date();
	      var cm = "USERRESET: " + "CID:" + signature_CID + ", user:" + intersiteobj.login.username + ", timestamp:" + timestamp;
	      sendeFeedback( { statistics: cm }, true );
	    }
	  }
	  iso = null;
	  logMessage(VERBOSEINFO, "Userreset verlangt");
      }
      
      if (iso == "") {
	iso = null; // Falls localStorage von der JavaScript-Konsole aus resettet wurde
	logMessage(VERBOSEINFO, "iso = \"\" auf null gesetzt");
      }

      if (iso == null) {
	intersiteobj = createIntersiteObj();
	intersiteobj.active = true;
	intersiteobj.startertitle = document.title;
	intersiteobj.configuration.CF_LOCAL = "1";
	intersiteobj.configuration.CF_USAGE = "1";
	intersiteobj.configuration.CF_TESTS = "1";
        intersiteactive = true;
	logMessage(VERBOSEINFO, "Intersite setup with local storage from scratch from " + intersiteobj.startertitle);
	if ((intersiteobj.configuration.CF_USAGE == "1") && (clearuser == false)) {
	    var timestamp = +new Date();
	    var cm = "INTERSITEFIRST: " + "CID:" + signature_CID + ", user:" + intersiteobj.login.username + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
	    sendeFeedback( { statistics: cm }, true );
	}
      } else {
	intersiteobj = JSON.parse(iso);
	logMessage(VERBOSEINFO,"iso geparsed, logintype = " + intersiteobj.login.type + ", username = " + intersiteobj.login.username);
	logMessage(VERBOSEINFO,"Got an intersite object from " + intersiteobj.startertitle);
	intersiteactive = true;
      }
    }
  }
  } // pulledstr-test

  if (intersiteactive == true) {
    // If user is online, ask for password, login and fetch data from server
    if ((intersiteobj.login.type == 2) || (intersiteobj.login.type == 3)) logMessage(VERBOSEINFO,"Type=2,3, serverget missing");
  } else {
    alert("Ihre Benutzerdaten konnten nicht vom Server geladen werden, eine automatische eMail an den Administrator wurde verschickt. Sie können den Kurs trotzdem anonym bearbeiten, eingetragene Lösungen werden jedoch nicht gespeichert!");
    var timestamp = +new Date();
    var us = "(unknown)";
    if (scormLogin == 1) us = s_login;
    var cm = "LOGINERROR: " + "CID:" + signature_CID + ", user:" + us + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
    sendeFeedback( { statistics: cm }, true );
    intersiteobj = createIntersiteObj();
    intersiteobj.active = true;
    intersiteobj.startertitle = document.title;
    intersiteobj.configuration.CF_LOCAL = "1";
    intersiteobj.configuration.CF_USAGE = "1";
    intersiteobj.configuration.CF_TESTS = "1";
    intersiteactive = true;
  }

  // Mark site as visited
  if ((intersiteactive == true) && (SITE_UXID != "(unknown)")) {
    if (intersiteobj.configuration.CF_USAGE == "1") {
      var f = false;
      var j = 0;
      var sid = "SITE_" + SITE_UXID;
      if (typeof(intersiteobj.sites) == "undefined") { intersiteobj.sites = []; }
      for (j = 0; j<intersiteobj.sites.length; j++) {
        if (intersiteobj.sites[j].uxid == sid) {
          f = true;
          intersiteobj.sites[j].maxpoints = 1;
          intersiteobj.sites[j].points = 1;
          intersiteobj.sites[j].id = SITE_ID;
          intersiteobj.sites[j].intest = isTest;
          intersiteobj.sites[j].section = SECTION_ID;
          logMessage(VERBOSEINFO,"Points for site " + sid + " modernized");
          }
        }
        if (f == false) {
          var k = intersiteobj.sites.length;
          intersiteobj.sites[k] = { uxid: sid };
          intersiteobj.sites[k].maxpoints = 1;
          intersiteobj.sites[k].points = 1;
          intersiteobj.sites[k].id = SITE_ID;
          intersiteobj.sites[k].intest = isTest;
          intersiteobj.sites[k].section = SECTION_ID;
          logMessage(VERBOSEINFO,"Points for site " + sid + " ADDED at position " + k);
        }
     }
  }

  UpdateSpecials();
  confHandlerISOLoad()
  updateLoginfield();

  // Has to be called after UpdateSpecials, because that creates hrefs
  if (intersitelinks != true) {
    var links = document.getElementsByClassName("MINTERLINK");
    for (i=0; i<links.length; i++) {
      links[i].onclick = function() { opensite(this.href); return false;}
    }
    intersitelinks = true;
  }


  if (clearuser == true) {
      pushISO(false);
      ulreply_set(false,"");
  }
}

function updateLoginfield() {

  var s = "";

  var cl = "#FFFFFF";
  if (intersiteactive == true) {
    switch (intersiteobj.login.type) {
      case 0: {
        s = "Kein Benutzer angemeldet";
        cl = "#E01010";
        $('#loginbutton').css("background-color","#FF5050");
        break;
      }
      case 1: {
        s = "Benutzer " + intersiteobj.login.username + " (" + intersiteobj.login.vname + " " + intersiteobj.login.sname + "), nicht am Server angemeldet";
        cl = "#FFFF10";
        $('#loginbutton').css("background-color","#FFFF50");
        break;
      }
      case 2: {
        s = "Benutzer " + intersiteobj.login.username + " (" + intersiteobj.login.vname + " " + intersiteobj.login.sname + ") ist am Server angemeldet";
        cl = "#FFFFFF";
        $('#loginbutton').css("background-color",$('#cdatabutton').css("background-color"));
        break;
      }
      case 3: {
        s = "Benutzer " + intersiteobj.login.username + " (" + intersiteobj.login.vname + " " + intersiteobj.login.sname + ") ist am Server angemeldet";
        cl = "#FFFFFF";
        $('#loginbutton').css("background-color",$('#cdatabutton').css("background-color"));
        break;
      }
      default: {
        logMessage(CLIENTERROR, "updateLoginfield, wrongtype=" + intersiteobj.login.type);
        s = "Keine Anmeldung möglich!";
        break;
      }
    }
  }

  // Set headers
  $('#LOGINROW').css("color",cl);
  $('#LOGINROW').html(s);

  // Build login-only fields if they exist on the page
  e = document.getElementById("ONLYLOGINFIELD");
  if (e != null) {
      logMessage(VERBOSEINFO, "Einlogfeld gefunden");

      if (intersiteactive == true) {

        e.innerHTML = s + "<br /><br />";
        e.innerHTML += "<table> <tr><td align=left>Benutzername:</td><td align=left><input id=\"OUSER_LOGIN\" type=\"text\" size=\"18\"></input></td></tr><tr><td align=left>Passwort:</td><td align=left><input id=\"OUSER_PW\" type=\"password\" size=\"18\"></input></td></tr></table><br /><button type =\"button\" onclick=\"userlogin_click();\">Benutzer anmelden</button>";
        e = document.getElementById("OUSER_LOGIN");
        if (e != null) {
            e.style.backgroundColor = "#D0D0D0";
            if ((intersiteobj.login.type == 2) || (intersiteobj.login.type == 3)) {
                e.value = intersiteobj.login.username;
            }
        }
        e = document.getElementById("OUSER_PW");
        if (e != null) e.style.backgroundColor = "#D0D0D0";
      } else logMessage(CLIENTERROR, "Login mangels intersite nicht moeglich");

  }


  // Create complete login field on settings page
  e = document.getElementById("RESETBUTTON");
  if (e != null) {
      var dis = true;

      if (intersiteactive == true) {
          if (intersiteobj.configuration.CF_LOCAL == "1") {
              dis = false;
          }
      }
      e.disabled = dis;
  }

  var e = document.getElementById("LOGINFIELD");
  if (e != null) {
    var s = "";
    if (intersiteactive == true) {
        if (intersiteobj.login != null) {
            var sb = "";
            if ((intersiteactive == true) && (intersiteobj.configuration.CF_LOCAL == "1")) {
                sb = "Datenspeicherung nur in diesem Browser und diesem Rechner.";
            } else {
                sb = "Es werden keine Kursdaten gespeichert.";
            }
            var t = intersiteobj.login.type;
            var cr = document.getElementById("CREATEBUTTON");
            var unf = document.getElementById("USERNAMEFIELD");
            var prefixs;
            if (scormLogin == 0) {
              prefixs = "Benutzername: " + intersiteobj.login.username + " (" + intersiteobj.login.vname + " " + intersiteobj.login.sname + ")";
            } else {
              // Username is id combination in the SCORM login modules
              prefixs = "Benutzer: " + intersiteobj.login.vname + " " + intersiteobj.login.sname;
            }
            switch (t) {
                case 0: {
                    s = "Noch keine Benutzerdaten vorhanden, Kurs wird anonym bearbeitet,<br />" + sb;
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
                    s = prefixs + ",<br />Datenspeicherung in diesem Browser und auf Server ";
                    if (cr != null) cr.disabled = true;
                    if (unf != null) unf.style.display = "none";
                    break;
                }

                case 3: {
                    // Doesn't display that it isn't up to date
                    s = prefixs + ",<br />Datenspeicherung in diesem Browser und auf Server ";
                    if (cr != null) cr.disabled = true;
                    if (unf != null) unf.style.display = "none";
                    break;
                }

                default: {
                    s = "Anmeldevorgang gescheitert!";
                    e.style.color = "#FF1111";
                    break;
                }

            }

            if ((t == 2) || (t == 3)) { s += feedbackdesc; }

            if (t != 0) {
                    var z = document.getElementById("USER_UNAME");
                    if (z != null) { z.value = intersiteobj.login.username; z.style.backgroundColor = "#70FFFF"; }
                    z = document.getElementById("USER_PW");
                    if (z != null) { z.value = intersiteobj.login.password; z.style.backgroundColor = "#70FFFF"; }
                    z = document.getElementById("USER_VNAME");
                    if (z != null) { z.value = intersiteobj.login.vname; z.style.backgroundColor = "#70FFFF"; }
                    z = document.getElementById("USER_SNAME");
                    if (z != null) { z.value = intersiteobj.login.sname; z.style.backgroundColor = "#70FFFF"; }
                    z = document.getElementById("USER_EMAIL");
                    if (z != null) { z.value = intersiteobj.login.email; z.style.backgroundColor = "#70FFFF"; }
            } else {
                    var z = document.getElementById("USER_UNAME");
                    if (z != null) { z.value = ""; z.style.backgroundColor = "#E0E3E0"; }
                    z = document.getElementById("USER_PW");
                    if (z != null) { z.value = ""; z.style.backgroundColor = "#E0E3E0"; }
                    z = document.getElementById("USER_VNAME");
                    if (z != null) { z.value = ""; z.style.backgroundColor = "#E0E3E0"; }
                    z = document.getElementById("USER_SNAME");
                    if (z != null) { z.value = ""; z.style.backgroundColor = "#E0E3E0"; }
                    z = document.getElementById("USER_EMAIL");
                    if (z != null) { z.value = ""; z.style.backgroundColor = "#E0E3E0"; }
            }


        } else s = "Keine Anmeldedaten gefunden!";
    } else s = "Keine Anmeldedaten im Browser gespeichert!";
    e.style.color = "#000000";
    e.innerHTML = s;


    logMessage(VERBOSEINFO, "Userfield gesetzt");
  }
}



function UpdateSpecials() {
  // update div 'FAVORITELISTLONG' if present
  var e = document.getElementById("FAVORITELISTLONG");
  if (e != null) {
    // textarea exists only on the settings page, is created and prepared by the page before load happens
    if ((intersiteactive==true) && (intersiteobj.configuration.CF_LOCAL == "0")) {
        e.innerHTML = "Datenspeicherung wurde durch Benutzer deaktiviert, es werden keine Kursdaten gespeichert.";
    } else {
      e.innerHTML = ((intersiteactive==true) && (localStoragePresent==true)) ? generateLongFavoriteList() : "Der Browser kann keine lokalen Daten speichern, Eingaben in Aufgabenfeldern werden nicht gespeichert.";
    }
  }

  // update element 'CHECKIS' if present
  var e = document.getElementById("CHECKIS");
  if (e != null) {
    // textarea exists only on the settings page, is created and prepared by the page before load happens
    if ((intersiteactive==true) && (intersiteobj.configuration.CF_LOCAL == "0")) {
        e.innerHTML = "Datenspeicherung wurde durch Benutzer deaktiviert, es werden keine Kursdaten gespeichert.";
    } else {
      var mys = JSON.stringify(intersiteobj);
      e.innerHTML = ((intersiteactive==true) && (localStoragePresent==true)) ? ("Der Browser kann die Kursdaten speichern,\nes werden momentan " + mys.length + " Bytes durch Kursdaten belegt.") : "Der Browser kann keine lokalen Daten speichern, Eingaben in Aufgabenfeldern werden nicht gespeichert.";
    }
  }

  // update output field for 'intersiteobj' if it exists
  var e = document.getElementById("OBJOUT");
  if (e != null) {
    // textarea exists only on the settings page, is created and prepared by the page before load happens
    e.value = JSON.stringify(intersiteobj);
  }

  // update output field for 'intersiteobj' if it exists
  var e = document.getElementById("OBJARRAYS");
  if (e != null) {
    // textarea exists only on the settings page, is created and prepared by the page before load happens
    if (intersiteactive == true) {
        e.value = "SITES:\n";
        var i = 0;
        for (i = 0; i < intersiteobj.sites.length; i++) {
            e.value += intersiteobj.sites[i].uxid + "\n";
        }
        e.value += "\nSCORES:\n";
        var i = 0;
        for (i = 0; i < intersiteobj.scores.length; i++) {
            e.value += intersiteobj.scores[i].siteuxid + "->" + intersiteobj.scores[i].uxid + ": " + intersiteobj.scores[i].points + "/" + intersiteobj.scores[i].maxpoints + "\n";
        }
    }
  }

  // update output field for course statistics if it exists
  var e = document.getElementById("CDATAS");
  if (e != null) {
    // textarea exists only on the settings page, is created and prepared by the page before load happens
    if ((intersiteactive==true) && (intersiteobj.configuration.CF_LOCAL == "0")) {
        e.innerHTML = "Datenspeicherung wurde durch Benutzer deaktiviert, es werden keine Kursdaten gespeichert.";
    } else {
      if ((intersiteactive==true) && (localStoragePresent==true)) {
        var s = "";
        var p = [];
        var t = [];
        var si = [];
        for (k = 0; k < globalexpoints.length; k++) {
          p[k] = 0; t[k] = 0; si[k] = 0;
          var j = 0;
          for (j = 0; j < intersiteobj.scores.length; j++) {
            if ((intersiteobj.scores[j].section == (k+1)) && (intersiteobj.scores[j].siteuxid.slice(0,6) != "VBKMT_")) {
                p[k] += intersiteobj.scores[j].points;
                if (intersiteobj.scores[j].intest == true) { t[k] += intersiteobj.scores[j].points; }
            }
          }

          for (j = 0; j < intersiteobj.sites.length; j++) {
            if (intersiteobj.sites[j].section == (k+1)) {
                si[k] += intersiteobj.sites[j].points;
            }
          }

          s += "<strong>Kapitel " + (k+1) + ": " + globalsections[k] + "</strong><br />";
          s += "Insgesamt " + si[k] + " von " + globalsitepoints[k] + " Lerneinheiten des Moduls besucht.<br />";
          s += "<progress id='slidebar0_" + k + "' value='" + si[k] + "' max='" + globalsitepoints[k] + "'></progress><br />";
          s += "Insgesamt " + p[k] + " von " + globalexpoints[k] + " Punkten der Aufgaben erreicht.<br />";
          s += "<progress id='slidebar1_" + k + "' value='" + p[k] + "' max='" + globalexpoints[k] + "'></progress><br />";
          s += "Insgesamt " + t[k] + " von " + globaltestpoints[k] + " Punkten im Abschlusstest erreicht.<br />";
          s += "<progress id='slidebar2_" + k + "' value='" + t[k] + "' max='" + globaltestpoints[k] + "'></progress><br />";
          var ratio = t[k]/globaltestpoints[k];
          if (ratio < 0.9) {
            s += "<span style='color:#E00000'>Abschlusstest ist noch nicht bestanden.</span>";
          } else {
            s += "<span style='color:#00F000'>Abschlusstest ist BESTANDEN.</span>";
          }
          s += "<br /><br />";

        }
        e.innerHTML = s;
      } else {
        e.innerHTML = "Der Browser kann keine lokalen Daten speichern, Eingaben in Aufgabenfeldern werden nicht gespeichert. Modifizieren Sie ggf. die Auswahl auf der Einstellungsseite.";
      }
    }
  }
}


// callbacks for pushlogin

function pushlogin_s_success(data) {
    // hotfix: parallel code in pushlogin_success !!!
    logMessage(VERBOSEINFO, "login success, data = " + JSON.stringify(data));
    if (data.status == false) { pushlogin_error("Login gescheitert", null); return; }
    logMessage(VERBOSEINFO, "Login ok, role = " + data.role);


    // store data
    var datastring = JSON.stringify(intersiteobj);
    userdata.writeData(false, intersiteobj.login.username, datastring, pushwrite_success, pushwrite_error); // logout is done by the write callbacks
}

function pushlogin_success(data) {
    logMessage(VERBOSEINFO, "login success, data = " + JSON.stringify(data));
    if (data.status == false) { pushlogin_error("Login gescheitert", null); return; }
    logMessage(VERBOSEINFO, "Login ok, role = " + data.role);


    // store data
    var datastring = JSON.stringify(intersiteobj);
    userdata.writeData(true, intersiteobj.login.username, datastring, pushwrite_success, pushwrite_error); // logout is done by the write callbacks 
}

function pushlogin_error(message, data) {
  logMessage(CLIENTERROR, "Konnte Daten nicht auf Server ablegen: " + message + ", data = " + JSON.stringify(data));
  logMessage(CLIENTONLY, "Server nicht erreichbar, speichere Daten im Browser und aktualisiere Server sobald Verbindung wieder hergestellt ist");
  setIntersiteType(3); // we are now in mode local>server
}

function pushlogout_success(data) {
  logMessage(VERBOSEINFO,"pushlogout success");
}

function pushlogout_error(message, data) {
  logMessage(VERBOSEINFO,"pushlogout error: " + message + ", data = " + JSON.stringify(data));
}

function pushwrite_success(data) {
  logMessage(VERBOSEINFO,"pushwrite success, data = " + JSON.stringify(data));
  setIntersiteType(2); // server is now up to date
  userdata.logout(false, pushlogout_success, pushlogout_error);
}

function pushwrite_error(message, data) {
  logMessage(VERBOSEINFO,"pushwrite error: " + message + ", data = " + JSON.stringify(data) + ", versuche logout...");
  userdata.logout(false, pushlogout_success, pushlogout_error);
}

// Writes all available data into the storage
// synced == true => only do synchronous ajax calls (necessary when calling unload-Handler for example because the callback page would be gone when the request get's replied to)
function pushISO(synced) {
  logMessage(VERBOSEINFO,"pushISO start (synced = " + synced + ")");
  var s = JSON.stringify(intersiteobj);
  if (localStoragePresent == true) {
    if (doScorm == 1) {
      localStorage.setItem("LOCALSCORM", JSON.stringify(pipwerks.scormdata));
      logMessage(VERBOSEINFO,"Aktualisiere SCORM Uebertragungsobjekt");
    }
    localStorage.setItem(getObjName(), s);
    if ((intersiteobj.login.type == 2) || (intersiteobj.login.type == 3)) {
        // Eintrag in Serverdatenbank aktualisieren
        logMessage(VERBOSEINFO,"Aktualisiere DB-Server (synced = " + synced + ")");
        if (synced) {
          userdata.login(false, intersiteobj.login.username, intersiteobj.login.password, pushlogin_s_success, pushlogin_error); // sync-version of the success callbacks
        } else {
          userdata.login(true, intersiteobj.login.username, intersiteobj.login.password, pushlogin_success, pushlogin_error);
        }
    }
  }
  updateLoginfield();
  logMessage(VERBOSEINFO,"pushISO finish");
}

// Opens a new webpage (from the local packet) in a new browser tab
// localurl sollte direkt aus dem href-Attribut bei anchors genommen werden TODO: Translation
// Marks the page as visited in 'intersiteobj'
function opensite(localurl) {
  //window.location.href = localurl; // fetches the new page

  // pushISO(); is now called on the pages by beforeunload

  if (intersiteactive == true) {
    if (intersiteobj.configuration.CF_USAGE == "1") {

      var timestamp = +new Date();
      var cm = "OPENSITE: " + "CID:" + signature_CID + ", user:" + intersiteobj.login.username + ", timestamp:" + timestamp + ", SITEUXID:" + SITE_UXID + ", localurl:" + localurl;
      sendeFeedback( { statistics: cm }, false ); // synced, otherwise the page with callbacks is gone when the request is completed
    }
  }

  window.open(localurl,"_self");
}

/*
 * Sends an object to the given URL via CORS request
 *
 * url: URL the object is sent to
 * data: object that should be sent
 * success: callback that get's called in case of success. Input as follows:
 *      function( response ) {}
 * error: Callback, der im Fehlerfall ausgefuehrt wird, eine Funktion der Form:
 * error: callback that get's called in case of errors. Input as follows:
 *      function( errorMessage ) {}
 * */
// Should be merged with function from userdata.js
function sendCorsRequest( url, data, success, error,async ) {
        logMessage(VERBOSEINFO, "intersite.sendCorsRequest called, type = POST, url = " + url + ", async = " + async + ", data = " + JSON.stringify(data));
        if (forceOffline == 1) {
            logMessage(VERBOSEINFO, "Send request omittet, course is in offline mode")
        }
        $.ajax( url, {
                type: 'POST',
                async: async,
                cache: false,
                contentType: 'application/x-www-form-urlencoded',
                crossDomain: true,
                data: data,
                //dataType: 'html', //Data type that's requeset for the response
                error: error,
                success: success
                //statusCode: {}, //list of handlers for various HTTP status codes
                //timout: 1000, //Timeout in ms
        });
}

/*
 * The sent feedback get's documented here (the callbacks write into there)
 * This provides an overview of successfull and failed feedbacks.
 *
 * Array of objects as follows:
 * {
 *      success: true/false,
 *      status: string,
 *      feedback: string,
 *      timestamp: timestamp
 * }
 * */
var feedbackLog = [];

/*
 * Sends a feedback string to the feedback server to save it in the databse
 *
 * The URL is taken from the global variable 'feedback_service'
 *
 * content:
 *  {
 *      feedback: "feedback entered manually by the user",
 *      statistics: "autoamtic feedback for statistics"
 *  }
 * */
function sendeFeedback( content,async ) {
        //send feedback only if a feedbackserver has been specified
        if( feedback_service != "" ) {
                sendCorsRequest( feedback_service, content,
                                //success callback
                                function( value ) {
                                        logMessage(VERBOSEINFO,"SendeFeedback success callback: " + JSON.stringify(value));
                                        feedbackLog.push( { success: true, status: value, feedback: content, timestamp: (new Date).getTime() } );
                                },
                                //error callback
                                function( httpRequest, textStatus, errorThrown ) {
                                        logMessage(VERBOSEINFO,"SendeFeedback error callback: " + textStatus + ", thrown: " + JSON.stringify(errorThrown));
                                        feedbackLog.push( { success: false, status: textStatus, feedback: content, timestamp: (new Date).getTime() });
                                }
                ,async);
        }
}

// ---------------------------------------------- configuration routines ------------------------------------------------

function confHandlerChange(id) {
  var e = document.getElementById(id);
  if ((e != null) && (intersiteactive == true)) {
    var c = e.checked;
    if (intersiteobj.active == true) {

      if ((intersiteobj.configuration.CF_LOCAL == "1") && (id == "CF_LOCAL") && (c == false)) {
          if (confirm("Ohne lokale Datenspeicherung gehen die Benutzer- und Kursdaten verloren. Trotzdem ohne Datenspeicherung fortfahren?") == false) { c = 1; e.checked = true; }
      }


      switch(id) {
        case "CF_LOCAL": { intersiteobj.configuration.CF_LOCAL = (c) ? "1" : "0"; break; }
        case "CF_USAGE": { intersiteobj.configuration.CF_USAGE = (c) ? "1" : "0"; break; }
        case "CF_TESTS": { intersiteobj.configuration.CF_TESTS = (c) ? "1" : "0"; break; }
      }
    }

    pushISO(false);
    UpdateSpecials();
    updateLoginfield();
  }
}

function confHandlerISOLoad() {
  if (intersiteactive == true) {
    if (intersiteobj.active == true) {
      var e;
      e = document.getElementById("CF_LOCAL");
      if (e != null) { e.checked = (intersiteobj.configuration.CF_LOCAL == "1") ? true : false; }
      e = document.getElementById("CF_USAGE");
      if (e != null) { e.checked = (intersiteobj.configuration.CF_USAGE == "1") ? true : false; }
      e = document.getElementById("CF_TESTS");
      if (e != null) { e.checked = (intersiteobj.configuration.CF_TESTS == "1") ? true : false; }
    }
  }
}

// -------------------------------------------------- user management (TODO: outsource into userdata.js) ---------------------------------------------------

function userlogin_click() {
  logMessage(VERBOSEINFO, "userlogin geklickt");

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

  var rt = allowedUsername(user_login);
  if (rt != "") { alert(rt); return; }
  rt = allowedPassword(user_pw);
  if (rt != "") { alert(rt); return; }

  logMessage(VERBOSEINFO, "Starte Login " + user_login);

  // Try loggin in to the server.
  userdata.login(true, user_login, user_pw, userlogin_success, userlogin_error);
  // continue with callbacks
}

function userlogin_success(data) {
    logMessage(VERBOSEINFO, "userlogin success");
    if (data.status == false) { userlogin_error("Login gescheitert", null); return; }
    logMessage(VERBOSEINFO, "Login ok, username = " + data.username + ", role = " + data.role);
    userdata.getData(true, undefined, loginread_success, loginread_error); // logout is done by the write callbacks
  // continue with callbacks
}

function userlogin_error(message, data) {
  if (typeof(data) == "object") {
      if (data.error == "invalid password") {
        alert("Benutzername oder Passwort sind nicht korrekt, bitte versuchen Sie es nochmal.");
        logMessage(VERBOSEINFO, "Login wegen fehlerhaftem Benutzernamen/Passwort nicht akzeptiert");
        return;
      }
  }
  logMessage(CLIENTERROR, "Login gescheitert: " + message + ", data = " + JSON.stringify(data));
}

function loginread_success(data) {
  if (data.status == false) {
      logMessage(VERBOSEINFO, "login read successm but status error: " + data.error);
      return;
  }

  logMessage(VERBOSEINFO,"loginread success");
  var iso = JSON.parse(data.data);

  logMessage(VERBOSEINFO, "iso = " + JSON.stringify(iso));

  intersiteobj = iso;
  setIntersiteType(2); // are now synchronous

  // TODO: belongs to quickfix, should be removed
  userdata.logout(true, pushlogout_success, pushlogout_error);
}

function loginread_error(message, data) {
  logMessage(CLIENTERROR, "loginread error: " + message + ", data = " + JSON.stringify(data) + ", trying logout...");
  logMessage(CLIENTONLY, "Konnte Benutzerdaten nicht von Server uebertragen!");
  userdata.logout(true, pushlogout_success, pushlogout_error);
}


function userreset_click() {
  logMessage(VERBOSEINFO, "userreset_click");
  var s = "Wirklich alle Benutzer- und Kursdaten ";
  if (intersiteactive == true) {
      if (intersiteobj.config != null) {
          if (intersiteobj.config.type > 0) {
              s += "(Benutzername " + intersiteobj.config.username + ") ";
          }
      }
  }
  s += "löschen? Dieser Vorgang kann nicht rückgängig gemacht werden!";
  if (confirm(s) == true) SetupIntersite(true);
}

// returns "" for valid usernames, error string otherwise
function allowedUsername(username) {
    if ((username.length < 6) || (username.length > 18)) {
         return "Der Loginname muss mindestens 6 und höchstens 18 Zeichen enthalten";
    }

    if (RegExp('[^a-z0-9\\-\\+_]', 'i').test(username)) {
        return "Im Loginnamen sind nur lateinische Buchstaben und Zahlen sowie die Sonderzeichen _ - + erlaubt.";
    }

    return "";
}

// return "" for valid passwords, error string otherwise
function allowedPassword(password) {
    if ((password.length < 6) || (password.length > 18)) {
         return "Das Passwort muss mindestens 6 und höchstens 18 Zeichen enthalten";
    }

    if (RegExp('[^a-z0-9\\-\\+_]', 'i').test(password)) {
          return "Im Passwort sind nur lateinische Buchstaben und Zahlen sowie die Sonderzeichen _ - + erlaubt.";
    }

    return "";
}

// type = 1 -> Create locally only, type = 2 -> create locally and immediately upgrade to server user
function usercreatelocal_click(type) {
    if (type==2) {
        alert("In der Korrekturversion ist das Anlegen eines Netz-Benutzers nicht möglich um eine Verzerrung der Aufgaben- und Nutzerdatenauswertung zu vermeiden, bitte registrieren Sie sich nur innerhalb Ihres Browsers mit dem Button unten.");
        return;
    }

    if (intersiteactive == false) {
        alert("Keine Datenspeicherung möglich, kann Benutzer nicht anlegen!");
        return;
    }

    if (intersiteobj.configuration.CV_LOCAL == "0") {
        alert("Keine Datenspeicherung möglich, lokale Datenspeicherung muss zuerst in den Einstellungen aktiviert werden.");
        return;
    }


    var un = document.getElementById("USER_UNAME");
    var vn = document.getElementById("USER_VNAME");
    var sn = document.getElementById("USER_SNAME");
    var em = document.getElementById("USER_EMAIL");
    var una = un.value;

    var rt = allowedUsername(una);
    if (rt != "") {
        alert(rt);
        return;
    }

    var pws = "";
    if (4==4) { //TODO: Wy is this always true statement here?
      // Version for correction: username=password

    } else {
      // normal version: password requested from user
      pws = prompt("Geben Sie ein Passwort für den Benutzer " + una + " ein:");
      if (pws == null) return; // user has pressed abort
      rt = allowedPassword(pws);
      if (rt != "") {
          alert(rt);
          return;
      }

      var pws2 = prompt("Geben Sie das Passwort zur Sicherheit nochmal ein:");
      if (pws2 == null) return; // user has pressed abort
      if (pws2 != pws) {
          alert("Die Passwörter stimmen nicht überein.");
          return;
      }
    }


    logMessage(CLIENTINFO, "User set to local for username " + una);
    logMessage(CLIENTINFO, "User was previously on type=" + intersiteobj.login.type);
    setIntersiteType(1);
    intersiteobj.login.username = una;
    intersiteobj.login.password = pws;
    intersiteobj.login.vname = vn.value;
    intersiteobj.login.sname = sn.value;
    intersiteobj.login.email = em.value;

    updateLoginfield();

    logMessage(VERBOSEINFO, "Neuen Benutzer " + intersiteobj.login.username + " angelegt.");

    if (intersiteobj.configuration.CF_USAGE == "1") {
          var timestamp = +new Date();
          var cm = "USERCREATE: " + "CID:" + signature_CID + ", user:" + una + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
          sendeFeedback( { statistics: cm }, true );
    }

    if (type == 2) {
        logMessage(CLIENTINFO, "Benutzer wird auf Typ 2 erweitert");
        userdata.addUser(true, intersiteobj.login.username, intersiteobj.login.password, undefined, register_success, register_error);
    }
}

// callbacks for first sign up
function register_success(data) {
  logMessage(VERBOSEINFO, "Register success, data = " + JSON.stringify(data));
  var na;
  na = (scormLogin == 1) ? (intersiteobj.login.sname) : (intersiteobj.login.username);
  if (data.status == true) {
      setIntersiteType(3);
      pushISO(false);
      if (intersiteobj.configuration.CF_USAGE == "1") {
        var timestamp = +new Date();
        var cm = "USERREGISTER: " + "CID:" + signature_CID + ", user:" + intersiteobj.login.username + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
        sendeFeedback( { statistics: cm }, true );
      }
      // alert("Benutzer " + na + " wurde erfolgreich angelegt\n(" + feedbackdesc + ")");
  } else {
      if (intersiteobj.configuration.CF_USAGE == "1") {
        var timestamp = +new Date();
        var cm = "USERREGISTERERROR: " + "CID:" + signature_CID + ", user:" + una + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent + ", data=" + JSON.stringify(data);
        sendeFeedback( { statistics: cm }, true );
      }
      setIntersiteType(1);
      if (data.error == "user already exists") {
          alert("Benutzer " + na + " existiert schon auf dem Server, bitte geben Sie einen neuen Benutzernamen ein.");
      } else {
          alert("Benutzer " + na + " konnte nicht angelegt werden, versuchen Sie es zu einem anderen Zeitpunkt nochmal. Der Benutzer wird nur im Browser angelegt.");
      }
  }
}


function register_error(message, data) {
  logMessage(VERBOSEINFO, "Register error: " + message + ", data = " + JSON.stringify(data));
  var na;
  na = (scormLogin == 1) ? (intersiteobj.login.sname) : (intersiteobj.login.username);
  alert("Benutzer " + na + " konnte nicht angelegt oder der Server nicht erreicht werden, versuchen Sie es zu einem anderen Zeitpunkt nochmal. Der Benutzer wird nur im Browser angelegt.");
  setIntersiteType(1);
}


// Callbacks for check_user call to the database (checking if a user exists)

function check_user_success(data) {
    logMessage(VERBOSEINFO, "checkuser success");
    var e = document.getElementById("USER_UNAME");
    if (e == null) {
        logMessage(VERBOSEINFO, "USER_UNAME-Feld nicht gefunden");
        return;
    }

    if ((data.action == "check_user") && (data.status == true)) {
      if (data.user_exists == true) {
        ulreply_set(false, "Benutzername ist schon vergeben.");
      } else {
        ulreply_set(true, "Dieser Benutzername ist verfügbar! <button type='button' style='background: #00FF00' onclick='usercreatelocal_click(2);'>Jetzt registrieren</button>");
      }
    } else {
        logMessage(VERBOSEINFO, "checkuser success, status=false, data = " + JSON.stringify(data));
        ulreply_set(false, "Kommunikation mit Server (" + feedbackdesc + ") nicht möglich.");
    }

}

function check_user_error(message, data) {
  logMessage(VERBOSEINFO, "checkuser error:" + message + ", data = " + JSON.stringify(data));
  ulreply_set(false, "Kommunikation mit Server (" + feedbackdesc + ") nicht möglich.");
}


function ulreply_set(ok, m) {
  var e;
  if (ok == false) {
    var s = "../../images/false.gif";
    e = document.getElementById("USER_UNAME");
    if (e == null) return; else {
        if (e.value == "") {
            e.style.backgroundColor = QCOLOR_NEUTRAL;
            s = "../../images/questionmark.gif";
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
    if (e == null) return; else e.src = "../../images/right.gif";
  }
  e = document.getElementById("ulreply_p");
  if (e == null) return; else e.innerHTML = m;
}

// checks if the user already exists in the database (true) or not (false)
function usercheck() {
    var e = document.getElementById("USER_UNAME");
    if (e == null) {
        logMessage(DEBUGINFO, "USER_UNAME-Feld nicht gefunden");
        return;
    }

    var una = e.value;
    var rt = allowedUsername(una);
    if (rt != "") {
        ulreply_set(false,rt);
        return;
    }

    userdata.checkUser(true, una, check_user_success, check_user_error);
}

function setIntersiteType(t) {
  logMessage(VERBOSEINFO, "Set type=" + t);
  if (intersiteactive == true) {
      intersiteobj.login.type = t;
  } else {
      logMessage(DEBUGINFO, "intersiteactive == false");
  }
}

// ----------------------------------- Favorites management -----------------------------------------

function createHelpFavorite() {
  var fav = {
    type: "Tipp",
    color: "00FF00",
    text: "Eingangstest probieren",
    pid: "?",
    icon: "test01.png"
  };
  logMessage(VERBOSEINFO, "New HelpFavorite created");
  return fav;
}

function generateShortFavoriteList() {
  if (intersiteactive == false) {
    return "Datenspeicherung nicht möglich";
  }
  
  if (typeof(intersiteobj.favorites) != "object") {
    intersiteobj.favorites = new Array();
  }

  var i;
  var s = "";
  for (i = 0; i < intersiteobj.favorites.length; i++) {
    s += "<img src=\"" + linkPath + "images/" + intersiteobj.favorites[i].icon + "\" style=\"width:20px;height:20px\">&nbsp;&nbsp;";
    s += "<a href=\"\" >" + intersiteobj.favorites[i].text + "</a><br />";
  }
  
  return s;
}

function generateLongFavoriteList() {
  if (intersiteactive == false) {
    return "Datenspeicherung nicht möglich";
  }
  
  if (typeof(intersiteobj.favorites) != "object") {
    intersiteobj.favorites = new Array();
  }

  var i;
  var s = "";
  for (i = 0; i < intersiteobj.favorites.length; i++) {
    s += "<img src=\"" + linkPath + "images/" + intersiteobj.favorites[i].icon + "\" style=\"width:48px;height:48px\">&nbsp;&nbsp;";
    s += "<a href=\"\" >" + intersiteobj.favorites[i].text + "</a><br />";
  }
  
  return s;
}
