/*
 * Funktionen zur Webservice-Verwaltung
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
// encoding: utf8


// --------------------------- Callbacks fuer die Buttons in der HTML-Seite ------------------------------------------------


function internal_feedback(id,bid,typetext) {
  logMessage(VERBOSEINFO, "Feedbackbutton geklickt fuer: " + typetext + ", id=" + id);
  
  if (intersiteobj.login.username == "") {
      alert("Sie sind nicht angemeldet und damit nicht identifizierbar, bitte melden Sie sich auf der Einstellungsseite an!");
      return;
  }
//   
//   if (intersiteobj.login.username == "") {
//       message("Es ist kein Feedbackserver im Modul eingetragen, daher kann kein Feedback eingeschickt werden");
//       return;
//   }
  
  var e = document.getElementById(bid);
  e.style.background = "#FFD2D0";
  
  var timestamp = +new Date();
  var cm = prompt("Meldung zu " + typetext + " versenden (Einsender: " + intersiteobj.login.username + "): ");
  if (cm != null) {
      cm = "INTERNFEEDBACK: " + "user:" + intersiteobj.login.username + ", timestamp:" + timestamp + ", element:" + typetext + ", feedback:" + cm;
      logMessage(VERBOSEINFO, "sending: " + JSON.stringify(cm));
      sendeFeedback( { feedback: cm } ,true);
  } else {
      logMessage(VERBOSEINFO, "User canceled send");
  }
}


function feedback_button(feedbacktype,id,bid,typetext) {
  logMessage(VERBOSEINFO, "Feedbackbutton: " + feedbacktype + ", id=" + id);
  var e = document.getElementById(bid);
  e.style.background = "#F0D0D0";
  
  var cm = prompt("Feedback zu " + typetext + ":", "");

  var timestamp = +new Date();
  request = { creationtime: timestamp, cid: signature_CID, type: feedbacktype, comment: cm, qid: id, sendid: sendcounter, status: 0 };  
  // status =0: Nicht geschickt, =1 ist abgeschickt, =2 abgeschickt und positiver reply vom Server [nur dann ist reply-Attribut vorhanden], =3 abgeschickt und error oder timeout
  sendcounter++;
  sendFeedbackToServer(request);
}

function export_button(id, doctype) {
  logMessage(VERBOSEINFO, "ExportButton id= " + id + " geclickt mit doctype=" + doctype);
  if (doctype == 2) {
     alert("Export im Word-Format ist noch nicht implementiert");
     return;
   }
   
   if (doctype == 1) {
     var fname = docName + "export" + id + ".tex";
     window.open (fname,"_self",false);
  }
}
