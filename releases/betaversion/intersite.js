// encoding: ASCII !

// liefert local-storage-name des intersite-Objekts
function getObjName() {
    return "isobj_" + signature_main; // Wichtig: gleiches Objekt auch fuer verschiedene Versionen!
}

// Typen von Anmeldungen:
// Typ 0: Anonym local:
//        - Strings in login-Teilobjekt sind leer, Benutzer ist anonym
//        - intersiteobj wird in Abhaengigkeit der Flags in LocalStorage abgelegt
// Typ 1: Personalisiert local:
//        - Strings in login-Teilobjekt sind mit Nutzerdaten gefuellt, aber Passwort ist leer
//        - intersiteobj wird in Abhaengigkeit der Flags in LocalStorage abgelegt
// Typ 2: Personalisiert local to server:
//        - Strings in login-Teilobjekt sind mit Nutzerdaten gefuellt und Paar (username,password) ist vom Server akzeptiert
//        - intersiteobj wird primaer lokal gehalten und nur bei logout an server gesendet, es wird nichts vom Server geholt
// Typ 3: Personalisiert server:
//        - Strings in login-Teilobjekt sind mit Nutzerdaten gefuellt und Paar (username,password) ist vom Server akzeptiert
//        - Lokales intersiteobj enthaelt nur config und login-Info, richtiges Objekt wird vom Server geholt und stets an server gepusht




function createIntersiteObj() {
  // console.log("New IntersiteObj created");
  var obj = { active: false, configuration: {}, scores: [], sites: [], login: { type: 0, vname: "", sname: "", username: "", password: "" } };
  return obj;
}


// Hilfsfunktion zum rekursiven Klonen von einfachen Objekten in JS
function objClone(obj) {
  // return JSON.parse(JSON.stringify(obj));
    if(obj == null || typeof(obj) != 'object')
        return obj;

    var temp = obj.constructor();
    if ((typeof temp) != "object") console.log("PROBLEM with object" + obj);

    for(var key in obj) {
        if(obj.hasOwnProperty(key)) {
            temp[key] = objClone(obj[key]);
        }
    }
    return temp;
}

// Initialisiert das Intersite-Objekt, falls update==true werden vorhandene Daten ueberschrieben
function SetupIntersite(clearuser) {
  
  if (typeof(localStorage) !== "undefined") {
    localStoragePresent = true;
    // console.log("localStorage found");
  } else {
    localStoragePresent = false;
    console.log("localStorage NOT found");
    var stor = window.localStorage;
    if (typeof(stor) !== "undefined") {
      console.log("window.localStorage as stor found!");
    }
  }
  
  if (intersitelinks != true) {
    var links = document.getElementsByClassName("MINTERLINK");
    for (i=0; i<links.length; i++) {
      links[i].onclick = function() { opensite(this.href); return false;}
    }
    intersitelinks = true;
  }

  if (localStoragePresent == false) {
    intersiteobj = createIntersiteObj();
    intersiteobj.active = true;
    intersiteobj.startertitle = document.title;
    intersiteobj.configuration.CF_LOCAL = "0";
    intersiteobj.configuration.CF_USAGE = "0";
    intersiteobj.configuration.CF_TESTS = "0";
    intersiteactive = true;
    console.log("Intersite setup WITHOUT STORAGE from scratch from " + intersiteobj.startertitle);
  } else {
    var iso = localStorage.getItem(getObjName());
    if (clearuser == true) {
        if (intersiteactive == true) {
          if (intersiteobj.configuration.CF_USAGE == "1") {
            var timestamp = +new Date();
            var cm = "USERRESET: " + "CID:" + signature_CID + ", user:" + currentUser + ", timestamp:" + timestamp;
            sendeFeedback( { statistics: cm },true );
          }
        }
        iso = null;
        console.log("Userreset verlangt");
    }
    if (iso == null) {
      intersiteobj = createIntersiteObj();
      intersiteobj.active = true;
      intersiteobj.startertitle = document.title;
      intersiteobj.configuration.CF_LOCAL = "1";
      intersiteobj.configuration.CF_USAGE = "1";
      intersiteobj.configuration.CF_TESTS = "1";
      intersiteactive = true;
      // console.log("Intersite setup with local storage from scratch from " + intersiteobj.startertitle);
      if ((intersiteobj.configuration.CF_USAGE == "1") && (clearuser == false)) {
	  var timestamp = +new Date();
	  var cm = "INTERSITEFIRST: " + "CID:" + signature_CID + ", user:" + currentUser + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
	  sendeFeedback( { statistics: cm },true );
      }
    } else {
      intersiteobj = JSON.parse(iso);
      intersiteactive = true;
      // console.log("Got an intersite object from " + intersiteobj.startertitle);
      LoadSiteData();
    }
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
          // console.log("Points for site " + sid + " modernized");
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
          // console.log("Points for site " + sid + " ADDED at position " + k);
        }
     }
  }
  
  UpdateSpecials();
  confHandlerISOLoad()
  updateLoginfield();
  if (clearuser == true) pushISO();
}

function updateLoginfield() {
  var e = document.getElementById("RESETBUTTON");
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
                    s = "Benutzername: " + intersiteobj.login.username + 
                        " (" + intersiteobj.login.vname + " " + intersiteobj.login.sname +
                        "),<br />Datenspeicherung auf Server ";
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

            if ((t == 2) || (t == 3)) { s += "(" + feedbackdesc + ")"; }
                
            if (t != 0) {
                    var z = document.getElementById("USER_UNAME");
                    if (z != null) { z.value = intersiteobj.login.username; z.style.backgroundColor = "#70FFFF"; }
                    z = document.getElementById("USER_PW");
                    if (z != null) { z.value = intersiteobj.login.password; z.style.backgroundColor = "#70FFFF"; }
                    z = document.getElementById("USER_VNAME");
                    if (z != null) { z.value = intersiteobj.login.vname; z.style.backgroundColor = "#70FFFF"; }
                    z = document.getElementById("USER_SNAME");
                    if (z != null) { z.value = intersiteobj.login.sname; z.style.backgroundColor = "#70FFFF"; }
                    currentUser = intersiteobj.login.username;
            } else {
                    var z = document.getElementById("USER_UNAME");
                    if (z != null) { z.value = ""; z.style.backgroundColor = "#E0E3E0"; }
                    z = document.getElementById("USER_PW");
                    if (z != null) { z.value = ""; z.style.backgroundColor = "#E0E3E0"; }
                    z = document.getElementById("USER_VNAME");
                    if (z != null) { z.value = ""; z.style.backgroundColor = "#E0E3E0"; }
                    z = document.getElementById("USER_SNAME");
                    if (z != null) { z.value = ""; z.style.backgroundColor = "#E0E3E0"; }
                    currentUser = "";
            }
           
            
        } else s = "Keine Anmeldedaten verfügbar!";
    } else s = "Keine Anmeldedaten vom Browser verfügbar!";
    e.style.color = "#000000";
    e.innerHTML = s;
    
    // console.log("Userfield gesetzt");
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

// Schreibt alle vorhandenen Daten in die Storage
function pushISO() {
  intersiteobj.pipwerksscorm = objClone(pipwerks.scormdata);
  var s = JSON.stringify(intersiteobj);
  if (localStoragePresent == true) {
    localStorage.setItem(getObjName(), s);
  }
  updateLoginfield();
}

// Oeffnet eine neue Webseite (aus dem lokalen Paket) in einem neuen Browsertab
// localurl sollte direkt aus dem href-Attribut bei anchors genommen werden
// Vermerkt die Seite als angeschaut im intersiteobj
function opensite(localurl) {
  //window.location.href = localurl; // holt die neue Seite

  // pushISO(); wird jetzt von unbeforeunload auf den Seiten ausgefuehrt

  if (intersiteactive == true) {
    if (intersiteobj.configuration.CF_USAGE == "1") {
        
      var timestamp = +new Date();
      var cm = "OPENSITE: " + "CID:" + signature_CID + ", user:" + currentUser + ", timestamp:" + timestamp + ", SITEUXID:" + SITE_UXID + ", localurl:" + localurl;
      sendeFeedback( { statistics: cm },false ); // synced, sonst ist Seite mit Callbacks weg wenn Auftrag fertig
    }
  }
  
  window.open(localurl,"_self");
}

function LoadSiteData() {
  if ((typeof intersiteobj.pipwerksscorm) != "undefined") {
      pipwerks.scormdata = objClone(intersiteobj.pipwerksscorm);
      //pipwerks = obj.Clone(intersiteobj.pipwerksscormx);
      // console.log("SCORMData from intersite loaded");
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
					// console.log("Success callback: " + value);
					feedbackLog.push( { success: true, status: value, feedback: content, timestamp: (new Date).getTime() } );
				},
				//error callback
				function( httpRequest, textStatus, errorThrown ) {
					// console.log("Error callback: " + textStatus + ", thrown: " + errorThrown);
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
          if (confirm("Ohne lokale Datenspeicherung gehen sämtliche Benutzer- und Kursdaten verloren. Trotzdem ohne Datenspeicherung fortfahren?") == false) { c = 1; e.checked = true; }
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

function userreset_click() {
  var s = "Wirklich sämtliche Benutzer- und Kursdaten ";
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

function usercreate_click() {
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
    if (un.value.trim().length < 6) {
        alert("Der Loginname muss mindestens 6 Zeichen enthalten");
        return;
    }
    
    var una = un.value;
    
    var i;
    for (i = 0; i < una.length; i++) {
        var c = una.charAt(i);
        if (!(((c >= "A") && (c <= "Z")) || ((c >= "a") && (c <= "z")) || ((c >= "0") && (c <= "9")))) {
            alert("Im Loginnamen sind nur lateinische Buchstaben und Zahlen erlaubt, keine Sonderzeichen oder Umlaute.");
            return;
        }
    }
    
    intersiteobj.login.type = 1;
    intersiteobj.login.username = una;
    intersiteobj.login.password = "";
    intersiteobj.login.vname = vn.value;
    intersiteobj.login.sname = sn.value;
    
    updateLoginfield();    
    
    alert("Neuen Benutzer " + intersiteobj.login.username + " angelegt.");

    if (intersiteobj.configuration.CF_USAGE == "1") {
          var timestamp = +new Date();
          var cm = "USERCREATE: " + "CID:" + signature_CID + ", user:" + currentUser + ", timestamp:" + timestamp + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
          sendeFeedback( { statistics: cm },true );
    }
}

function userlogin_click() {
  alert("Noch nicht implementiert!");
}
