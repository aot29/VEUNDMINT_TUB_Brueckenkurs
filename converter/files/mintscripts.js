// Daniel Haase 2011 (MINT-Kolleg BW/VEMA/VEMINT)
// encoding: latin1

function notationParser_IN(s) {

    // Von der Koordinierungsgruppe beschlossene OMB+ Notation
    s = s.replace(/\,/g,".");
    s = s.replace(/\;/g,",");

    // Am Ende haengende Verketter ^ und _ nicht an Parser weitergeben
    if (s.lastIndexOf("^") == (s.length-1)) s = s.slice(0,s.length-1);
    if (s.lastIndexOf("_") == (s.length-1)) s = s.slice(0,s.length-1);
    
    // Ueber HTML-CopyPaste erhaltene Tags ersetzen
    s.replace(/&nbsp;/g," ");
    s.replace(/\t/g," ");
    
    return s;
    
}

function notationParser_OUT(s) {
    
    s = s.replace(/\,/g,";");
    s = s.replace(/\\right\./g,"\\right\\DOTESCAPE"); // Quick&Dirty-workaround fuer Dezimalpunktreplacement
    s = s.replace(/\./g,",");
    s = s.replace(/\\right\\DOTESCAPE/g,"\\right\."); // Quick&Dirty-workaround fuer Dezimalpunktreplacement

    return s;
}

function mygcd(a, b) {
  if (!b) { return a; }
  return mygcd(b, a % b);
}


// Erzeugt das zu einem interaktiven Fragefeld gehoerende JS-Objekt
// uxid = unique exercise id zur Verwendung mit intersiteobj
// c = Wert der Zaehlers MFieldCounter aus tex-Dokument
// solution = Loesung (Typ der Loesung abhaengig vom Typ der Aufgabe, aber immer string)
// id = alphanumerische id des Aufgaben-Elements (Eindeutig in html-file)
// type = Typnummer der Aufgabe wie in mintmod.tex beschrieben
// option = Optionsstring, ggf. Einzelstrings durch Semikolon getrennt
// points = Erreichbare Punktzahl der Aufgabe
// section = entsprechender counter aus texfile
function CreateQuestionObj(uxid,c,solution,id,type,option,pnts,intest,section) {

  // Durch ttm geschleuste Loesungsformeln entparsen falls ttm < oder > als HTML-Code codiert hat
  
  solution = solution.replace(/\&\#62\;/g,">");
  solution = solution.replace(/\&lt\;/g,"<");

  ob = Object.create(null);
  ob.counter = c;
  ob.id = id;
  
  if (type == 2) {
    ob.imgid = option;
  } else {
    ob.imgid = "QM" + ob.id;
  }
  
  
  if ((type == 6) || (type == 7)) {
    // Intervalle und Spezialaufgaben haben Loesungscode fuer linke und rechte Grenze, und Semikolons werden durch Kommata ersetzt.
    ob.solution = solution.replace(/\;/gi,",");
    try {
      // regexp umsetzung von Intervallausdruck in die beiden Grenzen muss noch erledigt werden
      // sowie check in check_group und der init
      ob.solcodea = mathJS.compile("0");
      ob.solcodeb = mathJS.compile("0");
    } catch(e) {
      logMessage(CLIENTERROR, "Solution of type " + type + " not compileable: " + solution);
      ob.solcodea = mathJS.compile("0");
      ob.solcodeb = mathJS.compile("0");
    }
      
  } else {
    ob.solution = solution;
    try {
      if ((type != 1) && (type != 3) && (type != 6) && (type != 7)) {
          var rt = mparser.convertMathInput(solution);
          ob.solcode = mathJS.compile(rt.mathjs);
    } else {
        ob.solcode = mathJS.compile("0");
        // workaround fuer mehrelementige oder Intervallartige Loesungen bei MParsedQuestion oder MSpecialQuestion sowie Textloesungen fuer MQuestion
    }
      logMessage(VERBOSEINFO, "Successfully compiled " + solution);
    } catch(e) {
    logMessage(CLIENTERROR, "Solution of type " + type + " not compileable: " + solution + ", exception = " + JSON.stringify(e));
    ob.solcode = mathJS.compile("0");
    }
  }
  ob.valcode = mathJS.compile("0");
  ob.valvalid = false;
  ob.type = type;
  ob.option = option;
  ob.maxpoints = pnts;
  ob.points = 0; // wird nur von notifyPoints gefuellt !
  ob.message = "";
  ob.element = null;
  ob.intest = (intest>=1);
  ob.section = section;
  ob.uxid = uxid;
  ob.value = 0; // nur von typ 2 genutzt
  
  // Diese Elemente werden von handlerChange nach Eingabe des Benutzers gefuellt
  ob.rawinput = "";
  ob.texinput = "";
  ob.parsedinput = "";
 
  // Dynamische prepare-Funktion unabhaengig vom Fragefeldtyp einbauen
  // Funktion bekommt das dem Feld zugewiesene DOM-Element als Parameter, clear xoder externes setting wird danach separat ausgeführt in InitResults
  ob.prepare = function() { this.element = document.getElementById(this.id); if (this.type == 2) { this.image = document.getElementById(this.option); } };

    // Dynamische clear-Funktion abhaengig vom Fragefeldtyp einbauen
  if ((type == 1) | (type == 3) | (type == 4) | (type == 5) | (type == 6) | (type == 7)) {
      ob.rawloadvalue = function(val) { // Nur Benutzung in clear
            document.getElementById(this.id).value = val; // Stringbasierte Felder
            this.rawinput = val;
            check_group(this.counter,this.counter);
      };
      ob.clear = function() {
            this.texinput = "\\text{(Keine Eingabe)}";
            this.parsedinput = "0";
            this.valcode = mathJS.compile("0");
            this.valvalid = false;
            this.rawloadvalue("");
      };
  } else
  {
    if (type == 2) {
      // Uebersetzen der values fuer die Loesung: tex: 0 und 1, js: 0 = noch nicht geclickt, 1 = angewaehlt, 2 = abgewaehlt
      if (ob.solution == "0") ob.solution = "2"; else ob.solution = "1";
      ob.clear = function() { this.element.checked = false; this.value = "0"; this.message = ""; this.image.src = "../../images/questionmark.gif"; notifyPoints(this.counter, 0, SOLUTION_NEUTRAL); };
      ob.rawloadvalue = function(val) { this.element.checked = (val=="1"); this.value = val; this.message = "";  this.image.src = "../../images/questionmark.gif"; }
    } else {
      // UNBEKANNTER TYP
    }
  }

  var integrationsSchritte = 100;
  // convert-Funktion je nach Typ setzen
  if ((type == 1) | (type == 3) | (type == 4) | (type == 5) | (type == 7)) {
    // Diese Feldtypen rendern und parsen ihre Eingabe ganz normal
    ob.convertinput = function() { return mparser.convertMathInput(notationParser_IN(this.rawinput), integrationsSchritte ); }
  } else {
    if (type == 6) {
      // Bei Intervallfragefeldern das Parsing auf die Intervallgrenzen anwenden
      ob.convertinput = function() { return mparser.convertMathInput(notationParser_IN(this.rawinput), integrationsSchritte ); }
    }
  }
  
  FVAR.push(ob);
  // if ((FVAR.length-1) != c) { alert("Objekt Nr. " + (FVAR.length-1) + " in Array hat Counter " +c); } 
}



// Blendet Hinweis-Bereiche ein und aus
function toggle_hint(div_id) {
    var e = document.getElementById(div_id);
    
/*
    if (e.style.visibility == 'hidden') {
      e.style.visibility = 'visible';
    } else {
      e.style.visibility = 'hidden';
    }
*/
    if (e.style.display == 'none') {
      e.style.display = 'block';
    } else {
      e.style.display = 'none';
    }
}

// Ueberprueft, ob eine Benutzereingabe einem Vereinfachungsmuster entspricht, Typen wie in mintmod.tex bei MSimplifyQuestion
// 0 = Keine Vereinfachung gefordert, nur normale Syntaxchecks werden gemacht
// 1 = Keine Klammern (runde oder eckige) mehr im vereinfachten Ausdruck
// 2 = Faktordarstellung (Term hat Produkte als letzte Operation, Summen als vorgeschaltete Operation)
// 3 = Summendarstellung (Term hat Summen als letzte Operation, Produkte als vorgeschaltete Operation)
// Werte 0...15 sind Typen, Flags 16,32,64,128,256,512 sind optional
// 16 = Nur ein slash (Bruchstrich) im Ausdruck gestattet
// 32 = Stammfunktion gefragt, input wird nur modulo Konstanten bewertet (indem die zu f(0)=0 normiert wird)
// 64 = Keine Wurzelfunktion erlaubt (muss als x^(1/2) geschrieben werden)
// 128 = Keine Betragsfunktion erlaubt (muss als Fallunterscheidung geschrieben werden)
// 256 = Keine Brüche und keine Potenzen erlaubt (also kein / und kein ^ mit dem man ein ^(-1) schummeln könnte)
// 512 = Besondere Stuetzstellen (nur >1 und nur schwach rational, sonst symmetrisch um Nullpunkt und ganze Zahlen)
// 1024 = Nur String aus Ziffern 0,..,9 in Loesung erlaubt
// 2048 = Nur hoechstens ein ^ und kein / und * erlaubt
// Rueckgabe: Array aus string-int-Paaren, jeweils Meldung und ob die Loesung gemaess den Vereinfachungsregeln erlaubt ist (0) oder nicht (1)
function checkSimplification(type, input) {
  var ret = new Array();

  // Allgemeine Pruefungen

  if (input.indexOf("|") != -1) {
      ret.push(new Array("abs(...) statt |...|" , 1));
  }

  if (input.indexOf("e^") != -1) {
      ret.push(new Array("exp(TERM) statt e^TERM" , 1));
  }
  
  if (input.indexOf("\\") != -1) {
      ret.push(new Array("Backslash-Notation verwendet" , 0));
  }
  
  if (input.indexOf(")(") != -1) {
      ret.push(new Array("(...)*(...) statt (...)(...)" , 1));
  }

  var rx = /(\d+)([a-zA-Z(]+)/;
  var res = rx.exec(input);
  if (res != null) {
    if (res.length >= 3) {
        ret.push(new Array("Produkte in Form " + res[1] + "*" + res[2] + " statt " + res[1] + res[2], 1));
    }
  }
  
  
  if ((type & 15) == 1) {
    // Alle Klammern durch runde Klammern ersetzen
    var rex = new RegExp('\\[','gi');
    input = input.replace(rex,"(");
    rex = new RegExp('\\]','gi');
    input = input.replace(rex,")");
    if ((input.indexOf("(") != -1) || (input.indexOf(")") != -1)) {
      ret.push(new Array("L&#246;sung ist nicht vereinfacht" , 1));
    }
  }
  
  if ((type & 15) == 3) {
    // Höchste Operation muss Addition/Subtraktion sein, Addition/Subtraktion darf auf tieferen Ebenen nicht vorkommen
    // Alle Klammern durch runde Klammern ersetzen
    var rex = new RegExp('\\[','gi');
    input = input.replace(rex,"(");
    rex = new RegExp('\\]','gi');
    input = input.replace(rex,")");
  }
    

  if ((type & 16) == 16) {
    // Nur ein Bruchstrich erlaubt
    if (input.indexOf("/") != -1) {
      if (input.indexOf("/") != input.lastIndexOf("/")) {
	ret.push(new Array("Bruch ist nicht zusammengefasst" , 1));
      }
    }
  }

  if ((type & 64) == 64) {
    // Keine Wurzelfunktion erlaubt
    if (input.indexOf("sqrt") != -1) {
      ret.push(new Array("Wurzeln sollen als Exponenten geschrieben werden" , 1));
    }
  }
  
  if ((type & 128) == 128) {
    // Keine Betragsfunktion erlaubt
    if ((input.indexOf("abs") != -1) | (input.indexOf("|") != -1)) {
      ret.push(new Array("Betragsstriche sollen durch eine Fallunterscheidung geschrieben werden" , 1));
    }
  }
  
  if ((type & 256) == 256) {
    // Keine Brüche und keine Potenzen erlaubt
    if ((input.indexOf("^") != -1) | (input.indexOf("/") != -1)) {
      ret.push(new Array("L&#246;sung darf keine Nenner oder Potenzen enthalten" , 1));
    }
  }

  if ((type & 1024) == 1024) {
    // Nur natuerliche Zahl in Rohform erlaubt
    var t = input.trim();
    if (isProperNumber(t) == false) {
      ret.push(new Array("L&#246;sung soll eine Zahl sein" , 1));
    }
  }
  
  if ((type & 2048) == 2048) {
    // Nur hoechstens ein ^ und kein / und * erlaubt
    if (input.indexOf("^") != -1) {
      if (input.indexOf("^") != input.lastIndexOf("^")) {
        ret.push(new Array("Potenzen sollen zusammengefasst werden" , 1));
      }
    } else {
      if ((input.indexOf("/") != -1) || (input.indexOf("*") != -1)) {
        ret.push(new Array("Nenner und Faktoren sollen aufgel&#246;st werden" , 1));
      }
    }
    
  }

  
  return ret;
}

function isProperNumber(s) {
  if (s.indexOf("x") != -1) return false; // schließt Hexadezimalzahlen aus    
  if (s.indexOf("b") != -1) return false; // schließt Binaerzahlen aus    
  if (s.indexOf("o") != -1) return false; // schließt Oktalzahlen aus    
    
  return $.isNumeric(s);
}

// Wird von einem input-Element aufgerufen, wenn der Fokus erhalten geht, passiert auch wenn Gruppe aktiv ist, da diese nur content-Checking betrifft
function handlerFocus(id) {
    if (FVAR[id].id != activefieldid) handlerChange(id,1);
}

// Wird von einem input-Element aufgerufen, wenn der Fokus verloren geht, passiert auch wenn Gruppe aktiv ist, da diese nur content-Checking betrifft
function handlerBlur(id) {
    if (FVAR[id].id == activefieldid) closeInputContent();
}

// Wird aufgerufen, wenn ein change-Event eines Eingabefelds eingetreten ist
// id = Index in Felderarray
// nocontentcheck == 1 -> Feld soll jetzt nicht kontrolliert werden (Feld gehoert z.B. zu Aufgabengruppe)
function handlerChange(id, nocontentcheck) {
  var formula = 0; // Stellt der Feldinhalt eine Formel dar?
  if (FVAR[id].type == 4) formula = 1; // Eingabefeld fuer mathematische Ausdruecke? Rohe Zahlen oder Intervalle werden nicht gehintet
  if (formula == 1) {
    var e = document.getElementById(FVAR[id].id);
    FVAR[id].rawinput = e.value;
    FVAR[id].texinput = "";
    if (e.value != "") {
      try {
	// Eingabe konnte geparset werden
	var ob = FVAR[id].convertinput();
	FVAR[id].texinput = notationParser_OUT(ob.latex);
	FVAR[id].parsedinput = ob.mathjs;
	FVAR[id].valcode = mathJS.compile(ob.mathjs);
	FVAR[id].valvalid = true;
      } catch(e) {
	// Eingabe konnte nicht geparset werden
	if (FVAR[id].texinput == "") FVAR[id].texinput = "\\text{(Fehlerhafte Eingabe)}";
	FVAR[id].parsedinput = "0";
	FVAR[id].valcode = mathJS.compile("0");
	FVAR[id].valvalid = false;
      }
    } else {
      // Eingabe war leer
      FVAR[id].texinput = "\\text{(Keine Eingabe)}";
      FVAR[id].parsedinput = "0";
      FVAR[id].valcode = mathJS.compile("0");
      FVAR[id].valvalid = false;
    }
  }

  if (nocontentcheck != 1) {
      check_group(id, id); // Erzeugt ggf. Meldungen, die zusaetzlich zur Formel angezeigt werden
      
      if (FVAR[id].points == FVAR[id].maxpoints) {
        if (intersiteactive == true) {
            if (intersiteobj.configuration.CF_TESTS == "1") {
            var st = "";
            var timestamp = +new Date();
            st = "EXSUCCESS: " + "CID:" + signature_CID + ", user:" + intersiteobj.login.username + ", timestamp:" + timestamp + ", pagename:" + fullName + ", uxid:" + FVAR[id].uxid + ", elementid:" + id + ", input:" + FVAR[id].rawinput + ", message:" + FVAR[id].message;
            sendeFeedback( { statistics: st }, true);
            }
        }
      }
  }
 
  if (formula == 1) {
    var s = FVAR[id].texinput;
    displayInputContent(id,s);
    var u = document.getElementById("UFIDM" + activefieldid);
    if (u != null) {
      u.innerHTML = FVAR[id].message;
      u.style.background = e.style.background;
    } else {
      logMessage(VERBOSEINFO, "UFIDM not available"); // passiert z.B. bei geschlossenen Tests staendig da Messagepart dann nicht angezeigt ist
    }
  } else closeInputContent();

		  
}

// Callback fuer die Fragegruppen-Buttons
function group_button(input_from, input_to) {
  check_group(input_from, input_to);
}


function check_all() {
  // FVAR[0] ist dummy
  if (FVAR.length > 1) check_group(1,FVAR.length-1);
}

// Hilfsfunktion, die convertMathInput fuer den Fall kapselt, dass nur eine einfache Uebersetzung und keine Fehlerverarbeitung
// und keine LaTeX-Darstellung noetig ist (als Ersatz fuer pureParse aus parser.js).
// Der Ausdruck muss zu einer festen Zahl auswertbar sein (Konstrukte erlauben?)
// Eingabe: Eingabestring des Benutzers, Ausgabe: double (fester Zahlenwert)
// Bei Fehlern und Exceptions wird NaN geliefert
function rawParse(eingabe) {
   try {
     var retobj = mparser.convertMathInput(eingabe,2);
     var mjs = retobj.mathjs;
         var z = mparser.evalMathJS(mjs);
	 return z;
   } catch(e) {
     return NaN;
   }
}

// Uebernimmt die Inhalte der DOM-Elemente von Question-Feldern und faerbt sie entsprechend ein (auch Checkboxen!)
function check_group(input_from, input_to) {

    var d = document;
    var i;
    var s;

  
    if (isTest == true) {
      // Bei Tests bilden alle vorhandenen Fragefelder eine Gruppe
      nPoints = 0;
      nMaxPoints = 0;
    }
    
    for (i=input_from; i<=input_to; i++) {
            s = FVAR[i].id;
            var e = d.getElementById(s);

            switch(FVAR[i].type) {
              
              case 1: {
                // Eingabefeld mit alphanumerischer Loesung, case-sensitive
                var v = e.value;
               var sol = FVAR[i].solution;

               var rex = new RegExp('&#196;','gi');
               sol = sol.replace(rex,'Ä');
               rex = new RegExp('&#214;','gi');
               sol = sol.replace(rex,'Ö');
               rex = new RegExp('&#220;','gi');
               sol = sol.replace(rex,'Ü');
               rex = new RegExp('&#228;','gi');
               sol = sol.replace(rex,'ä');
               rex = new RegExp('&#246;','gi');
               sol = sol.replace(rex,'ö');
               rex = new RegExp('&#252;','gi');
               sol = sol.replace(rex,'ü');
               rex = new RegExp('&#60;','gi');
               sol = sol.replace(rex,'<');
               rex = new RegExp('&lt;','gi');
               sol = sol.replace(rex,'<');
               rex = new RegExp('&#62;','gi');
               sol = sol.replace(rex,'>');
               rex = new RegExp('&gt;','gi');
               sol = sol.replace(rex,'>');
               rex = new RegExp('&#38;','gi');
               sol = sol.replace(rex,'&');
               rex = new RegExp('&#223;','gi');
               sol = sol.replace(rex,'ß');
               rex = new RegExp('&#166;','gi');
               sol = sol.replace(rex,'|');
               FVAR[i].rawinput = v;
               if (v == sol) {
                  FVAR[i].message = "";
                  notifyPoints(i, FVAR[i].maxpoints, SOLUTION_TRUE);
                } else {
                  if (v == "") {
                    FVAR[i].message = "";
                    notifyPoints(i, 0, SOLUTION_NEUTRAL);
                 } else {
                    FVAR[i].message = "L&#246;sung inkorrekt";
                    notifyPoints(i, 0, SOLUTION_FALSE);
                  }
                }
                break;
              }

              case 2: {
                // Checkbox
                var v;
		// Uebersetzen der checked-values in die eigenen values ("0" = noch nicht angeclickt, "1" = angewaehlt, "2" = abgewaehlt)
                if (e.checked==true) v = "1"; else v = "2";
		FVAR[i].value = v;
                FVAR[i].rawinput = v;
                if (v == FVAR[i].solution) {
                  notifyPoints(i, FVAR[i].maxpoints, SOLUTION_TRUE);
                } else {
                  notifyPoints(i, 0, SOLUTION_FALSE);
                }
		break;
              }
              
              case 3: {
                // Eingabefeld mit reeller Loesung, geparset, exakt bis auf OPTION Stellen hinter dem Komma
                // Leerstring in Vorgabeloesung: Leere Menge ist gefragt (nicht leerer String)
                // Mehrere durch Kommata getrennte Werte in Loesung: Endliche Menge ist als Eingabe gefragt
                // Mehrere durch Semikolon getrennte Werte in Loesung: Endliche Menge ist als Eingabe gefragt [ Nur eingegebene Werte, die Vorgabeloesung ist immer mit Kommata zu schreiben ]

                FVAR[i].rawinput = e.value;
                var stellen = FVAR[i].option;
                var soluta = FVAR[i].solution.split(","); // hat nie Mengenklammern

                // Mehr als eine Musterloesung (die gleich sein können): Mengenklammern werden in Eingabe verlangt, auch wenn es nur eine Loesung ist
                // Nur eine Musterloesung: Keine Mengenklammern in Loesungseingabe erlaubt

                var valuta = {};
                var ok = 1;
                var solleer = 0; // leere Menge gefragt (wird sonst nicht erkannt weil split ein Element (Leerstring) liefert
                if (FVAR[i].solution == "") {
                    solleer = 1;
                    soluta = {}; // die leere Menge als leeres Array moeglicher Werte
                }
                
                if ((soluta.length == 1) && (solleer == 0)) {
                     // Es ist ein Element ohne Angabe von Mengenklammern gefragt
                     valuta = notationParser_IN(e.value).split(",");
                     if (valuta.length != 1) {
                         ok = 0;
                     } else {
                        if ((valuta[0].indexOf("{") != -1) | (valuta[0].indexOf("}") != -1)) ok = 0;
                     }
                } else {
                     // Es ist eine Menge (ggf. leer oder einelementig) gefragt
                     var tr = notationParser_IN(e.value).trim();
                     if ((tr.indexOf("{") != 0) | (tr.indexOf("}") != (tr.length-1))) {
                         // Mengenklammern nicht richtig gesetzt oder nicht vorhanden
                         ok = 0;
                     } else {
                         var st = tr.substr(1,tr.length-2);
                         if (st.trim() == "") {
                             valuta = {};
                             logMessage(VERBOSEINFO, "Benutzer hat leere Menge eingegeben");
                         } else {
                           valuta = st.split(",");
			   if (valuta.length==1) {
			     // Alternativ Semikolon moeglich, aber nur wenn kein Komma gefunden
			     valuta = st.split(";");
			  }
                        }
                     }
                }

                // Pruefe beide Teilmengenrelationen, d.h. doppelte Aufführungen von Elementen gelten als richtig
                for (vj=0; ((vj<valuta.length) & (ok==1)); vj++) {
                   var c = 0;
                   var v = rawParse(valuta[vj]);
                   for (sj=0; ((sj<soluta.length) & (c==0)); sj++) {
                      var s = rawParse(applyMVARValues(soluta[sj]));
                      if (Math.abs(extround(v,stellen)-extround(s,stellen)) <= Math.pow(10,(stellen+2)*(-1))) c = 1;
                   }
                   if (c==0) ok = 0;
                }
                for (sj=0; ((sj<soluta.length) & (ok==1)); sj++) {
                   var c = 0;
                   var s = rawParse(applyMVARValues(soluta[sj]));
                   for (vj=0; ((vj<valuta.length) & (c==0)); vj++) {
                      var v = rawParse(valuta[vj]);
                      if (Math.abs(extround(v,stellen)-extround(s,stellen)) <= Math.pow(10,(stellen+2)*(-1))) c = 1;
                   }
                   if (c==0) ok = 0;
                }
                
                
		if (ok == 1) {
                  FVAR[i].message = "";
                  notifyPoints(i, FVAR[i].maxpoints, SOLUTION_TRUE);
                } else {
                  if (e.value == "") {
                    FVAR[i].message = "";
                    notifyPoints(i, 0, SOLUTION_NEUTRAL);
                  } else {
                    if ((soluta.length == 1) && (solleer == 0)) {
                        FVAR[i].message = "Wert inkorrekt";
                    } else {
                        FVAR[i].message = "L&#246;sungsmenge inkorrekt";
                    }
                    notifyPoints(i, 0, SOLUTION_FALSE);
                  }
                }
                break;
              }
              
              case 4: {
                // Eingabefeld mit Funktionsausdruck als Loesung, geparset, approximierter Vergleich an den Stuetzstellen 1,2,...,Anzahl verschoben um Anzahl/2 nach links
		// Ggf. Vereinfachungsvorschrift (Fall 5)

	        var options = FVAR[i].option.split(";",4);
                var stuetzen = options[0];
                var varia = options[1].split(","); // Mehrere Auswertungsvariablen durch Komma getrennt erkennen
		var stellen = options[2];
                var vereinfachung = options[3]; // Werte 0..15 sind Vereinfachungstyp (0 = keine), Flags 16,32,64,128 sind optional
                
                var k;
                var message = "";
                var ok = true;
 
                // FVAR[i].rawinput und andere müssen hier vor Aufruf (z.B. von handlerChange) gesetzt sein (was gefixt werden muss)

		if (FVAR[i].valvalid == false) {
		  ok = false;
		  message = "Frage noch nicht beantwortet";
		} else {
		
		var c1,c2;
		
		if ((vereinfachung & 32) == 32) {
		  // Nur nach Stammfunktion gefragt, beide Funktionen werden auf f(1.234)=0 normiert, es wird davon ausgegangen, dass es nur eine Variable gibt
		  // und dass die Funktion bei x=1.234 existiert.
		  var scope = mathJSFunctions;
		  scope[varia[0]] = 1.234;
		  c1 = FVAR[i].valcode.eval(scope);
		  c2 = FVAR[i].solcode.eval(scope);
		}


                var first;
         	if ((vereinfachung & 512) == 512) {
		  // Besondere (nur positive und nur schwach rationale) Stuetzstellen gefordert
                  first = 1.1957856840; // sollte nicht aus versehen als Bruch irgendwo auftreten
		} else {
		  // Normale Stuetzstellen (positive und negative, fast symmetrisch, und Null wird getroffen wenn mehr als eine Stelle verlangt)
                  first = 1 - (stuetzen*0.5); // erste Stuetzstelle, Definition macht JavaScript auch klar dass es floats sind
		}

		
		vv = [];
		for (vj=0; vj<varia.length; vj++) vv[vj] = first;
		
                try {

		  // ---------- Starting eval for vv = " + vv + " --------------------");
		  
		  var ok = true;
		  var fini = false;
		  
		  while (fini == false) {
		    // Bei gegebenen Stuetzstellen in vv auswerten
		    var scope = mathJSFunctions;
		    for (vj=0; vj<varia.length; vj++) {
		      scope[varia[vj]] = vv[vj];
		    }
                    s = FVAR[i].solcode.eval(scope);
		    v = FVAR[i].valcode.eval(scope);
                    if ((vereinfachung & 32) == 32) {
                        s = s - c2;
                        v = v - c1;
                    }
                    
		    var pd = "norm(" + s + " - " + v + ")";
                    var ed = rawParse(pd);
                    
		    if (!(Math.abs(extround(ed,stellen)-extround(0,stellen)) <= Math.pow(10,(stellen+2)*(-1)))) {
		      ok = false;
		      fini = true;
		      message = "Eingabe ist noch nicht richtig";
		    }
		    
		    // Gesamtes Stuetzstellenarray inkrementieren
		    var index = 0;
		    var inc = true;
		    while (inc == true) {
		      (vv[index])++;
		      if (vv[index] > stuetzen) {
			vv[index] = first;
			index++;
			if (index == varia.length) {
			  // Ganzes array durchinkrementiert
			  inc = false;
			  fini = true;
			}
		      } else {
			inc = false;
		      }
			
		    }
		    
		    
		  }
		  
    	          if (ok == true) message = "Dies ist eine richtige L&#246;sung";
		  
		  
		} catch(e) {
		  ok = false;
		  message = "Form der Eingabe ist fehlerhaft";
		}
                
                var messages = checkSimplification(vereinfachung, FVAR[i].rawinput);
                
		
		for (k=0; k<messages.length; k++) {
                    // if (message != "") { message = message + "<br />"; }
                    message = message + "<div style='color:#454545'>" + messages[k][0] + "</div>";
                    if (messages[k][1] == 1) ok = false;
                }
                
		} // endif von valvalid-test

		
                FVAR[i].message = message;
		if (ok) {
                  notifyPoints(i, FVAR[i].maxpoints, SOLUTION_TRUE);
                } else {
                  if (e.value == "") {
                    notifyPoints(i, 0, SOLUTION_NEUTRAL);
                  } else {
                    notifyPoints(i, 0, SOLUTION_FALSE);
                  }
                }


		break;
              }

              
         case 6: {
                FVAR[i].rawinput = e.value;
		var b = notationParser_IN(e.value.trim());
                b = b.replace(/;/gi,","); // Kommata und Semikolon in Musterloesung und Eingabe zulassen (Semikolon in Musterloesung wird von CreateQuestionObj verarztet)
                var stellen = FVAR[i].option;
                
		var typl = 0; // 0 = nicht bekannt, 1 = offen, 2 = abgeschlossen, 3 = minus unendlich
		var typr = 0;
		var btypl = 0; 
		var btypr = 0;
		
	        ok = 0;

		if (FVAR[i].solution.indexOf("(") != -1) typl = 1;
		if (FVAR[i].solution.indexOf("[") != -1) typl = 2;
		if (FVAR[i].solution.indexOf("(-infty") != -1) typl = 3;
		if (FVAR[i].solution.indexOf("(infty") != -1) typl = 0;
		if (FVAR[i].solution.indexOf(")") != -1) typr = 1;
		if (FVAR[i].solution.indexOf("]") != -1) typr = 2;
		if (FVAR[i].solution.indexOf("infty)") != -1) typr = 3;
		if (FVAR[i].solution.indexOf("-infty)") != -1) typr = 0;
		  
		if ((typr == 0) || (typl == 0)) {

		  logMessage(CLIENTERROR, "Loesungsintervall " + FVAR[i].solution + " ist fehlerhaft");
		  
		} else {
		  
                  // Alternativen für "infty" erkennen
                  b = b.replace(/infinity/g, 'infty');
                  b = b.replace(/unendlich/g, 'infty');
		  
                  // mit dieser Technik wird noch (-1)*infty als infty interpretiert
                  if (b.indexOf("(") != -1) btypl = 1;
		  if (b.indexOf("[") != -1) btypl = 2;
		  if (b.indexOf("(-infty") != -1) btypl = 3;
                  if (b.indexOf("(infty") != -1) btypl = 0;
		  if (b.indexOf(")") != -1) btypr = 1;
		  if (b.indexOf("]") != -1) btypr = 2;
		  if (b.indexOf("infty)") != -1) btypr = 3;
                  if (b.indexOf("-infty)") != -1) btypr = 0;
		
		  if ((typl == btypl) && (typr == btypr)) {
		    var s = b.split(",");
		    var t = FVAR[i].solution.split(",");
		    if (s.length == 2) {
		      ok = 1;
		      s[0] = s[0].substring(1,s[0].length).trim();
		      s[1] = s[1].substring(0,s[1].length-1).trim();
		      t[0] = t[0].substring(1,t[0].length).trim();
		      t[1] = t[1].substring(0,t[1].length-1).trim();
		      if (typl != 3) {
			var h = rawParse(applyMVARValues(s[0]));
			if ((isNaN(h)) | (Math.abs(extround(h,stellen)-extround(rawParse(applyMVARValues(t[0])),stellen)) > Math.pow(10,(stellen+2)*(-1)))) ok = 0;
		      }
		      if (typr != 3) {
  			var h = rawParse(applyMVARValues(s[1]));
			if ((isNaN(h)) | (Math.abs(extround(h,stellen)-extround(rawParse(applyMVARValues(t[1])),stellen)) > Math.pow(10,(stellen+2)*(-1)))) ok = 0;
		      }
		    }
		  }
		}
		
		
                if (ok == 1) {
		  FVAR[i].message = "Dies ist eine richtige L&#246;sung";
                  notifyPoints(i, FVAR[i].maxpoints, SOLUTION_TRUE);
                } else {
                  if (e.value == "") {
		    FVAR[i].message = "";
                    notifyPoints(i, 0, SOLUTION_NEUTRAL);
                  } else {
		    FVAR[i].message = "Ist nicht das gesuchte Intervall";
                    notifyPoints(i, 0, SOLUTION_FALSE);
                  }
                }

		
		break;
              }

         case 7: {
	        // Spezialisiertes Eingabefeld, Wirkung haengt von Fallindex ab
                FVAR[i].rawinput = e.value;
		var b = notationParser_IN(e.value.trim());
                var ok = 0;		
		

	        var options = FVAR[i].option.split(";",4);
                var stuetzen = options[0];
                var varia = options[1].split(","); // Mehrere Auswertungsvariablen durch Komma getrennt erkennen
		var stellen = options[2];
                var styp = options[3]; // string der Spezialtyp der Aufgabe angibt
                

                var message = "";
		
		switch(styp) {

		  case "onlyempty": {
                    if (b.trim().length == 0) ok = 1;
		    break;
		  }
		  
                  case "vector": {
                    var n = rawParse(b);
                    ok = 1;
                    break;
                  }
		  
		  case "evennat": {
		    var n = rawParse(b);
		    if ((n >= 1) && (Math.floor(n) == n) && (n % 2 == 0)) ok = 1;
		    break;
		  }
		  
		  case "oddnat": {
		    var n = rawParse(b);
		    if ((n >= 1) && (Math.floor(n) == n) && (n % 2 == 1)) ok = 1;
		    break;
		  }
		  
		  case "intervalelement": {
                    // Kommata und Semikolon in Musterloesung zugelassen (Semikolon in Musterloesung wird von CreateQuestionObj verarztet)
                    var typl = 0, typr = 0;
		    var s = FVAR[i].solution;
		    if (s.indexOf("(") != -1) typl = 1;
		    if (s.indexOf("[") != -1) typl = 2;
		    if (s.indexOf("(-infty") != -1) typl = 3;
		    if (s.indexOf("(infty") != -1) typl = 0;
		    if (s.indexOf(")") != -1) typr = 1;
		    if (s.indexOf("]") != -1) typr = 2;
		    if (s.indexOf("infty)") != -1) typr = 3;
		    if (s.indexOf("-infty)") != -1) typr = 0;
                    
		    if ((typr == 0) || (typl == 0)) {
		      logMessage(CLIENTERROR, "Loesungsintervall " + FVAR[i].solution + " ist fehlerhaft (Aufgabe Typ 7)");
		    } else {
		      
     		      var t = s.split(",");
  		      if (t.length == 2) {
			ok = 1;
			var l = rawParse(b);
			if (b.trim() == "") {
			  // Leerstring ist keine richtige Eingabe und fuehrt bei echtem Leerstring zu grauem Feld
			  l = NaN;
			  ok = 0;
			}
		        t[0] = t[0].substring(1,t[0].length).trim();
		        t[1] = t[1].substring(0,t[1].length-1).trim();
       		        var h0 = rawParse(applyMVARValues(t[0]));
       		        var h1 = rawParse(applyMVARValues(t[1]));
                        var sl = l + " "; // Umgehung eines Fehlers wenn l nur Zahl und nicht String ist
		        if ((sl.indexOf(",") != -1) | (sl.indexOf("[") != -1) | (sl.indexOf("]") != -1)) {
                          ok = 0; // Vektor oder Intervall vom Benutzer eingegeben, aber Zahl erwartet. Muss separat abgefangen werden da JavaScript sonst Strings vergleicht
                        } else {
                          if ((typl == 1) && (h0 >= l)) ok = 0;
                          if ((typl == 2) && (h0 > l)) ok = 0;
                          if ((typr == 1) && (h1 <= l)) ok = 0;
                          if ((typr == 2) && (h1 < l)) ok = 0;
                       }
 		      }	
		    }
		    
		    break;
		  }

                  case "exactfraction": {
                    // Bruch muss zur Loesung aequivalent sein, sowie maximal gekuerzt und mit positivem Nenner

                    var options = FVAR[i].option.split(";",4);
                    var stellen = options[0];
                    var s = FVAR[i].solution;
                    var sp = -1.2;
                    var l = 0;
                    if (b.trim() == "") {
                      // Leerstring ist keine richtige Eingabe und fuehrt bei echtem Leerstring zu grauem Feld
                      l = NaN;
                      ok = 0;
                    } else {
                      l = rawParse(b);
                      sp = rawParse(s);
                      ok = 1;
                    }
                    
                    // Richtiger Bruchwert bis auf Abschaetzung?
                    if (Math.abs(extround(l,stellen)-extround(sp,stellen)) <= Math.pow(10,(stellen+2)*(-1))) {
                    } else {
                        ok = 0;
                    }

                    // Bruch maximal gekuerzt, nur Zahlen benutzt und Nenner positiv?
                    if (b.indexOf("/") == -1) {
                        // ist es eine ganze Zahl?
                        var rx = /(-?\d+)/ ;
                        var m;
                        if ((m = rx.exec(b)) != null) {
                            if (m[1] != b) {
                                ok = 0; // ist keine reine ganze Zahl
                            }
                        } else {
                            ok = 0; // ist keine reine ganze Zahl
                        }
                        
                    } else {
                        var fr = b.split("/");
                        if (fr.length != 2) {
                            ok = 0;
                        } else {
                            fr[0] = fr[0].trim();
                            fr[1] = fr[1].trim();

                            var rex = /(-?\d+)/ ;
                            var u;
                            // Test dass nur ganze Zahlen benutzt wurden und Nenner positiv ist
                            if ((u = rex.exec(fr[0])) != null) {
                                if (u[1] == fr[0]) {
                                  if ((u = rex.exec(fr[1])) != null) {
                                    if (u[1] == fr[1]) {
                                        var a = rawParse(fr[0]);
                                        if (a < 0) { a = -a; }
                                        var b = rawParse(fr[1]);
                                        var g = mygcd(a,b);
                                        if ((g != 1) || (b <= 0)) ok = 0;
                                    } else {
                                      ok = 0;
                                    }
                                  } else {
                                    ok = 0;
                                  }
                                } else {
                                    ok = 0;
                                }
                            } else {
                              ok = 0;
                            }
                        }
                    }
                    
                    
                    break;
                  }

                  default: {
		    logMessage(CLIENTERROR, "STYP " + styp + " nicht bekannt (MSpecialQuestion)");
		    ok = 0;
		    break;
		  }
		}
		
                if (ok == 1) {
		  FVAR[i].message = "Dies ist eine richtige L&#246;sung";
                  notifyPoints(i, FVAR[i].maxpoints, SOLUTION_TRUE);
                } else {
                  if (e.value == "") {
		    FVAR[i].message = "";
                    notifyPoints(i, 0, SOLUTION_NEUTRAL);
                  } else {
		    FVAR[i].message = "Ist keine richtige L&#246;sung";
                    notifyPoints(i, 0, SOLUTION_FALSE);
                  }
                }

		
		break;
              }

              
              // default: { alert("Unbekannter Typ: " + FIELD_TYPE[i]); }
            }
    }



    // if (isTest == true) fillUserField();
}

// Funktion zur Syntaxpruefung von CodeEdit-Feldern
function checkCESyntax(editor,applet) {
    var prg = editor.getValue();
    applet.setViewText(prg);
}

//---------------------------------------------------------------- Funktionen zur LMS-Interaktionen in SCORM-Modulen ------------------------------------------------------------

function ScanParentsForApi(win)
{
      var nParentsSearched = 0;
      while ( (win.API_1484_11 == null) && (win.parent != null) && (win.parent != win) && (nParentsSearched <= 500))
      {
            nParentsSearched++;
            win = win.parent;
      }
      return win.API_1484_11;
}

function GetSCORMApi()
{
      var API = null;
      //Search all the parents of the current window if there are any
      if ((window.parent != null) && (window.parent != window))
      {
            API = ScanParentsForApi(window.parent);
      }
      if ((API == null) && (window.top.opener != null))
      {
            API = ScanParentsForApi(window.top.opener);
      }
      
      return API;
}

// Parameter: Die globale ID (als string) des Fragefelds, typischerweise mit \MGenerateID erzeugt
// Rueckgabe: Die personalisierte cms-interaction-id fuer dieses Feld des Lerners. Falls noch nicht vorhanden wird eine erzeugt und mit einer leeren Interaktion belegt.
// VERALTET
function GetInteractionID(gid)
{
  if (objScormApi == null) return -1;

  var N = objScormApi.GetValue("cmi.interactions._count");
  
  var id = -1;
  for (id=0; id<N; id++) {
    var sid = objScormApi.GetValue("cmi.interactions." + id + ".id");
    if (sid == gid) return id;
  }
  
  // Neue Interaktion im LMS generieren und Werte initialisieren
  objScormApi.SetValue("cmi.interactions." + N + ".id",gid);
  objScormApi.SetValue("cmi.interactions." + N + ".type", "long-fill-in");
  objScormApi.SetValue("cmi.interactions." + N + ".description", "Question id " + gid);
  objScormApi.SetValue("cmi.interactions." + N + ".learner_response", "");
  objScormApi.SetValue("cmi.interactions." + N + ".result","neutral");
  
  return N;
}

// Parameter: Die globale uxid (als string) des Fragefelds
function GetResult(uxid)
{
  if (intersiteactive == true) {
    if (intersiteobj.configuration.CF_LOCAL == "1") {
      var j = 0;
      for (j = 0; j < intersiteobj.scores.length; j++) {
	if (intersiteobj.scores[j].uxid == uxid) {
	  return intersiteobj.scores[j].rawinput;
	}
      }
    }
  }
  return null;
}

// Fuellt alle vorhandenen Fragefelder der Seite mit den gespeicherten Antworten aus dem LMS,
// falls empty==true wird alles mit Leerstrings gefuellt auch wenn API da ist, falls keine API da ist oder Benutzer nicht will gibt es immer Leerstrings
function InitResults(empty)
{
  logMessage(DEBUGINFO, "InitResults (empty=" + empty + ", isTest=" + isTest + ") start");
  var f = document.getElementById("TESTEVAL");
  if ((empty==true) & (f != null)) f.innerHTML = "Test ist noch nicht abgeschlossen.";
  if (isTest == true) testFinished = false;

  var i = 0;
  for (i=1; i<FVAR.length; i++) { FVAR[i].prepare(); }
  
  if (intersiteactive == true) {
    if (intersiteobj.configuration.CF_LOCAL == "0") empty = true; // Benutzer will keine StorageNutzung
  }
  
  if ((empty==true) || (intersiteactive!=true)) for (i=1; i<FVAR.length; i++) { FVAR[i].clear(); }
 
  if ((intersiteactive == true) && (empty==false)) {
    logMessage(VERBOSEINFO, "Performing reload");
    var gid = "";
    var v = "";
    for (i=1; i<FVAR.length; i++) {
      var e = document.getElementById(FVAR[i].id);
      v = GetResult(FVAR[i].uxid);
            
      if (v == null)  v = "";
      switch(FVAR[i].type) {
              
	      case 1: {
		// Eingabefeld mit alphanumerischer Loesung, case-sensitive
                e.value = v;
		FVAR[i].rawinput = v;
                check_group(i,i);
                break;
              }

              case 2: {
                // Checkbox, v ist "1" oder "0"
                if ((v == "0") || (v == "")) { e.checked = false; FVAR[i].clear(); }
                if (v == "1") { e.checked = true; check_group(i,i); }
                if (v == "2") { e.checked = false; check_group(i,i); }
                break;
              }
              
              case 3: {
                // Eingabefeld mit reeller Loesung, geparset, exakt bis auf OPTION Stellen hinter dem Komma, Mengen moeglich, Mengen moeglich
                e.value = v;
		FVAR[i].rawinput = v;
                check_group(i,i);
                break;
              }
              
              case 4: {
                // Eingabefeld mit Funktionsausdruck als Loesung, geparset, approximierter Vergleich an den Stuetzstellen 1,2,...,Anzahl
                if (v.trim() != "") {
                    e.value = v;
                    FVAR[i].rawinput = v;
                    try {
                        // Eingabe konnte geparset werden
                        var ob = FVAR[i].convertinput();
                        FVAR[i].texinput = notationParser_OUT(ob.latex);
                        FVAR[i].parsedinput = ob.mathjs;
                        FVAR[i].valcode = mathJS.compile(ob.mathjs); // mathjs oder parser? mathjs ist mit konstrukten?
                        FVAR[i].valvalid = true;
                    } catch(e) {
                        // Eingabe konnte nicht geparset werden
                        if (FVAR[i].texinput == "") FVAR[i].texinput = "\\text{(Fehlerhafte Eingabe)}";
                        FVAR[i].parsedinput = "0";
                        FVAR[i].valcode = mathJS.compile("0");
                        FVAR[i].valvalid = false;
                    }
                } else {
                 FVAR[i].texinput = "\\text{(Keine Eingabe)}";
                 FVAR[i].parsedinput = "0";
                 FVAR[i].valcode = mathJS.compile("0");
                 FVAR[i].valvalid = false;
                }






                check_group(i,i);
                break;
              }
              
	      case 6: {
                // Eingabefeld mit Intervall als Loesung
                e.value = v;
                FVAR[i].rawinput = v;
                check_group(i,i);
                break;
	      }
              
	      case 7: {
                // Spezialisiertes Eingabefeld
                e.value = v;
                FVAR[i].rawinput = v;
                check_group(i,i);
                break;
	      }
      }
    }
    

  } else {
    // Keine geladenen Daten oder empty==true, alle Felder werden geleert
    for (i=1; i<FVAR.length; i++) { FVAR[i].clear(); } // kein check_group weil sonst eingefärbt bzw. checkboxen ausgewertet werden, stringbasierte Felder rufen check selbst bei clear auf
  }

}

// Wird auf Testseiten vom Abschluss-Button aufgerufen
function finish_button(name) {
  check_all();
  var f = document.getElementById("TESTEVAL"); // Element vom Typ textarea
  var nMinPoints = 1;
 var ratio = 100*nPoints/nMaxPoints;
  if (f != null) {
    f.innerHTML = "";
    f.innerHTML += "<strong>" + name + " wurde abgeschlossen:</strong><br />";
    f.innerHTML += "Im Test erreichte Punkte: " + nPoints + "<br />";
    f.innerHTML += "Maximal erreichbare Punkte: " + nMaxPoints + "<br />";
    f.innerHTML += "Der Test wird abgeschickt, wenn mindestens ein Punkt erreicht wurde.<br /><br />";
    if (nPoints < nMinPoints) {
      f.innerHTML += "<strong>Der Test ist noch nicht abgeschickt.</strong><br />";
    } else {
      f.innerHTML += "Test ist eingereicht, kann aber weiter bearbeitet und erneut abgeschickt werden.<br />";
    }
    if (name == "Eingangstest") {
    ratio = Math.round(ratio * 100) / 100;
    f.innerHTML += "Es wurden " + ratio + "% der Punkte erreicht.<br /><br />";
    if (ratio < 50) {
      f.innerHTML += "Empfehlung: Versuchen Sie, zunächst die ersten drei Module des Kurses erfolgreich zu bearbeiten und die Abschlusstests zu l&#246;sen. Bei anhaltenden Schwierigkeiten in der Schulmathematik empfiehlt sich der Besuch eines <a href='../../location.html'>Präsenzangebots</a> anstelle eines Onlinekurses.<br />";
    } else {
        if (ratio < 80) {
          f.innerHTML += "Empfehlung: Bearbeiten Sie die <a href='../../chapters.html'>Module</a> des Kurses in der vorgegebenen Reihenfolge und versuchen Sie anschließend, die Abschlusstests zu l&#246;sen.<br />";
        } else {
          f.innerHTML += "Empfehlung: Bei nur punktuellen Schwierigkeiten genügt es, die Abschlusstests der <a href='../../chapters.html'>Module</a> im Kurs zu l&#246;sen und nur bei Bedarf Stoff in den Modulen nachzuarbeiten.<br />";
        }
       
    }
    }
    
  }
  if (isTest == true) {
      testFinished = true;
      
      if ((intersiteactive==true) && (intersiteobj.configuration.CF_TESTS=="1")) {
          pushISO(false);
          var timestamp = +new Date();
          var cm = "TESTFINISH: " + "CID:" + signature_CID + ", user:" + intersiteobj.login.username + ", timestamp:" + timestamp + ", testname:" + name + ", nPoints:" + nPoints + ", maxPoints:" + nMaxPoints + ", ratio:" + (nPoints/nMaxPoints) + ", nMinPoints:" + nMinPoints;
          sendeFeedback({statistics: cm }, true);
          logMessage(VERBOSEINFO, "Testfinish gesendet");
      }

      if (doScorm == 1) {
        // MatheV4: Gesamtpunktzahl ueber alle ABSCHLUSSTESTS mitteln und Prozentwert an SCORM uebertragen
        
        var mx = 0;
        var mi = 0;
        var av = 0;
        // iterate through questions with test flag outside preparation test
        
        var psres = pipwerks.SCORM.init();
        logMessage(VERBOSEINFO, "SCORM init = " + psres);
        psres = pipwerks.SCORM.get("cmi.learner_id");
        logMessage(VERBOSEINFO, "SCORM learner id = " + psres);
        psres = pipwerks.SCORM.get("cmi.learner_name");
        logMessage(VERBOSEINFO, "SCORM learner name = " + psres);
        psres = pipwerks.SCORM.set("cmi.interactions.0.id","TEST");
        logMessage(VERBOSEINFO, "SCORM set interact_id = " + psres);
        psres = pipwerks.SCORM.set("cmi.interactions.0.learner_response",nPoints);
        logMessage(VERBOSEINFO, "SCORM set interact_lr = " + psres); // false im KIT-ILIAS
        psres = pipwerks.SCORM.set("cmi.interactions.0.result",true);
        logMessage(VERBOSEINFO, "SCORM set interact_res = " + psres); // false im KIT-ILIAS
        psres = pipwerks.SCORM.set("cmi.score.raw",nPoints);
        logMessage(VERBOSEINFO, "SCORM set rawpoints = " + psres);
        psres = pipwerks.SCORM.set("cmi.score.min",nMinPoints);
        logMessage(VERBOSEINFO, "SCORM set minpoints = " + psres);
        psres = pipwerks.SCORM.set("cmi.score.max",nMaxPoints);
        logMessage(VERBOSEINFO, "SCORM set maxpoints = " + psres);
        psres = pipwerks.SCORM.set("cmi.score.scaled",(nPoints/nMaxPoints));
        logMessage(VERBOSEINFO, "SCORM set scaled points = " + psres);

        psres = pipwerks.SCORM.set("cmi.objectives.0.id","Abschlusstests");
        logMessage(VERBOSEINFO, "SCORM set objectives = " + psres);
        psres = pipwerks.SCORM.set("cmi.objectives.0.raw",nPoints);
        logMessage(VERBOSEINFO, "SCORM set obrawpoints = " + psres); // false im KIT-ILIAS
        psres = pipwerks.SCORM.set("cmi.objectives.0.min",nMinPoints);
        logMessage(VERBOSEINFO, "SCORM set obminpoints = " + psres); // false im KIT-ILIAS
        psres = pipwerks.SCORM.set("cmi.objectives.0.max",nMaxPoints);
        logMessage(VERBOSEINFO, "SCORM set obmaxpoints = " + psres); // false im KIT-ILIAS
        psres = pipwerks.SCORM.set("cmi.objectives.0.scaled",(nPoints/nMaxPoints));
        logMessage(VERBOSEINFO, "SCORM set obscaled = " + psres); // false im KIT-ILIAS
        psres = pipwerks.SCORM.set("cmi.objectives.0.completion_status", (nPoints>=nMinPoints) ? ("completed") : ("incomplete") );
        logMessage(VERBOSEINFO, "SCORM set obcompletion " + psres);

        psres = pipwerks.SCORM.set("cmi.scaled_passed_score", nMinPoints/nMaxPoints);
        logMessage(VERBOSEINFO, "SCORM set obscossc " + psres); // false im KIT-ILIAS
        psres = pipwerks.SCORM.set("cmi.score", nPoints/nMaxPoints );
        logMessage(VERBOSEINFO, "SCORM set obscore " + psres); // false im KIT-ILIAS


        psres = pipwerks.SCORM.set("cmi.progress_measure",(nPoints/nMaxPoints));
        logMessage(VERBOSEINFO, "SCORM set progress measure = " + psres);
        psres = pipwerks.SCORM.set("cmi.success_status", (nPoints>=nMinPoints) ? ("passed") : ("failed") );
        logMessage(VERBOSEINFO, "SCORM set obcomp = " + psres);
        psres = pipwerks.SCORM.set("cmi.completion_status", (nPoints>=nMinPoints) ? ("completed") : ("incomplete") );
        logMessage(VERBOSEINFO, "SCORM set completion " + psres);
        psres = pipwerks.SCORM.save();
        logMessage(DEBUGINFO, "SCORM save = " + psres);
        if (psres==true) f.innerHTML += "Die Punktzahl wurde zur statistischen Auswertung übertragen\n";
      }
      
      
  }
}

function reset_button()
{
  logMessage(DEBUGINFO, "reset_button start");
  InitResults(true);
}

function notifyPoints(i, points, correct) {
  FVAR[i].points = points;
  if (isTest == true) {
    nPoints += points;
    nMaxPoints += FVAR[i].maxpoints;
  }
  if (intersiteactive == true) {
      if ((intersiteobj.configuration.CF_LOCAL == "1") && (intersiteobj.configuration.CF_TESTS == "1")) {
          var f = false;
          var j = 0;
          for (j = 0; j<intersiteobj.scores.length; j++) {
              if (intersiteobj.scores[j].uxid == FVAR[i].uxid) {
                  f = true;
                  intersiteobj.scores[j].maxpoints = FVAR[i].maxpoints;
                  intersiteobj.scores[j].points = points;
                  intersiteobj.scores[j].siteuxid = SITE_UXID;
                  intersiteobj.scores[j].section = FVAR[i].section;
                  intersiteobj.scores[j].id = FVAR[i].id;
                  intersiteobj.scores[j].uxid = FVAR[i].uxid;
                  intersiteobj.scores[j].intest = FVAR[i].intest;
                  intersiteobj.scores[j].rawinput = FVAR[i].rawinput;
                  intersiteobj.scores[j].value = FVAR[i].value;
                  logMessage(VERBOSEINFO, "Points for " + SITE_UXID + "->" + FVAR[i].uxid + " modernized");
              }
          }
          if (f == false) {
            var k = intersiteobj.scores.length;
            intersiteobj.scores[k] = { uxid: FVAR[i].uxid };
            intersiteobj.scores[k].maxpoints = FVAR[i].maxpoints;
            intersiteobj.scores[k].points = points;
            intersiteobj.scores[k].siteuxid = SITE_UXID;
            intersiteobj.scores[k].section = FVAR[i].section;
            intersiteobj.scores[k].id = FVAR[i].id;
            intersiteobj.scores[k].intest = FVAR[i].intest;
            intersiteobj.scores[k].value = FVAR[i].value;
            intersiteobj.scores[k].rawinput = FVAR[i].rawinput;
            logMessage(VERBOSEINFO, "Points for " + FVAR[i].uxid + " ADDED at position " + k);
          }
      }
  }
  
  // Feldeigenschaften entsprechend anpassen
  var img = document.getElementById(FVAR[i].imgid);
  if (img == null) {
      logMessage(VERBOSEINFO, "notifyPoints warning: img=0, type = " + FVAR[i].type);
  } else {
    switch(correct) {
        case SOLUTION_TRUE: { img.src = "../../images/right.gif"; break; }
        case SOLUTION_FALSE: { img.src = "../../images/false.gif"; break; }
        case SOLUTION_NEUTRAL: { img.src = "../../images/questionmark.gif"; break; }
    }
  }
  
  if (FVAR[i].type != 2) {
      // Normale Kombination Eingabefeld und Antworticon
      var e = document.getElementById(FVAR[i].id);
      switch(correct) {
          case SOLUTION_TRUE: { e.style.background = QCOLOR_TRUE; break; }
          case SOLUTION_FALSE: { e.style.background = QCOLOR_FALSE; break; }
          case SOLUTION_NEUTRAL: { e.style.background = QCOLOR_NEUTRAL; break; }
      }
  }

 
}


function globalunloadHandler()
{
  pushISO(true); // nur synchrone ajax-calls erlauben, da wir im unload-Handler sind und die callbacks sonst verschwinden bevor Aufruf beantwortet wird
 
  // VERALTET
  if (pipwerks.scormdata.connection.isActive == true)
  {
    logMessage(VERBOSEINFO, "pipwerks.scormdata.connection.isActive == true in globalunloadHandler");
    pipwerks.SCORM.save();
  } else {
    logMessage(VERBOSEINFO, "pipwerks.scormdata.connection.isActive == false in globalunloadHandler");
  }

  
  
  // if (doScorm == 1) pipwerks.SCORM.save();
    
  // Terminate terminiert die Verbindung permanent!
  /*
  if (doScorm == 1) {
    var psres = pipwerks.SCORM.quit();
  }
  */
    
}

function globalloadHandler(pulluserstr)
{
  // Wird aufgerufen, wenn die Seite komplett geladen ist (NACH globalready) ODER durch pull-emit-callback wenn intersiteobj aktualisiert werden muss
  // Fragefelder initialisieren und einfaerben
  logMessage(DEBUGINFO, "globalLoadHandler start, pulluser = " + ((pulluserstr == "") ? ("\"\"") : ("userdata")));
  SetupIntersite(false, pulluserstr); // kann durch nach dem load stattfindende Aufrufe von SetupIntersite ueberschrieben werden, z.B. wenn das intersite-Objekt von einer aufrufenden Seite übergeben wird
  InitResults(false);
  setupBOperations();
  

  /*
  $( "input[mfieldtype='4']" ).qtip({
        content: '...',
	show: {event: 'mouseenter click' }
  });
  alert("p");
  */


  logMessage(DEBUGINFO, "globalLoadHandler finish");
 
}

function globalreadyHandler()
{
  logMessage(DEBUGINFO, "globalreadyHandler start");
  setupJQuery();
  logMessage(DEBUGINFO, "globalreadyHandler finish");
}

// VERALTET
function fillUserField()
{
  logMessage(DEBUGINFO, "fillUserField start");
  if (isTest == true) {
    var e = document.getElementById("UFID");
    if (e != null) {
      if (lName != "") {
	e.value = lName + "\n(ID: " + lID + ")";
      } else {
	e.value = "<Nicht angemeldet>";
      }
      
      if (nPoints > 0) {
	if (nMaxPoints > 0) {
	  e.value += "\nPunkte erreicht: " + nPoints + " von " + nMaxPoints;
	} else {
	  e.value += "\nPunkte erreicht: " + nPoints;
	}
      } else {
	if (nMaxPoints > 0) {
	  e.value += "\nPunkte zu erreichen: " + nMaxPoints;
	}
      }
      e.readOnly = true;
    }
  }
}

// Ermittelt die vertikale Scrollposition des Browsers
function getScrollY() {
    var scrOfY = 0;
 
    if( typeof( window.pageYOffset ) == 'number' ) {
        //Netscape compliant
        scrOfY = window.pageYOffset;
        scrOfX = window.pageXOffset;
    } else if( document.body && ( document.body.scrollLeft || document.body.scrollTop ) ) {
        //DOM compliant
        scrOfY = document.body.scrollTop;
        scrOfX = document.body.scrollLeft;
    } else if( document.documentElement && ( document.documentElement.scrollLeft || document.documentElement.scrollTop ) ) {
        //IE6 standards compliant mode
        scrOfY = document.documentElement.scrollTop;
        scrOfX = document.documentElement.scrollLeft;
    }
    return scrOfY;
}

// Setzt die vertikale Scrollposition des Browsers
// function setScrollY(y) {
//     if( typeof( window.pageYOffset ) == 'number' ) {
//         //Netscape compliant
//         window.pageYOffset(y);
//     } else if( document.body && ( document.body.scrollLeft || document.body.scrollTop ) ) {
//         //DOM compliant
//         document.body.scrollTop(y);
//     } else if( document.documentElement && ( document.documentElement.scrollLeft || document.documentElement.scrollTop ) ) {
//         //IE6 standards compliant mode
//         document.documentElement.scrollTop(y);
//     }
// }
// 

function getGlobalValue(varname) {
  // MVAR-Array wird im Gegensatz zu FIELD von 0 an nummeriert
  var i;
  for (i=0; i<MVAR.length; i++) {
    if (MVAR[i].vname == varname) {
      return MVAR[i].value();
    }
  }
  return 0;
}

function rerollMVar(varname) {
  // MVAR-Array wird im Gegensatz zu FIELD von 0 an nummeriert
  var i;
  for (i=0; i<MVAR.length; i++) {
    if (MVAR[i].vname == varname) {
      MVAR[i].reroll();
      var j = 0;
      for (j=0; j<MVAR[i].deps.length; j++) {
	MVAR[i].deps[j].valueHasMutated();
      }
      check_group(1,FVAR.length-1);
      return MVAR[i].value();
    }
  }

  return 0;
}

// Registriert ein Variablenabhängiges div das MathJax-generierten Mathematikausdrücke anzeigt
// Variablen werden über Observablen repräsentiert, deren Änderung triggert das Update des divs
// Eingabe: Die Formel als LaTeX-String ggf. mit \MVar-Kommandos und das observable-"Objekt"
function registerVariables(texmath,obsobj) {
  var i = 0;
  for (i=0; i<MVAR.length; i++) {
    var s = MVAR[i].vname;
    if (texmath.search("[var_" + s + "]") != -1) {
      MVAR[i].deps.push(obsobj);
    }
  }
}


// --------------------------- Das Eingabefenster fuer Formelfelder -----------------------------------------------

// Stellt in einem separaten Bereich den content des Felds dar.
// Es kann immer nur ein Eingabefeld aktiv sein.


function closeInputContent() {
    viewmodel.ifobs("");
    var u = document.getElementById("UFIDM");
    if (u != null) {
      u.value = "";
    }
    if (activefieldid != "") {
        if (activetooltip == null) {
	  logMessage(DEBUGINFO, "activefieldid ohne tooltip!");
	} else {
	  var api = activetooltip.qtip("api");
	  api.toggle(false);
	  api.destroy();
	  activetooltip = null;
	}
        activefieldid = "";
    }
}

function displayInputContent(id,latex) {
    latex = "\\displaystyle\\large " + latex;
    activefieldid = FVAR[id].id;
    if (activetooltip != null) {
      // Tooltip ist schon da
    } else {
      // Neuer Tooltip wird erzeugt und an das input-Element geklebt, bei Tests keine Kommentare dazu abhaengig vom Status des Tests
      var content = "";
      if ((isTest == false) | (testFinished == true)) {
	content = '<div id="NINPUTFIELD' + activefieldid + '" data-bind="evalmathjax: ifobs"></div><br /><div name="NUSERMESSAGE" id="UFIDM' + activefieldid + '" style="line-height:110%; color:#000000; border: thin solid rgb(0,0,0); padding: 8px; background-color:#CFDFDF; width:250px; font-size:11pt; font-family: "HelveticaNeue-Light", "Helvetica Neue Light", "Helvetica Neue", Helvetica, Arial, "Lucida Grande", Verdana, Arial, Helvetica , sans-serif;"></div>';
      } else {
	content = '<div id="NINPUTFIELD' + activefieldid + '" data-bind="evalmathjax: ifobs"></div><br />(im laufenden Test keine Tipps)';
      }
      activetooltip = $(" input[id=\"" + activefieldid + "\"] ").qtip({ 
	id: 'activetooltip',
	show: {event: 'customShow' },
	hide: {event: 'customHide' },
        content: '...',
/*        events: {
          show: function(event, api) { alert("show"); },
          hide: function(event, api) { alert("hide"); }
        },*/
        style: {
          classes: 'qtip-blue qtip-shadow'
        }
      });
      
      var api = activetooltip.qtip("api");
      api.set('content.title',"Formeleingabe");
      api.set('content.text',content);
      // api.set("position.target",$(" input[id=\"" + activefieldid + "\"] "));
      // api.reposition(null,false);
      api.show();
      // api.reposition(null,false);
    }

    viewmodel.ifobs(latex);
    
    var element = document.getElementById("NINPUTFIELD" + activefieldid);
    
    if (element.childNodes[0]) {
        // Element ist schon da und wir nur upgedated
        // var sy = getScrollY();
        var mathelement = MathJax.Hub.getAllJax(element)[0];
        MathJax.Hub.Queue(["Text",mathelement,latex]);
        // setScrollY(sy);
    } else {
        // Element wird im qtip komplett neu angelegt und getypesettet
        // while(element.childNodes[0]) { element.removeChild( element.childNodes[0] ); }
      
        var s = document.createElement('script');
        s.type = "math/tex; mode=display";
        try {
          s.appendChild(document.createTextNode(latex));
          element.appendChild(s);
        } catch (e) {
          s.text = latex;
          element.appendChild(s);
        }
        MathJax.Hub.Queue(["Typeset",MathJax.Hub,element]);
    }
    
}


function setupJQuery() {
    
    // qtips an die Feedbackbuttons haengen
    $("button[ttip='1']").qtip({ 
           position: { target: 'mouse', adjust: { x: 5, y: 5 } },
           style: { classes: 'qtip-blue qtip-shadow' },
           content: { attr: 'tiptitle' },
           show: { event: "mouseenter" }
    });

}


// --------------------------- Hilfsmethoden der Variablenobjekte ----------------------------------------

// Mindestsatz fuer ein Variablenobject:
// string vname : Name der Variablen, Verwendung im Dokument mit \MVar{vname}, innerhalb der JavaScript-Funktionen mit [var_vname]
// string vtype : Typ der Variablen
// Array deps: fuer die Abhaengigkeiten, enthalt Bare-Namen der Observablen (Matheformeldivs) die diese Variable einsetzen
// Funktion latex()  : gibt LaTeX-String zur Darstellung des Inhalts zurueck
// Funktion value()  : gibt fuer JavaScript-Berechnungen (z.B. den Parser) brauchbaren Datentyp zurueck (z.B. einen echten int) [Rückgabetyp hängt vom Objekt ab!]
// Funktion reroll() : Objekt waehlt zufaellig einen neuen Wert fuer sich und gibt ihn auch zurueck 

function createGlobalInteger(vn,vmi,vma,vs) {
  v = Object.create(null);
  v.vname = vn;
  v.vtype = "int";
  v.min = vmi;
  v.max = vma;
  v.std = vs;
  v.val = vs;
  v.deps = new Array();
  v.reroll = function() { this.val = (this.min + Math.floor(Math.random()*(this.max - this.min + 1))); return this.value(); };
  v.latex = function() { var s = ""; s = this.val; return s; };
  v.value = function() { return this.val; };
  return v;
}

function createGlobalFraction(vn,vmi,vma,vsa,vsb) {
  v = Object.create(null);
  v.vname = vn;
  v.vtype = "frac";
  v.min = vmi;
  v.max = vma;
  v.vala = vsa;
  v.valb = vsb;
  v.normalize = function() {if (this.valb == 0) { this.vala = 0; this.valb = 1; } };
  v.normalize();
  v.deps = new Array();
  v.reroll = function() { this.vala = (this.min + Math.floor(Math.random()*(this.max - this.min + 1))); this.valb = (this.min + Math.floor(Math.random()*(this.max - this.min + 1))); this.normalize(); return [this.vala, this.valb]; };
  v.latex = function() { var s = ""; s = "\\frac{" + this.vala + "}{" + this.valb + "}"; return s; };
  v.value = function() { return "(" + this.vala + "*(1/" + this.valb + ")"; };
  return v;
}

function createGlobalSqrt(vn,vmi,vma,vs) {
  v = Object.create(null);
  v.vname = vn;
  v.vtype = "sqrt";
  v.min = vmi;
  v.max = vma;
  v.std = vs;
  v.val = vs;
  v.deps = new Array();
  v.reroll = function() { this.val = (this.min + Math.floor(Math.random()*(this.max - this.min + 1))); return this.value(); };
  v.latex = function() { var s = ""; s = "\\sqrt{" + this.val + "}"; return s; };
  v.value = function() { return "sqrt(" + this.val + ")"; };
  return v;
}

// Ersetzt alle Ausdruecke der Form [var_XXX] durch die Values aus dem MVAR-Array der aktuellen Seite
function applyMVARValues(s) {
    var k = 0;
    for (k=0; k<MVAR.length; k++) {
      var p = "\\[var_"+MVAR[k].vname+"\\]";
      var f = new RegExp(p,"g");
      s = s.replace(f,MVAR[k].value());
    }
    return s;
}

// Ersetzt alle Ausdruecke der Form [var_XXX] durch die Latex-Strings aus dem MVAR-Array der aktuellen Seite
function applyMVARLatex(s) {
    var k = 0;
    for (k=0; k<MVAR.length; k++) {
      var p = "\\[var_"+MVAR[k].vname+"\\]";
      var f = new RegExp(p,"g");
      s = s.replace(f,MVAR[k].latex());
    }
    return s;
}

// --------------------------------------------- Borkifier ---------------------------------------

function permuteString(str, u) {
  var n = str.length;
  var t = "";
  
  var i;
  for (i = 0; i < n; i++) {
    t += str.charAt((u*i) % n);
  }
 
  return t;
}


function debork(str, l) {
  var n = str.length;  
  u = (((5*n) - (3*l)) % n);
  while (mygcd(u,n) != 1) { u = ((u + 1) % n);}
   
  var i = 0;
  while ( ((i*u) % n) != 1) { i++; }
  
  str = permuteString(str, i);  
  return str.slice(0,l);
} 

// ----------------------------------------------- Roulette-Fragen ------------------------------

// Callbacks fuer roulette getCollection

function rid_success(data) {
    var s = JSON.stringify(data);
    logMessage(VERBOSEINFO,"rid_success: " + s);
}

function rid_error(message, data) {
    logMessage(VERBOSEINFO,"rid_error: " + message + ", data = " + JSON.stringify(data));
}
// Liefert den HTML-Text einer zufaellig ausgewaehlten Aufgabe aus der Collection zur gegebenen id vom exerciseserver
function rouletteExercise(rid) {
  exercises.getCollection(rid, rid_success, rid_error);
}
