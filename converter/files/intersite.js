// encoding: ASCII !

// liefert local-storage-name des intersite-Objekts
function getObjName() {
    return "isobj_" + signature_main; // Wichtig: gleiches Objekt auch fuer verschiedene Versionen!
}

// Typen von Anmeldungen:
// Typ -1: Kein LocalStorage verfuegbar, es kann nichts gespeichert werden
//        - Daten in intersiteobj existieren, werden aber nicht gespeichert
//        - Jede neu aufgerufene Seite erzeugt intersiteobj komplett neu
// Typ  0: Anonym local:
//        - Strings in login-Teilobjekt sind leer, Benutzer ist anonym
//        - intersiteobj wird in Abhaengigkeit der Flags in LocalStorage abgelegt
// Typ  1: Personalisiert local:
//        - Strings in login-Teilobjekt sind mit Nutzerdaten gefuellt, aber Passwort ist leer
//        - intersiteobj wird in Abhaengigkeit der Flags in LocalStorage abgelegt
// Typ  2: Personalisiert server sync:    (diese beiden Typen sind die einzig moeglichen falls scormLogin==true)
//        - Strings in login-Teilobjekt sind mit Nutzerdaten gefuellt und Paar (username,password) ist vom Server akzeptiert
//        - Daten in intersiteobj sind mit Serverdaten identisch und muessen nicht gepusht werden
// Typ  3: Personalisiert server async:
//        - Strings in login-Teilobjekt sind mit Nutzerdaten gefuellt und Paar (username,password) ist vom Server akzeptiert
//        - Daten in intersiteobj koennen aktueller sein als Serverdaten und muessen noch gepusht werden



function createIntersiteObj() {
  logMessage(VERBOSEINFO,"New IntersiteObj created");
  var obj = { active: false, configuration: {}, scores: [], sites: [], login: { type: 0, vname: "", sname: "", username: "", password: "", email: "" } };
  return obj;
}

function createIntersiteObjFromSCORM(s_login, s_name, s_pw) {
  logMessage(VERBOSEINFO,"New IntersiteObj for scormlogin created");
  var obj = createIntersiteObj();
  obj.login.type = 2;
  obj.login.vname = "";
  obj.login.sname = s_name;
  obj.login.username = s_login;
  obj.login.password = s_pw;
  obj.login.email = "";

  // userdata.check_user(obj.login.username, check_user_scorm_success, check_user_scorm_error); // function continues in callbacks!


  return obj;
  
}

// Callbacks fuer createIntersiteObjFormSCORM
function check_user_scorm_success(data) {
  logMessage(VERBOSEINFO, "checkuser_scorm success: data = " + JSON.stringify(data));
}

function check_user_scorm_error(message, data) {
  logMessage(VERBOSEINFO, "checkuser_scorm error:" + message + ", data = " + JSON.stringify(data));
}


// Hilfsfunktion zum rekursiven Klonen von einfachen Objekten in JS
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

// Initialisiert das Intersite-Objekt, falls update==true werden vorhandene Daten ueberschrieben, falls scormLogin==true wird Benutzerkennung nicht aus localStorage sondern SCORM geholt (schliesst clearuser aus)
function SetupIntersite(clearuser) {
  logMessage(VERBOSEINFO,"SetupIntersite START");
  var s_login = "";
  
  // LocalStorage nur anfragen, wenn loginscorm == 0
  if (typeof(localStorage) !== "undefined") {
    localStoragePresent = true;
    logMessage(VERBOSEINFO, "localStorage found");
  } else {
    localStoragePresent = false;
    logMessage(CLIENTERROR,"localStorage NOT found");
    var stor = window.localStorage;
    if (typeof(stor) !== "undefined") {
      logMessage(CLIENTERROR,"window.localStorage as stor found!");
    }
  }
  
  if (intersitelinks != true) {
    var links = document.getElementsByClassName("MINTERLINK");
    for (i=0; i<links.length; i++) {
      links[i].onclick = function() { opensite(this.href); return false;}
    }
    intersitelinks = true;
  }

  if (scormLogin == 1 ) {
    // SCORM: Uebergehe LocalStorage und hole Daten direkt vom DB-Server falls moeglich, sonst neuer Benutzer mit SCORM-ID und CID als login
    logMessage(VERBOSEINFO, "SCORM-Login forciert");

    var psres = pipwerks.SCORM.init();
    logMessage(VERBOSEINFO, "SCORM init = " + psres);
    psres = pipwerks.SCORM.get("cmi.learner_id");
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
    if (intersiteobj != null) {
      intersiteobj.active = true;
      intersiteactive = true;
      logMessage(VERBOSEINFO,"Intersite setup from SCORM: " + s_login);
    } else {
      intersiteactive = false;
      logMessage(VERBOSEINFO,"Intersite setup from SCORM failed: " + s_login);
    }
  } else {
    // Kein SCORM: Verwende LocalStorage falls verfuegbar
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
	      sendeFeedback( { statistics: cm },true );
	    }
	  }
	  iso = null;
	  logMessage(VERBOSEINFO, "Userreset verlangt");
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
	    sendeFeedback( { statistics: cm },true );
	}
      } else {
	intersiteobj = JSON.parse(iso);
	logMessage(VERBOSEINFO,"iso geparsed, logintype = " + intersiteobj.login.type + ", username = " + intersiteobj.login.username);
	logMessage(VERBOSEINFO,"Got an intersite object from " + intersiteobj.startertitle);
	intersiteactive = true;
      }
    }
  }
  
  if (intersiteactive == true) {
    LoadSiteData();
    // Falls Benutzer vernetzt, Passwort erfragen, einloggen und Daten von Server beziehen
    if ((intersiteobj.login.type == 2) || (intersiteobj.login.type == 3)) logMessage(VERBOSEINFO,"Type=2,3, serverget missing");
  } else {
    alert("Ihre Benutzerdaten konnten nicht vom Server geladen werden, eine automatische eMail an den Administrator wurde verschickt. Sie können den Kurs trotzdem anonym bearbeiten, eingetragene Lösungen werden jedoch nicht gespeichert!");
    var timestamp = +new Date();
    var us = "(unknown)";
    if (scormlogin == 1) us = s_login;
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

  // Seite als besucht markieren
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
  if (clearuser == true) {
      pushISO();
      ulreply_set(false,"");
  }
}

function updateLoginfield() {
  
  // Nur-Loginfelder aufbauen falls auf Seite vorhanden
  var e = document.getElementById("ONLYLOGINFIELD");
  if (e != null) {
      logMessage(VERBOSEINFO, "Einlogfeld gefunden");
      
      if (intersiteactive == true) {

          var s = "";         
          switch (intersiteobj.login.type) {
                case 0: {
                    s = "Kein Benutzer angemeldet.";
                    break;
                }

                case 1: {
                    s = "Benutzer " + intersiteobj.login.username + " (" + intersiteobj.login.vname + " " + intersiteobj.login.sname + "), nicht am Server angemeldet.";
                    break;
                }

                case 2: {
                    s = "Benutzer " + intersiteobj.login.username + " (" + intersiteobj.login.vname + " " + intersiteobj.login.sname + ") ist am Server angemeldet.";
                    break;
                }

                case 3: {
                    s = "Benutzer " + intersiteobj.login.username + " (" + intersiteobj.login.vname + " " + intersiteobj.login.sname + ") ist am Server angemeldet.";
                    break;
                }
                    
                default: {
                    logMessage(CLIENTERROR, "updateLoginfield, wrongtype=" + intersiteobj.login.type);
                    s = "Keine Anmeldung möglich!";
                    break;
                }
          }
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
    
    
  // Vollstaendiges Login-Feld in Einstellungsseite aufstellen
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
            switch (t) {
                case 0: {
                    s = "Noch keine Benutzerdaten vorhanden, Kurs wird anonym bearbeitet,<br />" + sb;
                    cr.disabled = false;
                    unf.style.display = "inline";
                    break;
                }

                case 1: {
                    s = "Benutzername: " + intersiteobj.login.username + " (" + intersiteobj.login.vname + " " + intersiteobj.login.sname + "),<br />" + sb;
                    cr.disabled = true;
                    unf.style.display = "none";
                    break;
                }

                case 2: {
                    s = "Benutzername: " + intersiteobj.login.username + 
                        " (" + intersiteobj.login.vname + " " + intersiteobj.login.sname +
                        "),<br />Datenspeicherung in diesem Browser und auf Server ";
                    cr.disabled = true;
                    unf.style.display = "none";
                    break;
                }

                case 3: {
                    // Dass es nicht aktuell ist wird hier nicht angezeigt
                    s = "Benutzername: " + intersiteobj.login.username + 
                        " (" + intersiteobj.login.vname + " " + intersiteobj.login.sname +
                        "),<br />Datenspeicherung in diesem Browser und auf Server ";
                    cr.disabled = true;
                    unf.style.display = "none";
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
    
  // Datenstand-Infofeld auf Einstellungsseite updaten falls vorhanden
  var e = document.getElementById("CHECKIS");
  if (e != null) {
    // textarea nur in Einstellungsseite vorhanden, wird dort durch Seite erzeugt und vorbereitet bevor load stattfindet
    if ((intersiteactive==true) && (intersiteobj.configuration.CF_LOCAL == "0")) {
        e.innerHTML = "Datenspeicherung wurde durch Benutzer deaktiviert, es werden keine Kursdaten gespeichert.";
    } else {
      var mys = JSON.stringify(intersiteobj);
      e.innerHTML = ((intersiteactive==true) && (localStoragePresent==true)) ? ("Der Browser kann die Kursdaten speichern,\nes werden momentan " + mys.length + " Bytes durch Kursdaten belegt.") : "Der Browser kann keine lokalen Daten speichern, Eingaben in Aufgabenfeldern werden nicht gespeichert.";
    }
  }

  // Ausgabefeld fuer intersiteobj updaten falls vorhanden
  var e = document.getElementById("OBJOUT");
  if (e != null) {
    // textarea nur in Einstellungsseite vorhanden, wird dort durch Seite erzeugt und vorbereitet bevor load stattfindet
    e.value = JSON.stringify(intersiteobj); 
  }
  
  // Ausgabefeld fuer intersitearrays updaten falls vorhanden
  var e = document.getElementById("OBJARRAYS");
  if (e != null) {
    // textarea nur in Einstellungsseite vorhanden, wird dort durch Seite erzeugt und vorbereitet bevor load stattfindet
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

  // Ausgabefeld fuer Kursstatistiken updaten falls vorhanden
  var e = document.getElementById("CDATAS");
  if (e != null) {
    // textarea nur in Einstellungsseite vorhanden, wird dort durch Seite erzeugt und vorbereitet bevor load stattfindet
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
            if ((intersiteobj.sites[j].section == (k+1)) && (intersiteobj.scores[j].siteuxid.slice(0,6) != "VBKMT_")) { 
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


// Callbacks fuer pushlogin
function pushlogin_success(data) {
    logMessage(VERBOSEINFO, "login success, data = " + JSON.stringify(data));
    if (data.status == false) { pushlogin_error("Login gescheitert", null); return; }
    logMessage(VERBOSEINFO, "Login ok, role = " + data.role);
    
    
    // Daten ablegen
    var datastring = JSON.stringify(intersiteobj);
    userdata.writeData(undefined, datastring, pushwrite_success, pushwrite_error); // logout wird von den write-Callbacks ausgefuehrt
}

function pushlogin_error(message, data) {
  logMessage(CLIENTERROR, "Konnte Daten nicht auf Server ablegen: " + message + ", data = " + JSON.stringify(data));
  logMessage(CLIENTONLY, "Server nicht erreichbar, speichere Daten im Browser und aktualisiere Server sobald Verbindung wieder hergestellt ist");
  setIntersiteType(3); // sind jetzt im Modus Lokal>Server
}

function pushlogout_success(data) {
  logMessage(VERBOSEINFO,"pushlogout success");
}

function pushlogout_error(message, data) {
  logMessage(VERBOSEINFO,"pushlogout error: " + message + ", data = " + JSON.stringify(data));
}

function pushwrite_success(data) {
  logMessage(VERBOSEINFO,"pushwrite success, data = " + JSON.stringify(data));
  setIntersiteType(2); // Server ist jetzt aktuell
  userdata.logout(pushlogout_success, pushlogout_error);
}

function pushwrite_error(message, data) {
  logMessage(VERBOSEINFO,"pushwrite error: " + message + ", data = " + JSON.stringify(data) + ", versuche logout...");
  userdata.logout(pushlogout_success, pushlogout_error);
}

// Schreibt alle vorhandenen Daten in die Storage
function pushISO() {
  logMessage(VERBOSEINFO,"pushISO start");
  intersiteobj.pipwerksscorm = objClone(pipwerks.scormdata);
  var s = JSON.stringify(intersiteobj);
  if (localStoragePresent == true) {
    localStorage.setItem(getObjName(), s);
    if ((intersiteobj.login.type == 2) || (intersiteobj.login.type == 3)) {
        // Eintrag in Serverdatenbank aktualisieren
        logMessage(VERBOSEINFO,"Aktualisiere Server");
        userdata.login(intersiteobj.login.username, intersiteobj.login.password, pushlogin_success, pushlogin_error);
    }
  }
  updateLoginfield();
  logMessage(VERBOSEINFO,"pushISO finish");
}

// Oeffnet eine neue Webseite (aus dem lokalen Paket) in einem neuen Browsertab
// localurl sollte direkt aus dem href-Attribut bei anchors genommen werden
// Vermerkt die Seite als angeschaut im intersiteobj
function opensite(localurl) {
  //window.location.href = localurl; // holt die neue Seite

  // pushISO(); wird jetzt von beforeunload auf den Seiten ausgefuehrt

  if (intersiteactive == true) {
    if (intersiteobj.configuration.CF_USAGE == "1") {
        
      var timestamp = +new Date();
      var cm = "OPENSITE: " + "CID:" + signature_CID + ", user:" + intersiteobj.login.username + ", timestamp:" + timestamp + ", SITEUXID:" + SITE_UXID + ", localurl:" + localurl;
      sendeFeedback( { statistics: cm },false ); // synced, sonst ist Seite mit Callbacks weg wenn Auftrag fertig
    }
  }
  
  window.open(localurl,"_self");
}

function LoadSiteData() {
  if ((typeof intersiteobj.pipwerksscorm) != "undefined") {
      pipwerks.scormdata = objClone(intersiteobj.pipwerksscorm);
      //pipwerks = obj.Clone(intersiteobj.pipwerksscormx);
      logMessage(VERBOSEINFO,"SCORMData from intersite loaded");
  }
}

/*
 * Sendet ein Objekt an die gegebene URL via CORS-Request
 *
 * url: URL, an die das Objekt gesendet wird
 * data: Objekt, das versendet werden soll
 * success: Callback, der im Erfolgsfall ausgefuehrt wird, eine Funktion der Form:
 * 		function( response ) {}
 * error: Callback, der im Fehlerfall ausgefuehrt wird, eine Funktion der Form:
 * 		function( errorMessage ) {}
 * */
function sendCorsRequest( url, data, success, error,async ) {
	$.ajax( url, {
		type: 'POST',
		async: async,
		cache: false,
		contentType: 'application/x-www-form-urlencoded',
		crossDomain: true,
		data: data,
		//dataType: 'html', //Erwarteter Datentyp der Antwort
		error: error,
		success: success
		//statusCode: {}, //Liste von Handlern fuer verschiedene HTTP status codes
		//timout: 1000,	//Timeout in ms
	});
}

/*
 * Hier wird das gesendete Feedback dokumentiert ( die callbacks schreiben hier rein ).
 * Damit hat man eine Uebersicht von erfolgreichen und fehlgeschlagenen Feedbacks.
 *
 * Array aus Objekten der Form:
 * {
 * 	success: true/false,
 *	status: string,
 *	feedback: string,
 *	timestamp: timestamp
 * }
 * */
var feedbackLog = [];

/* 
 * Sendet einen String an den Feedback-Server um ihn dort in der Datenbank zu speichern
 *
 * Die URL kommt aus der globalen Variable feedbackserver
 *
 * content:
 * 	{
 * 		feedback: "Manuell vom Nutzer gegebenes Feedback",
 * 		statistics: "Automatisches Feedback fuer Statistik"
 * 	}
 * 			
 * */
function sendeFeedback( content,async ) {
	//Feedback nur Senden, wenn ein feedbackserver angegeben ist
	if( feedbackserver != "" ) {
		sendCorsRequest( feedbackserver, content, 
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

// ---------------------------------------------- Konfigurationsroutinen ------------------------------------------------

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
    
    pushISO();
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

// -------------------------------------------------- Usermanagement (wird in userdata.js ausgelagert) ---------------------------------------------------

function userlogin_click() {
  logMessage(VERBOSEINFO, "userlogin geklickt");
  
  // Behandlung des schon eingelogten Benutzers:
  // type = 0: Anonym, Daten werden verworfen
  // type = 1: Lokal, Benutzer vorher fragen
  // type = 2: Server ist aktuell, lokale Daten werden verworfen
  // type = 3: Versuch vorher alles zu speichern
  
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
  
  // Versuche den Login am Server
  userdata.login(user_login, user_pw, userlogin_success, userlogin_error);
  // Weiter mit den Callbacks
}

function userlogin_success(data) {
    logMessage(VERBOSEINFO, "userlogin success");
    if (data.status == false) { userlogin_error("Login gescheitert", null); return; }
    logMessage(VERBOSEINFO, "Login ok, username = " + data.username + ", role = " + data.role);
    userdata.getData(undefined, loginread_success, loginread_error); // logout wird von den write-Callbacks ausgefuehrt
  // Weiter mit den Callbacks
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
  setIntersiteType(2); // sind jetzt synchron
 
  // Erstmal gleich wieder ausloggen
  userdata.logout(pushlogout_success, pushlogout_error);
}

function loginread_error(message, data) {
  logMessage(CLIENTERROR, "loginread error: " + message + ", data = " + JSON.stringify(data) + ", trying logout...");
  logMessage(CLIENTONLY, "Konnte Benutzerdaten nicht von Server uebertragen!");
  userdata.logout(pushlogout_success, pushlogout_error);
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

// Returnwerte: "" falls Benutzername zulaessig, Fehlerstring fuer Benutzer sonst
function allowedUsername(una) {
    if ((una.length < 6) || (una.length > 18)) {
         return "Der Loginname muss mindestens 6 und höchstens 18 Zeichen enthalten";
    }

    var i;
    for (i = 0; i < una.length; i++) {
        var c = una.charAt(i);
        if (!(((c >= "A") && (c <= "Z")) || ((c >= "a") && (c <= "z")) || ((c >= "0") && (c <= "9")) || (c == "_") || (c == "-") || (c == "+"))) {
            return "Im Loginnamen sind nur lateinische Buchstaben und Zahlen sowie die Sonderzeichen _ - + erlaubt.";
        }
    }
    
    return "";
}

// Returnwerte: "" falls Benutzername zulaessig, Fehlerstring fuer Benutzer sonst
function allowedPassword(una) {
    if ((una.length < 6) || (una.length > 18)) {
         return "Das Passwort muss mindestens 6 und höchstens 18 Zeichen enthalten";
    }

    var i;
    for (i = 0; i < una.length; i++) {
        var c = una.charAt(i);
        if (!(((c >= "A") && (c <= "Z")) || ((c >= "a") && (c <= "z")) || ((c >= "0") && (c <= "9")) || (c == "_") || (c == "-") || (c == "+"))) {
            return "Im Passwort sind nur lateinische Buchstaben und Zahlen sowie die Sonderzeichen _ - + erlaubt.";
        }
    }
    
    return "";
}

// type = 1 -> Nur lokal anlegen, type =2 -> Lokal anlegen und sofort zu Servernutzer upgraden
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
    if (4==4) {
      // Korrekturversion: username=password
              
    } else {
      // Normalversion: Password eingeben lassen
      pws = prompt("Geben Sie ein Passwort für den Benutzer " + una + " ein:");
      if (pws == null) return; // Benutzer hat Abbrechen gedrueckt
      rt = allowedPassword(pws);
      if (rt != "") {
          alert(rt);
          return;
      }
    
      var pws2 = prompt("Geben Sie das Passwort zur Sicherheit nochmal ein:");
      if (pws2 == null) return; // Benutzer hat Abbrechen gedrueckt
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
          sendeFeedback( { statistics: cm },true );
    }
    
    if (type == 2) {
        logMessage(CLIENTINFO, "Benutzer wird auf Typ 2 erweitert");
        userdata.addUser(intersiteobj.login.username, intersiteobj.login.password, undefined, register_success, register_error);
    }
}

// Callbacks fuer Erstregistrierung
function register_success(data) {
  logMessage(VERBOSEINFO, "Register success, data = " + JSON.stringify(data));
  if (data.status == true) {
      setIntersiteType(3);
      pushISO();
      if (intersiteobj.configuration.CF_USAGE == "1") {
        var timestamp = +new Date(); zertifizieren
        var cm = "USERREGISTER: " + "CID:" + signature_CID + ", user:" + intersiteobj.login.username + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
        sendeFeedback( { statistics: cm },true );
      }
      alert("Benutzer " + intersiteobj.login.username + " wurde erfolgreich angelegt\n(" + feedbackdesc + ")");
  } else {
      if (intersiteobj.configuration.CF_USAGE == "1") {
        var timestamp = +new Date();
        var cm = "USERREGISTERERROR: " + "CID:" + signature_CID + ", user:" + una + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent + ", data=" + JSON.stringify(data);
        sendeFeedback( { statistics: cm },true );
      }
      setIntersiteType(1);
      if (data.error == "user already exists") {
          alert("Benutzer " + intersiteobj.login.username + " existiert schon auf dem Server, bitte geben Sie einen neuen Benutzernamen ein.");
      } else {
          alert("Benutzer " + intersiteobj.login.username + " konnte nicht angelegt werden, versuchen Sie es zu einem anderen Zeitpunkt nochmal. Der Benutzer wird nur im Browser angelegt.");
      }
  }
}


function register_error(message, data) {
  logMessage(VERBOSEINFO, "Register error: " + message + ", data = " + JSON.stringify(data));
  alert("Benutzer " + intersiteobj.login.username + " konnte nicht angelegt oder der Server nicht erreicht werden, versuchen Sie es zu einem anderen Zeitpunkt nochmal. Der Benutzer wird nur im Browser angelegt.");
  setIntersiteType(1);
}


// Callbacks fuer UserCheck-Aufruf an Datenbank

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

// Prueft, ob der Nutzername in der DB vorhanden (true) ist oder nicht (false)
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

    userdata.checkUser(una, check_user_success, check_user_error);
}

function setIntersiteType(t) {
  logMessage(VERBOSEINFO, "Set type=" + t);
  if (intersiteactive == true) {
      intersiteobj.login.type = t;
  } else {
      logMessage(DEBUGINFO, "intersiteactive == false");
  }
}

