/*
 * Logging-Funktionalitaet
 *
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

// Globale Meldungsstufen:
// 1: CLIENTINFO   Wird als Feedback an Server geschickt, stellt eine Informationsmeldung dar
// 2: CLIENTERROR  Wird als Feedback an Server geschickt, stellt eine Fehlermeldung dar die behandelt werden muss, wird auch gesendet wenn Benutzer die USAGE abgeschaltet hat
// 3: CLIENTWARN   Wird als Feedback an Server geschickt, stellt eine interne Fehlermeldung dar die aber nicht gravierend ist
// 4: DEBUGINFO    Wird nur auf Browserkonsole ausgegeben, und nur falls es keine Releaseversion ist
// 5: VERBOSEINFO  Wird nur auf Browserkonsole ausgegeben, und nur falls es keine Releaseversion ist und verbose-flag aktiv ist
// 6: CLIENTONLY   Wird nur auf Browserkonsole ausgegeben, auch in Releases, und ohne Prefix
// 7: FATALERROR   Schwerwiegender Fehler, log-Funktion gibt ihn als die-Meldung aus (nur Konvertierung), macht bei fertigen Modulen (und damit im JS) keinen Sinn
// Message wird nur in nicht-release-Versionen auf Clientkonsole ausgegeben

var CLIENTINFO = 1;
var CLIENTERROR = 2;
var CLIENTWARN = 3;
var DEBUGINFO = 4;
var VERBOSEINFO = 5;
var CLIENTONLY = 6;
var FATALERROR = 7;

function logMessage(lvl, msg) {
  switch(lvl) {
      case 1: {
          if (isRelease == 0) { console.log("CLIENTINFO: " + msg); }
          if (typeof(intersiteobj) == "object") {
            if (intersiteobj.configuration.CF_USAGE == "1") {
                var timestamp = +new Date();
                var cm = "CLIENTINFO: " + "CID:" + signature_CID + ", user:" + intersiteobj.login.username + ", timestamp:" + timestamp + ", message: " + msg + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
                sendeFeedback( { statistics: cm },true );
            } else {
                var timestamp = +new Date();
                var cm = "CLIENTINFO: " + "CID:" + signature_CID + ", user: ??? (kein intersiteobj), timestamp:" + timestamp + ", message: " + msg + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
                sendeFeedback( { statistics: cm },true );
            }
          }
          break;
      }

      case 2: {
          if (isRelease == 0) { console.log("CLIENTERROR: " + msg); }
          if (typeof(intersiteobj) == "object") {
              var timestamp = +new Date();
              var cm = "CLIENTERROR: " + "CID:" + signature_CID + ", user:" + intersiteobj.login.username + ", timestamp:" + timestamp + ", message: " + msg + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
              sendeFeedback( { statistics: cm },true );
            }
          break;
      }
      
      case 3: {
          if (isRelease == 0) { console.log("CLIENTWARN: " + msg); }
          if (typeof(intersiteobj) == "object") {
            if (intersiteobj.configuration.CF_USAGE == "1") {
                var timestamp = +new Date();
                var cm = "CLIENTWARN: " + "CID:" + signature_CID + ", user:" + intersiteobj.login.username + ", timestamp:" + timestamp + ", message: " + msg + ", browsertype:" + navigator.appName + ", browserid:" + navigator.userAgent;
                sendeFeedback( { statistics: cm },true );
            }
          }
          break;
      }

      case 4: {
          if (isRelease == 0) { console.log("DEBUGINFO: " + msg); }
          break;
      }
      
      case 5: {
          if ((isRelease == 0) && (isVerbose == 1)) { console.log("VERBOSEINFO: " + msg); }
          break;
        }

      case 6: {
          console.log(msg);
          break;
      }

      case 7: {
	  // Sollte JS-seitig niemals eintreten aber trotzdem ausgeben
          console.log("FATAL: " + msg);
          break;
      }

      default: {
          if (isRelease == 0) { console.log("UNKNOWNMESSAGE: " + msg); }
          break;
      }
    
  }
}

