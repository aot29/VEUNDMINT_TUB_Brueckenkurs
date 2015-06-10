// Funktionen zur Webservice-Verwaltung
// MINT-Kolleg Baden-Wuerttemberg fuer das VEundMINT-Projekt, Daniel Haase 2014
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
