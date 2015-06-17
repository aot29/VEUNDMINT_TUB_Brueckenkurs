/* 
 * Zusaetzliche Funktionen zum LaTeX- und Matheparsing
 * Max Bruckner 2014-2015
 *
 * Diese Datei ist dafür zuständig einen String ( der z.B. in einem Textfeld
 * eingegeben wurde ) in einen von math.js parsebaren und einen von mathjax
 * renderbaren LaTeX-String umzuwandeln. Dies übernimmt die Funktion
 * convertMathInput()
 *
 * Weiterhin kann ein mathjs-String mit einer Reihe an Werten ausgerechnet werden,
 * dies macht man mit der Funktion evalMathJS().
 *
 * Außer diesen beiden Funktionen sollte von außerhalb keine Funktion verwendet werden.
 *
 * */

//MathJS initialisieren
var mathJS = math;
//Zusaetzliche Funktionen fuer MathJS
var mathJSFunctions = (function( mathjsInstance ) {
	const epsilonAbstand = 0.0001;    //Abstand, bei dem eine Fließkommazahl noch als Ganzzahl behandelt wird

	var functions = {};

	functions.ln = function( x ) {
		return mathjsInstance.log( x );
	};

	/*
	 * Wertet Integrale, Summen und Produkte aus
	 *
	 * typ: "int", "sum" oder "prod"
	 * variable: Name der Stuetzvariable
	 * unten: Untere Grenze
	 * oben: obere Grenze
	 * inhalt: inhalt des Konstrukts
	 * schritte: Anzahl der Rechenschritte ( nur für Integrale relevant )
	 * */
	functions.konstrukt = function( args, mathjsInstance, scope  ) {
		//Argumente holen
		var typ = args[0].toString();
		var variable = args[1].toString();
		var unten = mathjsInstance.eval( args[2].toString(), scope );
		var oben = mathjsInstance.eval( args[3].toString(), scope );
		var inhalt = args[4].toString();
		var schritte = typeof args[5] !== 'undefined' ? mathjsInstance.eval( args[5].toString(), scope ) : 1000;

		var code = mathjsInstance.compile( inhalt );
		var calculate = 
			function( value ) {
				scope['stuetzvariable_'+variable] = value;
				return code.eval( scope );
			};

		var faktor = 1;
		//Für Integrale obere und untere Grenze gegebenenfalls vertauschen
		if( (unten > oben) && ( typ == "int" ) ) {
			var swap = oben;
			oben = unten;
			unten = swap;
			faktor = -1;
		}

		var intervallbreite;    //Schrittgröße beim Berechnen des Konstrukts
		var operation;  //Rechenoperation, die jeweils pro Schritt ausgeführt wird ( operation( total, current, next, intervallbreite ) )
		var wert;       //Anfangswert
		//Definiere Operation und Intervallbreite für jeweiligen Typ
		switch( typ ) {
			case "sum":
				operation = 
					function( total, current, next, intervallbreite ) {
						return mathjsInstance.add(total, current);
					}
				intervallbreite = 1;
				wert = 0;
				schritte = mathjsInstance.add( mathjsInstance.subtract( oben, unten ), 1 );
				break;
			case "prod":
				operation = 
					function( total, current, next, intervallbreite ) {
						return mathjsInstance.multiply( total, current );
					}
				intervallbreite = 1;
				wert = 1;
				schritte = mathjsInstance.add( mathjsInstance.subtract( oben, unten ), 1 );
				break;
			case "int":
				operation = 
				function( total, current, next, intervallbreite ) {
					return mathjsInstance.add( total, mathjsInstance.multiply( mathjsInstance.divide( mathjsInstance.add(current, next), 2 ), intervallbreite ) ); //Mittelsumme
				}
				intervallbreite = mathjsInstance.divide( mathjsInstance.subtract(oben, unten), schritte );
				wert = 0;
				break;
			default:
				return  0;
		}

		//Abbrechen, wenn Intervallbreite 0
		if( intervallbreite == 0 ) {
			return 0;
		}

		//Berechne das Konstrukt
		var current = calculate( unten );
		var next;
		for( var i = 0; i < schritte; i++ ) {
			next = calculate( mathjsInstance.add( unten, mathjsInstance.multiply( mathjsInstance.add(i, 1), intervallbreite ) ) );
			wert = operation( wert, current, next, intervallbreite );
			current = next;
		}
		return mathjsInstance.multiply( faktor, wert );
	};

	/* 
	 * Berechnen der Fakultät.
	 *
	 * Besonderheit hierbei: Weicht der Wert um "epsilonAbstand"
	 * von einer natürlichen Zahl ab, wird diese Gerundet
	 * */
	functions.fakultaet = function( zahl ) {
		if( mathjsInstance.subtract( zahl, mathjsInstance.round( zahl ) ) <= epsilonAbstand ) {
			return mathjsInstance.factorial( mathjsInstance.round(zahl) );
		}

		return mathjsInstance.factorial( zahl );
	};

	/*
	 * Berechnen des Binomialkoeffizienten n über k.
	 *
	 * Wie auch bei der Fakultät wird "epsilonAbstand" berücksichtigt.A
	 *
	 * Es handelt sich hierbei um eine Abwandlung des Algorithmus
	 * auf "https://de.wikipedia.org/wiki/Binomialkoeffizient"
	 * */
	functions.binomial = function( n, k ) {
		//Negative k sind nicht erlaubt
		if( k < 0 ) {
			throw "FEHLER: Negatives k bei Binomialkoeffizient";
		} else if( k > n ) {
			throw "FEHLER: Im Binomialkoeffizient darf k nicht groesser als n sein.";
		}

		//Zahlen zu Ganzzahlen wandeln ( wenn sie um höchstens epsilonAbstand davon abweichen )
		if( mathjsInstance.subtract( n, mathjsInstance.round( n ) ) <= epsilonAbstand ) {
			n = mathjsInstance.round( n );
		}
		if( mathjsInstance.subtract( k, mathjsInstance.round( k ) ) <= epsilonAbstand ) {
			k = mathjsInstance.round( k );
		}

		//Berechnung
		if( mathjsInstance.multiply( 2, k ) > n ) {
			k = mathjsInstance.subtract( n, k ); //k = n-k
		}

		if( k == 0 ) {
			return 1;
		} else {
			var ergebnis = mathjsInstance.add( mathjsInstance.subtract( n, k ), 1 ); //ergebnis = n-k + 1
			for( var i = 2; i <= k; i = mathjsInstance.add( i, 1 ) ) {
				ergebnis = mathjsInstance.divide( mathjsInstance.multiply( ergebnis, mathjsInstance.add( mathjsInstance.subtract( n, k ), i ) ), i ); //ergebnis *= (n - k + i)/i
			}
			return ergebnis;
		}
	};

	//Referenzen auf Funktionen hinzufügen
	functions.arcsin = mathjsInstance.asin;
	functions.arccos = mathjsInstance.acos;
	functions.arctan = mathjsInstance.atan;
	functions.arccot = mathjsInstance.acot;
	functions.arcsinh = mathjsInstance.asinh;
	functions.arccosh = mathjsInstance.acosh;
	functions.arctanh = mathjsInstance.atanh;
	functions.arccoth = mathjsInstance.acoth;
	functions.konstrukt.rawArgs = true;	//Enable custom argument parsing

	/*
	*	An dieser Stelle meinen herzlichsten Dank an Jos de Jong, dafür dass er die tolle 
	*	Bibliothek MathJS geschrieben hat und dass er innerhalb von zwei Wochen
	*	das custom argument parsing in MathJS eingebaut hat, nachdem ich ihm einen
	*	entsprechenden Feature-Request geschrieben hatte. ( Max Bruckner)
	* */

	//Dieses Return-Objekt definiert das öffentliche Interface
	return functions;
})( mathJS ); //hier wird mathJS als mathjsInstance übergeben

//Importieren der Funktionen in den mathJS namespace
mathJS.import( mathJSFunctions );



//-------------------------------------------------------------------------------------------------------------------
/*
 * closure um das mparser-modul zu definieren und Funktionen zu kapseln, die von außen nicht sichtbar sein sollen.
 **/
var mparser = (function() {
	var mparser = {};
	/*
	* Gibt den Key zu einem gegebenen Wert in einem Assoziativen Array zurück.
	* Dies funktioniert nur dann richtig, wenn dieser Wert nur genau einmal vorkommt.
	* */
	function getArrayKey( array, value ) {
		for( var key in array ) {
			if( array[key] == value ) {
				return key;
			}
		}
		return undefined;
	}

	/*
	* Ersetzt von start bis ende im Quellstring durch den Ersetzungsstring.
	* Das ganze funktioniert wie String.prototype.slice, also exklusive dem Zeichen
	* an der Endposition
	* */
	function replaceByPos( input, anfang, ende, replace ) {
		var rumpf = input.slice( 0, anfang );
		var rest = input.slice( ende );
		return rumpf + replace + rest;
	}

	//Escapen von Strings für Regular Expressions:
	function regexEscape( input ) {
		return input.replace( /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&" );
	}

	/*
	 * Wiederholtes Ersetzen einer Regex, bis nichts mehr gematcht wird.
	 * Dies ist notwendig, wenn sich matches überschneiden.
	 *
	 * regex: RegExp-Objekt
	 * ACHTUNG, hiermit kann man leicht eine Endlosschleife produzieren
	 **/
	function replaceAllMatches( input, regex, replaceString ) {
		var lastInput;
		do {
			lastInput = input;
			input = input.replace( regex, replaceString );
		} while( lastInput != input )
		return input;
	}

	/*
	*	Ersetzt jedes Vorkommen eines Wortes in einem String
	*
	*	Ein Trefffer ist nur dann ein Treffer, wenn vor und nach dem Such-
	*	begriff keine Buchstaben oder "\" sind.
	* */
	function replaceWord( input, word, replacement ) {
		var lastChar = " ";
		var letter = RegExp( "[a-zA-Z\\\\]", "" );
		for( var pos = 0; pos < input.length; pos++ ) {
			if( (! letter.test( lastChar ) ) && ( input[pos] == word[0] ) ) {
				var suchPos;
				for( suchPos = 0; (suchPos < word.length) && (word[suchPos] == input[pos+suchPos]); suchPos++ ) {}
				//Gefunden
				if( (suchPos == word.length ) && ( (input.length <= pos + suchPos) || (!letter.test(input[pos+suchPos])) ) ) {
					input = replaceByPos( input, pos, pos + suchPos, replacement );
					pos += replacement.length;
				}
			}

			lastChar = input[pos];
		}

		return input;
	}

	/*
	* Globale Variablen mit Ersetzungen etc
	* -------------------------------------
	* */


	/*
	* Globale Map mit eindeutigen IDs
	* 
	* - Hinzufügen von Objekten im globalMap.add( objekt ), gibt die id als Wert zurück.
	* - Löschen von Objekten mit globalMap.remove( id )
	* - Lesen von Objekten mit globalMap.get( id )
	* - Schreiben von Objekten mit globalMap.set( id, objekt ), wirklich nur diese Methode verwenden
	* */
	var globalMap = {
		lastID: 0,
		add: function( objekt ) {
			var id = this.lastID + 1;
			//Genau dann eine Endlosschleife, wenn die Map 9007199254740992 Einträge hat ( sollte nicht passieren )
			//Diese Schleife sorgt dafür, dass nach einem Überlauf der ID keine IDs doppelt genutzt werden.
			for(; typeof this[id] != "undefined"; id++ ) {  
			}
			if( typeof objekt === "undefined" ) {
				//Ersetze undefined durch null, um leere von nichtexistenten Objekten unterscheiden zu können
				objekt = null;
			}
			this[id] = objekt;
			this.lastID = id;
			return id;
		},
		remove: function( id ) {
			if( typeof this[id] === "undefined" ) {
				throw "FEHLER: globalMap: Es existiert kein Objekt mit der ID " + id + "!" ;
				return false;
			}
			return delete this[id];
		},
		get: function( id ) {
			if( typeof this[id] === "undefined" ) {
				throw "FEHLER: globalMap: Es existiert kein Objekt mit der ID " + id + "!";
			}
			return this[id];
		},
		set: function( id, objekt ) {
				if( typeof this[id] === "undefined" ) {
					throw "FEHLER: globalMap: Es existiert kein Objekt mit der ID " + id + "!";
				}
				if( typeof objekt === "undefined" ) {
					//Ersetze undefined durch null, um leere von nichtexistenten Objekten unterscheiden zu können
					objekt = null;
				}
				this[id] = objekt;
			}
	};

	/*
	*  Fügt eine Fehlermeldung zur Liste der Fehler hinzu
	* */
	function addFehler( fehlerListenID, fehler ) {
		var fehlerListe = globalMap.get( fehlerListenID );
		fehlerListe.push( fehler );
		globalMap.set( fehlerListenID, fehlerListe );
	}

	/*
	*	Zu ersetzende Ausdrücke ( ohne Klammern )
	*
	* Array von Objekten der Form:
	*
	*	{	ausdruck: [ "a", "b" ], 	//Array von Ausdrücken
	*		replace: {
	*			"latex": "LaTeXString",
	*			"mathjs": "Parserstring"
	*			//Hierbei wird "$0" durch den Ausdruck ersetzt
	*		},
	*		word: true	//Soll der Ausdruck nur als Wort ersetzt werden ( keine Buchstaben oder "\" vor/nach dem gefundenen Ausdruck oder aber überall [ wichtige Unterscheidung da manche Ausdrücke Teil von anderen Ausdrücken sind ] )
	*	}
	* */
	var toReplace = [
		{
			ausdruck: [ "alpha", "beta", "gamma", "Gamma", "delta", "Delta", "zeta", "eta", "Theta", "iota", "kappa", "lambda", "Lambda", "nu", "xi", "Xi", "omicron", "pi", "Pi", "sigma", "Sigma", "tau", "upsilon", "Upsilon", "Phi", "chi", "psi", "Psi", "omega", "Omega" ],
			replace: {
				"latex": "\\$0",
				"mathjs": "$0"
			},
			word: true
		},
		{
			ausdruck: [ "Alpha" ],
			replace: {
				"latex": "A",
				"mathjs": "$0"
			},
			word: true
		},
		{
			ausdruck: [ "Beta" ],
			replace: {
				"latex": "B",
				"mathjs": "$0"
			},
			word: true
		},
		{
			ausdruck: [ "Epsilon" ],
			replace: {
				"latex": "E",
				"mathjs": "$0"
			},
			word: true
		},
		{
			ausdruck: [ "Zeta" ],
			replace: {
				"latex": "Z",
				"mathjs": "$0"
			},
			word: true
		},
		{
			ausdruck: [ "Eta" ],
			replace: {
				"latex": "H",
				"mathjs": "$0"
			},
			word: true
		},
		{
			ausdruck: [ "Iota" ],
			replace: {
				"latex": "I",
				"mathjs": "$0"
			},
			word: true
		},
		{
			ausdruck: [ "Kappa" ],
			replace: {
				"latex": "K",
				"mathjs": "$0"
			},
			word: true
		},
		{
			ausdruck: [ "Mu" ],
			replace: {
				"latex": "M",
				"mathjs": "$0"
			},
			word: true
		},
		{
			ausdruck: [ "Nu" ],
			replace: {
				"latex": "N",
				"mathjs": "$0"
			},
			word: true
		},
		{
			ausdruck: [ "Omicron" ],
			replace: {
				"latex": "O",
				"mathjs": "$0"
			},
			word: true
		},
		{
			ausdruck: [ "Rho" ],
			replace: {
				"latex": "P",
				"mathjs": "$0"
			},
			word: true
		},
		{
			ausdruck: [ "Tau" ],
			replace: {
				"latex": "T",
				"mathjs": "$0"
			},
			word: true
		},
		{
			ausdruck: [ "Chi" ],
			replace: {
				"latex": "X",
				"mathjs": "$0"
			},
			word: true
		},
		{
			ausdruck: [ "epsilon", "varepsilon" ],
			replace: {
				"latex": "\\varepsilon",
				"mathjs": "epsilon"
			},
			word: true
		},
		{
			ausdruck: [ "theta", "vartheta" ],
			replace: {
				"latex": "\\vartheta",
				"mathjs": "theta"
			},
			word: true
		},
		{
			ausdruck: [ "µ", "mu" ],
			replace: {
				"latex": "\\mu",
				"mathjs": "mu"
			},
			word: true
		},
		{
			ausdruck: [ "rho", "varrho" ],
			replace: {
				"latex": "\\varrho",
				"mathjs": "rho"
			},
			word: true
		},
		{
			ausdruck: [ "phi", "varphi" ],
			replace: {
				"latex": "\\varphi",
				"mathjs": "phi"
			},
			word: true
		},
		{
			ausdruck: [ "infty", "Infty", "infinity", "Infinity", "unendlich", "Unendlich" ],
			replace: {
				"latex": "\\infty",
				"mathjs": "infty"
			},
			word: true
		},
		{
			ausdruck: [ "prod", "produkt" ],
			replace: {
				"latex": "\\prod",
				"mathjs": "prod"
			},
			word: true
		},
		{
			ausdruck: [ "sum", "summe" ],
			replace: {
				"latex": "\\sum",
				"mathjs": "sum"
			},
			word: true
		},
		{
			ausdruck: [ "int", "integral" ],
			replace: {
				"latex": "\\int",
				"mathjs": "int"
			},
			word: true
		},
		{
			ausdruck: [ "°" ],
			replace: {
				"latex": "^{\\circ}",
				"mathjs": "°"
			},
			word: false
		},
		{
			ausdruck: [ "¹" ],
			replace: {
				"latex": " ^{1}",	//HINWEIS: Das Leerzeichen ist wichtig
				"mathjs": "^1"
			},
			word: false
		},
		{
			ausdruck: [ "²" ],
			replace: {
				"latex": " ^{2}",	//HINWEIS: Das Leerzeichen ist wichtig
				"mathjs": "^2"
			},
			word: false
		},
		{
			ausdruck: [ "³" ],
			replace: {
				"latex": " ^{3}",	//HINWEIS: Das Leerzeichen ist wichtig
				"mathjs": "^3"
			},
			word: false
		},
		{
			ausdruck: [ "*" ],
			replace: {
				"latex": " {\\cdot} ",
				"mathjs": "*"
			},
			word: false
		},
		{
			ausdruck: [ "_", "^" ],	//Wichtig für Klammersetzung
			replace: {
				"latex": " $0",
				"mathjs": "$0"
			},
			word: false
		},
		{
			ausdruck: [ ">=" ],
			replace: {
				"latex": "{\\geq}",
				"mathjs": ">="
			},
			word: false
		},
		{
			ausdruck: [ "<=" ],
			replace: {
				"latex": "{\\leq}",
				"mathjs": "<="
			},
			word: false
		}
	];

	var klammernPaare = {
		"(": ")",
		"{": "}",
		"[": "]",
		"|": "|"   //Nur fuer Ersetzung, nicht fuer Suchen gedacht
	};

	//Folgende Strings werden mit vorangesetztdem 'd' als Differential interpretiert
	var differentiale = [ "x", "y", "z", "t", "u" ];

	//erstelle Character-Klassen für öffnende und schließende Klammern
	var characterClassAuf = "";
	var characterClassZu = "";
	Object.keys( klammernPaare ).forEach(
		function( key ) {
			characterClassAuf += regexEscape( key );
			characterClassZu += regexEscape( klammernPaare[key] );
		}
	);

	//Ausdrücke, die in LaTeX andere Klammern erfordern
	// { 
	//     ausdruck: "zu suchender Ausdruck",
	//     replace: {
	//        0: "Ersetzung für beliebige Anzahl an Argumenten, dies ist ein Speziallfall",
	//        1: "Ersetzung für Ausdruck mit einem Argument",
	//        2: "Ersetzung für Ausdruck mit zwei Argumenten"
	//        //Hierbei wird $1 durch den ersten Wert, $2 durch den zweiten Wert ... ersetzt.
	//        //$0 wird durch den gefundenen Ausdruck ersetzt
	//        },
	//     klammern: "String aller klammern für die die Ersetzung gilt"
	//
	// }
	//
	// Im falle von 0, also einer beliebigen Anzahl von Argumenten sieht das Objekt folgendermaßen aus:
	// 0: {
	// 	anfang: "Anfang des neuen Ausdrucks"
	// 	argument: "Wodurch das Argument ersetzt wird"
	// 	trenner: "Trenner zwischen Argumenten"
	// 	ende: "Ende des neuen Ausdrucks"
	// }
	// Im falle von beliebig vielen Argumenten wird $i durch das entsprechende Argument ersetzt
	var toReplaceKlammern =  [
		{
			//Trigonometrische und andere Funktionen in normaler notation ohne Ersetzung des Wortes
			// ( 1 zu 1 in LaTeX konvertierbar durch voranstellen von "\\")
			ausdruck: [ "sin", "cos", "tan", "cot", "arcsin", "arccos", "arctan", "sinh", "cosh", "tanh", "coth", "exp", "ln" ],
			replace: {
				"latex": {
					1: "\\$0($1)"
				},
				"mathjs": {
					1: "$0($1)"
				}
			}
		},
		{
			ausdruck: [ "log" ],
			replace: {
				"latex": {
					1: "\\log($1)",
					2: "\\log($1,$2)"
				},
				"mathjs": {
					1: "log($1)",
					2: "log($1,$2)"
				}
			}
		},
		{
			ausdruck: [ "asin" ],
			replace: {
				"latex": {
					1: "\\arcsin($1)"
				},
				"mathjs": {
					1: "asin($1)"
				}
			}
		},
		{
			ausdruck: [ "acos" ],
			replace: {
				"latex": {
					1: "\\arccos($1)"
				},
				"mathjs": {
					1: "acos($1)"
				}
			}
		},
		{
			ausdruck: [ "atan" ],
			replace: {
				"latex": {
					1: "\\arctan($1)"
				},
				"mathjs": {
					1: "atan($1)"
				}
			}
		},
		{
			ausdruck: [ "acot", "arccot" ],
			replace: {
				"latex": {
					1: "\\cot^{-1}($1)"
				},
				"mathjs": {
					1: "acot($1)"
				}
			}
		},
		{
			ausdruck: [ "asinh", "arcsinh" ],
			replace: {
				"latex": {
					1: "\\sinh^{-1}($1)"
				},
				"mathjs": {
					1: "asinh($1)"
				}
			}
		},
		{
			ausdruck: [ "acosh", "arccosh" ],
			replace: {
				"latex": {
					1: "\\cosh^{-1}($1)"
				},
				"mathjs": {
					1: "acosh($1)"
				}
			}
		},
		{
			ausdruck: [ "atanh", "arctanh" ],
			replace: {
				"latex": {
					1: "\\tanh^{-1}($1)"
				},
				"mathjs": {
					1: "atanh($1)"
				}
			}
		},
		{
			ausdruck: [ "acoth", "arccoth" ],
			replace: {
				"latex": {
					1: "\\coth^{-1}($1)"
				},
				"mathjs": {
					1: "acoth($1)"
				}
			}
		},
		{ 
			ausdruck: [ "^" ],
			replace: {
				"latex": {
					1: "^{$1}"
				},
				"mathjs": {
					1: "^($1)"
				}
			}
		},
		{ 
			ausdruck: [ "_" ],
			replace: {
				"latex": {
					1: "_{$1}"
				},
				"mathjs": {
					1: "_($1)"
				}
			}
		},
		{ 
			ausdruck: [ "sqrt", "wurzel", "Wurzel" ],
			replace: {
				"latex": { 
					1: "\\sqrt{$1}",
					2: "\\sqrt[$1]{$2}"
				},
				"mathjs": {
					1: "sqrt($1)",
					2: "nthRoot($2,$1)"
				}
			}
		},
		{ 
			ausdruck: [ "sum", "Sum", "summe", "Summe", "\\sum" ],
			replace: {
				"latex": {
					3: "\\sum_{$1}^{$2}($3)"
				},
				"mathjs": {
					3: "sum_($1)^($2)($3)"
				}
			}
		},
		{ 
			ausdruck: [ "int", "Int", "integral", "Integral", "\\int" ],
			replace: {
				"latex": {
					3: "\\int_{$1}^{$2}{$3}"
				},
				"mathjs": {
					3: "int_($1)^($2)($3)"
				}
			}
		},
		{ 
			ausdruck: [ "prod", "Prod", "produkt", "Produkt", "\\prod" ],
			replace: {
				"latex": {
					3: "\\prod_{$1}^{$2}($3)"
				},
				"mathjs": {
					3: "prod_($1)^($2)($3)"
				}
			}
		},
		{
			ausdruck: [ "abs", "betrag", "Betrag" ],
			replace: {
				"latex": {
					1: "\\left|$1\\right|"
				},
				"mathjs": {
					1: "abs($1)"
				}
			}
		},
		{
			ausdruck: [ "factorial", "Factorial", "fakultaet", "Fakultaet", "fakultät", "Fakultät" ],
			replace: {
				"latex": {
					1: "{($1)!}"
				},
				"mathjs": {
					1: "fakultaet($1)"
				}
			}
		},
		{
			ausdruck: [ "binomial", "Binomial", "binomialkoeff", "Binomialkoeff", "binomialkoeffizient", "Binomialkoeffizient" ],
			replace: {
				"latex": {
					2: "{\\binom{$1}{$2}}"
				},
				"mathjs": {
					2: "binomial($1,$2)"
				}
			}
		},
		{
			ausdruck: [ "falls", "Falls", "if", "If" ],
			replace: {
				"latex": {
					3: "{\\left\\lbrace\\begin{matrix}{$2}&{\\mbox{falls}\\;{$1}}\\\\{$3}&\\mbox{sonst}\\end{matrix}\\right.}"
				},
				"mathjs": {
					3: "(($1)?($2):($3))"
				}
			}
		},
		{ //Differentiale
			ausdruck: [ "d" ],
			replace: {
				"latex": {
					1: " {~d{$1}} "	//HINWEIS: Die Leerzeichen sind wichtig
				},
				"mathjs": {
					1: "(d($1))"
				}
			}
		},
		//WICHTIG: Der Eintrag für Vektoren muss immer am Ende stehen,
		//da der leere String immer gematcht wird und die folgenden Einträge nicht mehr
		//berücksichtigt würden!
		{	//Vektoren und Klammern
			ausdruck: [ "" ],
			replace: {
				"latex": {
					0: {
						anfang: "{\\left(\\begin{matrix}",
						argument: "{$i}",
						trenner: "\\\\",
						ende: "\\end{matrix}\\right)}"
					},
					1: "\\left($1\\right)"
				},
				"mathjs": {
					0: {
						anfang: "[",
						argument: "$i",
						trenner: ",",
						ende: "]"
					},
					1: "($1)"
				}
			},
			klammern: "(["
		}
	];

	/*
	*	Ersetzt eingaben anhand des Objektes toReplace
	*
	* 	input: Zu verarbeitender String
	*  mode: welche Art von Ersetzung soll durchgeführt werden ( "latex", "mathjs" )
	* */
	function simpleReplace( input, mode, fehlerListenID ) {
		//Ersetzungen durchgehen
		toReplace.forEach(
			function( element ) {
				//Durchgehen aller "namen" dieses ausdrucks ( z.B. asin, arcsin für den Arkussinus )
				element.ausdruck.forEach(
					function( ausdruck ) {
						var ersetzung = element.replace[mode];
						ersetzung = ersetzung.replace( RegExp( "\\$0", "g" ), ausdruck ); //$0 durch den gefundenen Ausdruck ersetzen
						if( element.word ) { //sollen nur ganze Wörter ersetzt werden ( bei ausdruck = "sin" würde nur "sin" aber nicht z.B. "arcsin" ersetzt werden )
							input = replaceWord( input, ausdruck, ersetzung );
						} else {	//Ersetzung ohne Wortgrenzen
							input = input.replace( RegExp( regexEscape( ausdruck ), "g" ), ersetzung  );
						}
					}
				);
			}
		);
		return input;
	}


	/*
	* Kümmert sich um die rekursive Abarbeitung von Klammerausdrücken
	* Bekommt einen String und liefert einen String mit verarbeiteten Klammerausdrücken
	* zurück.
	*
	* Klammerausdrücke sind hierbei Ausdrücke in Form eines Wortes gefolgt von Klammern
	* mit beliebig vielen, per Komma getrennten, Argumenten.
	*
	* Beispiel:
	* 	gamma+log(alpha,beta)+epsilon
	*   ---------^----- ----^--------
	*    ^       |   ^   ^  |     ^
	*    |  anfang   |   |  ende  |
	*    rumpf       |   |        rest
	*       inhalte[0]   inhalte[1]
	*
	* Die Ersetzung erfolgt anhand des Inhaltes von toReplaceKlammern.
	*
	* Parameter:
	*  input: Zu verarbeitender String
	*  mode: welche Art von Ersetzung soll durchgeführt werden ( "latex", "mathjs" )
	* */
	function bracketReplace( input, mode, fehlerListenID ) {
		//Finde öffnende Klammer
		var rex = RegExp( "[" + characterClassAuf + "]", "" );	//Öffnende Klammern
		var treffer = rex.exec( input );
		if( treffer != null ) {
			var klammerAuf = treffer[0];
			var anfang = treffer.index;	//Position der öffnenden Klammer
			var ende = sucheKlammern( input, anfang );	//schließende Klammer
			if( ende < 0 ) {
				addFehler( fehlerListenID, {
					nutzer: "Fehlende schließende Klammer!",
					debug: "bracketReplace: fehlende schließende Klammer" }
				);
				return input;
			}

			var inhalte = [];	//Array der Argumente innerhalb der Klammern
			//Inhalt der Klammer anhand von Kommata zerlegen
			for( var pos = anfang + 1; (pos > 0) && (pos < ende); pos = nextKomma + 1 ) {
				var nextKomma = findeAufKlammerEbene( input, ",", 0, pos );
				if( (nextKomma == -1 ) || (nextKomma > ende) ) {
					nextKomma = ende;
				}
				inhalte.push( bracketReplace( input.slice( pos, nextKomma ), mode, fehlerListenID ) );
			}

			//Strings vor und nach der Klammer
			var rumpf = input.slice( 0, anfang );
			var rest = input.slice( ende + 1 );

			//String in den der neue Inhalt gescpeichert wird
			var inhalt = "";

			//Durchgehen der Ersetzungen
			var i;
			treffer = null;
			for( i = 0; (i < toReplaceKlammern.length) && (treffer == null); i++ ) {
				// Überspringen wenn Klammern nicht in Liste
				var klammern = toReplaceKlammern[i].klammern;
				if( (typeof klammern == "undefined") || (klammern.search( regexEscape(klammerAuf) ) != -1 ) ) {
					//Durchgehen der zu findenden Ausdrücke
					for( j in toReplaceKlammern[i].ausdruck ) {
						var ausdruck = toReplaceKlammern[i].ausdruck[j];
						//Ausdruck am Ende des Rumpfes suchen
						rex = RegExp( "(^|[^a-zA-Z\\\\])(" + regexEscape( ausdruck ) + ")$", "" );
						treffer = rex.exec( rumpf );
						if( treffer != null ) {
							rumpf = rumpf.replace( rex, "$1" );	//ausdruck aus Rumpf entfernen
							//Existiert eine Ersetzung mit gegebener Kommazahl?
							if( (typeof toReplaceKlammern[i].replace[mode][inhalte.length]) != "undefined" ) {
								inhalt = toReplaceKlammern[i].replace[mode][inhalte.length];
							} else if( (typeof toReplaceKlammern[i].replace[mode][0]) != "undefined" ) {	//Ersetzung für beliebige Zahl von Argumenten?
								var replaceObject = toReplaceKlammern[i].replace[mode][0];

								//Zusammensetzen des Strings
								inhalt = replaceObject.anfang;
								for( var k = 1; k < inhalte.length; k++ ) {
								inhalt += replaceObject.argument.replace( "$i", "$" + k )
								+ replaceObject.trenner;
								}
								inhalt += replaceObject.argument.replace( "$i", "$" + inhalte.length )
								+ replaceObject.ende;

							} else {
								addFehler( fehlerListenID, {
									nutzer: "Fehlerhafte Klammersetzung oder anzahl an Kommata",
									debug: "bracketReplace: es existiert keine Ersetzung für gegebenen Input"
								}
								);
								return input;
							}

							//Ersetze alle $-Ausdrücke im String inhalt
							//"$0" durch ausdruck ersetzen
							rex = RegExp( "\\$0", "g" );
							inhalt = inhalt.replace( rex, ausdruck );
							//Restliche Argumente ersetzen ( $1, $2, ... )
							for( var j = inhalte.length; j > 0; j-- ) {	//von oben nach unten Zählen, damit z.B. $11 vor $1 ersetzt wird
								rex = RegExp( "\\$" + j, "g" );
								inhalt = inhalt.replace( rex, inhalte[j-1] );
							}

							break;	//Schleife stoppen da passender Ausdruck bereits gefunden
						}
					}
				}
			}

			//Wenn kein Treffer, erstelle inhalt aus inhalte, sonst funktioniert {\cdot} beispielsweise nicht!
			if( (i == toReplaceKlammern.length) && (treffer == null)   ) {
				inhalt = klammerAuf + inhalte.join( ',' ) + klammernPaare[klammerAuf];
			}

			return rumpf + inhalt + bracketReplace( rest, mode, fehlerListenID );
		}
		return input;
	}

	/*
	* Diese Funktion sucht das Gegenstück zu einer gegebenen Klammer
	*  Returnwert ist die Position der gefundenen Klammer oder -1 im
	*  Fehlerfall
	**/
	function sucheKlammern( input, klammerPos ) {
		//Klammertypen, können auch umgekehrt sein ( klammerAuf enthält z.B.
		// eine schließende Klammer, wenn nach links gesucht wird )
		var klammerAuf = input[klammerPos];
		var klammerZu = '';
		var delta;  //Richtung ( -1: nach links, +1: nach rechts )
		//bestimme Suchrichtung und setze Klammernpaare
		if( klammernPaare[klammerAuf] != undefined ) { //klammerAuf ist öffnende Klammer
			klammerZu = klammernPaare[klammerAuf];
			delta = 1;  //Nach rechts suchen
		} else if( getArrayKey( klammernPaare, klammerAuf ) ) { //Prüfe, ob klammerAuf schließende Klammer ist
			klammerZu = getArrayKey( klammernPaare, klammerAuf );
			delta = -1; //Nach links suchen
		} else {
			return -1;
		}

		//Jetzt wird endlich nach der eigentlichen Klammer gesucht
		var klammerZuPos;
		var zaehler = 1;
		for( klammerZuPos = klammerPos + delta; (zaehler > 0) && (klammerZuPos >= 0) && (klammerZuPos < input.length); klammerZuPos += delta ) {
			if( input[klammerZuPos] == klammerZu ) {
				zaehler--;
			} else if( input[klammerZuPos] ==  klammerAuf ) {
				zaehler++;
			}
		}
		klammerZuPos -= delta;  //letztes "+= delta" aus Schleife korrigieren

		//passende Klammer gefunden?
		if( zaehler == 0 ) {
			return klammerZuPos;
		} else {
			return -1;
		}
	}

	/*
	*	Diese Funktion sucht in einem String nach einer Zeichenfolge, liefert
	*	aber nur einen Treffer auf der angegebenen Klammerebene ( Klammerebene
	*	0, wenn nichts angegeben, startPos 0 wenn nichts angegeben ). Rückgabewert ist
	*	die Position des Treffers oder -1 wenn nichts gefunden wurde.
	*
	*	HINWEIS: Im suchString werden verschiedene Klammertypen nicht voneinander
	*	unterschieden
	*	TODO: Ebenjene Unterscheidung ermöglichen
	* */
	function findeAufKlammerEbene( input, suchString, klammerEbene, startPos ) {
		//Gegebenenfalls Standardwert setzen
		klammerEbene = (typeof klammerEbene != 'undefined') ? klammerEbene : 0;
		startPos = (typeof startPos != 'undefined') ? startPos : 0;

		//Bei leerem Suchstring abbrechen
		if( suchString.length < 1 ) {
			return -1;
		}

		//Alle Klammern durch runde Klammern ersetzen:
		input = input.replace( RegExp( "[" + characterClassAuf + "]", "g"), "(" );
		input = input.replace( RegExp( "[" + characterClassZu + "]", "g"), ")" );
		suchString = suchString.replace( RegExp( "[" + characterClassAuf + "]", "g"), "(" );
		suchString = suchString.replace( RegExp( "[" + characterClassZu + "]", "g"), ")" );

		var aktuelleEbene = 0;
		var pos;			//Position im Input
		//Suche nach String
		for( pos = startPos; (pos < input.length); pos++ ) {
			if( (aktuelleEbene == klammerEbene) && (input[pos] == suchString[0]) ) {
				var suchPos;
				for( suchPos = 0; (suchPos < suchString.length) && (suchString[suchPos] == input[pos+suchPos]); suchPos++ ) {}
				if( suchPos == suchString.length ) {	//gefunden
					return pos;
				}
			}

			//Klammern zählen
			if( input[pos] == '(' ) {
				aktuelleEbene++;
			} else if( input[pos] == ')' ) {
				aktuelleEbene--;
			}
		}

		return -1;
	}

	/*
	* Tauscht abfolgen von ^(...) _(...) aus durch _(...)^(...).
	*
	* Die Vertauschung erfolgt ausschließlich im Parserstring
	*
	* HINWEIS: Es werden keine Grenzen innerhalb von Grenzen unterstützt
	*  ( sowas wie "int_{int_{a}^{b}}^{c}")
	*                       --------
	*
	* */
	function swapBoundaries( input, fehlerListenID ) {
		//entfernen von Leerzeichen
		input = input.replace( /\s+/g, '' );

		var untereGrenzeStart = findeAufKlammerEbene( input, "_(", 0 ); // Anfang->_(...)
		if( untereGrenzeStart != -1 ) { //Wenn "_(" gefunden
			var untereGrenzeEnde = sucheKlammern( input, untereGrenzeStart + 1 ); //_(...)<-Ende
			if( untereGrenzeEnde < 0 ) {
				addFehler( fehlerListenID, {
					nutzer: "Untere grenze endet nicht",    //TODO: evtl. besseren Namen finden, da untere Grenze nur bei Integralen passt.
					debug: "swapBoundaries: untere Grenze endet nicht" } );
				return input;
			}

			//Strings vor und Nach _(...)
			var anfang = input.slice( 0, untereGrenzeStart );
			var ende = input.slice( untereGrenzeEnde + 1 );

			var untereGrenze = input.slice( untereGrenzeStart + 2, untereGrenzeEnde );

			//Positionsangaben für obere Grenze, diese beziehen sich nicht auf input,
			//  sondern entweder anfang oder ende, je nachdem, wo sich die obere Grenze befindet
			var obereGrenzeStart;
			var obereGrenzeEnde;

			//Suche nach ^(..) hinter _(..)
			var obereGrenzeStart = findeAufKlammerEbene( ende, "^(", 0 );
			if( obereGrenzeStart == 0 ) { // "^(" am Anfang des Strings ende
				obereGrenzeEnde = sucheKlammern( ende, 1 );
				if( obereGrenzeEnde >= 0 ) {
					var obereGrenze = ende.slice( obereGrenzeStart + 2, obereGrenzeEnde );
					var endeRest = ende.slice( obereGrenzeEnde + 1 );   //Restlicher Teil von ende, der nicht zur oberen Grenze gehört
					//Rückgabe des Strings, keine Vertauschung
					return anfang + "_(" + untereGrenze + ")" + "^(" +  obereGrenze + ")" + swapBoundaries( endeRest, fehlerListenID );
				} else {
					addFehler( fehlerListenID, {
						nutzer: "Obere grenze endet nicht",    //TODO: evtl. besseren Namen finden, da obere Grenze nur bei Integralen passt.
						debug: "swapBoundaries: obere Grenze endet nicht" } );
					return input;
				}
			} else {
				//Suche nach ^(...) vor _(...)
				if( anfang[anfang.length - 1] == ')' ) {	//Endet Anfang mit ")"?
					obereGrenzeEnde = anfang.length - 1;
					obereGrenzeStart = sucheKlammern( anfang, obereGrenzeEnde ) - 1;
					if( (obereGrenzeStart >= 0) && (anfang[obereGrenzeStart] == "^")) {
						var obereGrenze = anfang.slice( obereGrenzeStart + 2, obereGrenzeEnde );
						var anfangRumpf = anfang.slice( 0, obereGrenzeStart );
						return anfangRumpf + "_(" 
							+ swapBoundaries( untereGrenze, fehlerListenID )
							+ ")" + "^(" 
							+ swapBoundaries( obereGrenze, fehlerListenID ) 
							+ ")" 
							+ swapBoundaries( ende, fehlerListenID );
					} else {
						addFehler( fehlerListenID, {
							nutzer: "Obere grenze fehlt!",
							debug: "swapBoundaries: obere Grenze existiert nicht." } );
						return input;
					}
				} else {
					addFehler( fehlerListenID, {
						nutzer: "Obere grenze fehlt!",
						debug: "swapBoundaries: obere Grenze existiert nicht." } );
					return input;
				}
			}
		}

		return input;   //Die Ausführung sollte hier eigentlich gar nicht ankommen
	}

	/*
	* Verarbeitet Differentiale, sodass sie die Form (d(x)) annehmen
	* ( sowohl für LaTeX-String als auch Parser-String )
	*  input: Eingabestring
	*  klammerTyp: Öffnende Klammer des Typs, der für das Differential verwendet werden soll
	*              ( hauptsächlich '(' für Parser-String und '{' für LaTeX-String )
	*
	* Differentiale der Form d(...) werden mithilfe von toReplaceKlammern verarbeitet
	* */
	function preprocessDifferentials( input, klammerTyp, fehlerListenID ) {
		var klammerAuf = klammerTyp;
		var klammerZu = klammernPaare[klammerTyp];
		//erstellen der Regex für einfache Differentiale ( dx, dy ... )
		var regexString = "(";      //Ziel: (x|y.....)
		differentiale.forEach( 
			function( differential ) {
				regexString += differential + "|";
			}
		);
		regexString = regexString.slice( 0, -1);      //entferne letztes '|'
		regexString += ')';

		var rex = RegExp( "(^|[^a-zA-Z])d" + regexString + "($|[^a-zA-Z])", 'g' ); 
		input = replaceAllMatches( input, rex, "$1" + klammerAuf + "d" + klammerAuf + "$2" + klammerZu + klammerZu + " $3" );
		return input;
	}

	/*
	* Bestimmt den Inhalt von Integralen und deren Differentiale und formatiert sie:
	*
	*   Parserstring: int_(...)^(...)(...)(d(x))
	*                                ^   ^
	*                           anfang   ende
	*
	*   Rückgabe ist ein Objekt, mit den Elementen "mathjs" und "mathjs".
	*
	* */
	function replaceConstructs( input, integrationsSchritte, fehlerListenID ) {
		var result = {
			mathjs: input,
			mathjs: input
		};
		var rex = new RegExp( "(int|sum|prod)_\\(" );
		var treffer = rex.exec( input );
		if( treffer != null ) {
			var typ = treffer[1];   //Typ ( sum, int, prod )

			//Grenzen ( bzw. wie auch immer das bei nicht-Integralen heißt ) und Inhalt
			var untenStart = treffer.index + typ.length + 1; // "int_" = typ.length + 1
			var obenStart = sucheKlammern( input, untenStart ) + 2; // ")^" = 2
			if( obenStart < 2 ) {	//0 (von sucheKlammern) + 2 = 2
				addFehler( fehlerListenID, {
					nutzer: "fehlende schließende Klammer",
					debug: "replaceConstructs: fehlende schließende Klammer"} );
				return input;
			}
			var unten = input.slice( untenStart + 1, obenStart - 2 );   //String der unteren Grenze
			var inhaltStart = sucheKlammern( input, obenStart ) + 1; // ")" = 1
			if( inhaltStart < 1 ) {	//0 + 1 = 1
				addFehler( fehlerListenID, {
					nutzer: "fehlende schließende Klammer",
					debug: "replaceConstructs: fehlende schließende Klammer"} );
				return input;
			}
			var oben = input.slice( obenStart + 1, inhaltStart - 1 );   //String der oberen Grenze
			var inhaltEnde = inhaltStart;   //Wird erst noch bestimmt

			var rumpf = input.slice( 0, treffer.index );	//Alles vor dem gefundenen Konstrukt
			var variable = "";  //Laufvariable, bei Integralen ist es das Differential ( ohne "(d(" und ")" )
			var rest = "";     //Rest des Eingabestrings ( nach inhalt ), enthält bei Integralen auch das Differential

			if( typ == "int" ) {    //Integral
				var dAuf,dZu;   //Positionen der Klammern des Differentials

				dAuf = findeAufKlammerEbene( input, "(d(", 0, inhaltStart );	//Anfang des Differentials

				inhaltEnde = dAuf - 1;

				if( ( dAuf >= input.length ) || ( dAuf < 0 ) ) {
					addFehler( fehlerListenID, {
						nutzer: "Differential fehlt",
						debug: "replaceConstructs: kein Differential" } );
					return input;
				}

				dZu = sucheKlammern( input, dAuf + 2 );	//erste schließende Klammer des Differentials "(d(...)<---"
				if( dZu < 0 ) {
					addFehler( fehlerListenID, {
						nutzer: "Differential hat kein Ende",
						debug: "replaceConstructs: Differential hat kein Ende" } );
					return input;
				}

				//Bestimmen der Variable ( des Differentials )
				variable = input.slice( dAuf + 3, dZu );

				rest = input.slice( dZu + 2 );
			} else {    //Kein Integral
				//Bestimmen der Laufvariable durch Aufsplitten
				var untenSplit = unten.split( '=' ); 
				variable = untenSplit.shift();	//Erstes element von untenSplit löschen und in variable speichern
				unten = untenSplit.join('=');	//Rest von untenSplit wieder zusammenfügen (wichtig damit Verschachtelung funktioniert)

				//Inhalt bestimmen
				if( input[inhaltStart] == "(" ) {   //Inhalt in Klammern?
					inhaltEnde = sucheKlammern( input, inhaltStart );
				} else {    //Ansonsten Inhalt bis "," (in Vektor) oder Ende des Strings 
					inhaltEnde = findeAufKlammerEbene( input, ",", 0, inhaltStart );
					if( inhaltEnde < 0 ) {	//Wenn kein Komma, nehme Ende des Strings
						inhaltEnde = input.length - 1;
					}
				}

				if( inhaltEnde < 0 ) {  //Fehlerbehandlung
					addFehler( fehlerListenID, {
						nutzer: "Fehlerhafte Klammersetzung",
						debug: "replaceConstructs: Konstrukt wird nicht beendet" } );
					return input;
				}
				rest = input.slice( inhaltEnde + 1 );
			}

			var inhalt = input.slice( inhaltStart, inhaltEnde + 1 );

			//Variable durch Schlüsselwort ersetzen 
			//( "(stuetzvariable_$variable)", wobei $variable durch den eigentlich Wert ersetzt wird )
			var variableEscaped = regexEscape( variable );  //Sonderzeichen für Regex escapen
			if( variableEscaped.length <= 0 ) { //leere variable Abfangen um Endlosschleife zu verhindern
				addFehler( fehlerListenID, {
					nutzer: "",
					debug: "replaceConstructs: Leere Variable" } );
				return input;
			}
			var rex = RegExp( "(^|[^a-zA-Z_])" + variableEscaped + "($|[^a-zA-Z])", "" );
			var lastInhalt;
			inhalt = replaceAllMatches( inhalt, rex, "$1(stuetzvariable_" + variableEscaped + ")$2" );

			//Rekursiver Selbstaufruf zum bearbeiten von verschachtelten Konstrukten.
			var untenObjekt = replaceConstructs( unten, integrationsSchritte, fehlerListenID );
			var obenObjekt = replaceConstructs( oben, integrationsSchritte, fehlerListenID );
			var inhaltObjekt = replaceConstructs( inhalt, integrationsSchritte, fehlerListenID );
			var restObjekt = replaceConstructs( rest, integrationsSchritte, fehlerListenID );

			//Rückgabeobjekt zusammensetzen
			result.mathjs = rumpf + 
			'konstrukt(' 
				+ typ + ','
				+ variable + ','
				+ untenObjekt.mathjs + ','
				+ obenObjekt.mathjs + ','
				+ inhaltObjekt.mathjs 
				+ (typ === "int"?',' + integrationsSchritte:"")
				+ ')'
				+ restObjekt.mathjs;
		}

		return result;
	}

	/*
	* Umhüllt Konstrukte im LaTeX-String mit geschweiften Klammern,
	* um die Weiterverarbeitung zu erleichtern
	* */
	function encloseLatexConstructs( input, fehlerListenID ) {
		//Regex zum finden des Anfangs von Konstrukten, die noch nicht eingeklammert sind
		var rex = RegExp( "(^|[^" + characterClassAuf + "]\\s*)\\\\(int|prod|sum)\\s*(\\^|_)", "" );

		//Verarbeite alle Konstrukte
		var treffer = rex.exec( input );
		while( treffer != null ) {
			var typ = treffer[2]; //Typ aus zweitem Regex-Submatch ( int, prod oder sum )
			var startPos = treffer.index + treffer[1].length; //Position des '\' vor typ

			//Suche nach dem Ende
			var ende = startPos
			if( typ == "int" ) {        //Integral?
				//Suche nach Differential
				var rest = input.slice( startPos );	//Input-String ab startPos
				ende = findeAufKlammerEbene( rest, "{d{", 0 );
				if( ende < 0 ) {  //Fehler abfangen
					addFehler( fehlerListenID, {
						nutzer: "Differential fehlt",
						debug: "encloseLatexConstructs: {d{ nicht gefunden" } );
					return input;
				}

				ende = sucheKlammern( rest, ende ) + 1;
				if( ende < 1 ) { //0 + 1 = 1
					addFehler( fehlerListenID, {
						nutzer: "Fehlerhafte Klammersetzung",
						debug: "encloseLatexConstructs: fehlende Klammer" } );
					return input;
				}

				ende += startPos;	//Mache ende zu Postion in input statt rest
			} else {
				//Suche nach ende der dritten Klammer, Komma oder Ende des Strings
				// "...\prod_{..}^{..}{...}..." bzw. "...\prod_{..}^{..}....."
				//                        ^                                 ^

				//An Ende von unterer Grenze gehen
				var pos = findeAufKlammerEbene( input, "{", 0, startPos );
				pos = sucheKlammern( input, pos );
				//An Ende von oberer Grenze gehen ( bzw. Anfang des Inhalts )
				pos = findeAufKlammerEbene( input, "{", 0, pos + 1 );
				pos = sucheKlammern( input, pos );
				if( pos < 0 ) {
					addFehler( fehlerListenID, {
						nutzer: "Fehlerhafte Klammersetzung",
						debug: "encloseLatexConstructs: fehlende Klammer" } );
				}

				if( (pos + 1 < input.length ) && (RegExp("[" + characterClassAuf + "]", "g").test( input[pos+1] )) ) {
					ende = sucheKlammern( input, pos+1 );
				} else {
					ende = findeAufKlammerEbene( input, ",", 0, pos+1 );
					if( ende < 0 ) {
						ende = input.length - 1;
					}
				}
			}

			var konstrukt = input.slice( startPos, ende + 1 );  //Gesamtes Konstrukt
			input = replaceByPos( input, startPos, ende + 1, "{" + konstrukt + "}" );   //Konstrukt in Klammern umhüllen

			treffer = rex.exec( input );
		}
		return input;
	}

	/*
	* Sucht Potenzen im LaTeX-String und umklammert sie mit
	* geschweiften Klammern, um die Bruchdarstellung zu ver-
	* einfachen.
	*
	* Wichtig hierbei ist vor allem die Unterscheidung von "^"
	* als Potenz und "^" als Anfang einer oberen Grenze.
	* */
	function encloseLatexPower( input, fehlerListenID ) {
		//TODO: weniger Copy & Paste
		//Ersetzen aller Leerstellen durch ein Leerzeichen ( z.B. "   " -> " " )
		input = input.replace( /\s+/g, " " );

		//Verarbeiten aller " ^" im Input
		//WICHTIG: In der Schleife müssen alle " ^" durch "^" (ohne Leerzeichen)
		// ersetzt werden, sonst ist das eine Endlosschleife
		for( var hochPos = input.lastIndexOf( " ^" ); hochPos != -1; hochPos = input.lastIndexOf( " ^" ) ) {	//Durchgehen aller " ^" von hinten nach vorne
			var anfang = input.slice( 0, hochPos );
			var ende = input.slice( hochPos + 2 ); //" ^".length == 2

			//Linke Seite untersuchen
			var rexWert = RegExp( "(\\\\?[a-z]+|[0-9]+(\\.[0-9]+)?)!*$", "i" );   //Zahl oder Variable ( inklusive "!" bei Fakultät )
			var rexKlammer = RegExp( "[" + characterClassZu + "](!*)$", "" ); //schließende Klammer am Ende ( inklusive "!" bei Fakultät )
			var wertPos = anfang.search( rexWert );
			var klammerPos = anfang.search( rexKlammer );
			var basisAnfang;	//Position des Anfangs der Basis der Potenz
			if( wertPos != -1 ) {	//Einfacher Ausdruch vor " ^"
				if( ( wertPos > 0 ) && ( anfang[wertPos - 1 ] == "_" ) ) {	//Untere Grenze davor ( ==> keine Potenz )
					input = anfang + "^" + ende;
					break;
				}
				basisAnfang = wertPos;
			} else if( klammerPos != -1 ) {	//Klammerausdruck vor " ^"
				var treffer = rexKlammer.exec( anfang );
				klammerPos = treffer.index;
				klammerPos = sucheKlammern( anfang, klammerPos );	//Zu öffnender Klammer springen
				if( klammerPos < 0 ) {
					addFehler( fehlerListenID, {
						nutzer: "Fehlende öffnende Klammer",
						debug: "encloseLatexPower: fehlende öffnende Klammer" } );
					return input;
				}

				//Weiter nach links, bis Anfang einer eventuellen vorhergehenden Funktion:
				// ...5+\arcsin(.....)
				//      ^<----^
				for( klammerPos--; ( klammerPos >= 0 ) && /[a-z\\]/i.test( anfang[klammerPos] ); klammerPos-- ) {}
				if( (klammerPos >= 0) && (anfang[klammerPos] == "_") ) {	//Untere Grenze davor ( ==> keine Potenz )
					input = anfang + "^" + ende;
					break;
				}
				klammerPos++;  //Korrigiere letztes "--" der For-Schleife

				basisAnfang = klammerPos;
			} else {
				addFehler( fehlerListenID, {
					nutzer: "Ungültige Basis in Potenz",
					debug: "encloseLatexPower: ungültige Basis in Potenz" } );
				return input;
			}

			//Rechte Seite bearbeiten
			rexWert = RegExp( "^(\\\\?[a-z]+|[0-9]+(\\.[0-9]+)?)", "i" );   //Zahl oder Variable ( ohne Fakultät, gemäß Priorität der Operatoren
			rexKlammer = RegExp( "^(\\\\?[a-z]+)?([" + characterClassAuf + "])", "i" ); //öffnende Klammer oder Funktion am Anfang
			var exponentEnde;
			if( rexKlammer.test( ende ) ) {	//Klammerausdruck oder Funktion im Exponenten
				exponentEnde = ende.search( RegExp( "[" + characterClassAuf + "]" ), "" );
				exponentEnde = sucheKlammern( ende, exponentEnde );
				if( exponentEnde < 0 ) {
					addFehler( fehlerListenID, {
						nutzer: "Fehlende schließende Klammer",
						debug: "encloseLatexPower: fehlende schließende Klammer"} );
					return input;
				}

				if( ( ende.length > exponentEnde + 2 ) && ( ende[exponentEnde + 2] == "_" ) ) {	//Untere Grenze dahinter ( ==> keine Potenz )
					input = anfang + "^" + ende;
					break;
				}
			} else if( rexWert.test( ende ) ) { //Zahl oder Variable am Anfang
				var treffer = rexWert.exec( ende );
				exponentEnde = treffer[0].length;
				if( ( ende.length > exponentEnde + 2 ) && ( ende[exponentEnde + 2] == "_" ) ) { //Untere Grenze dahinter ( ==> keine Potenz )
					input = anfang + "^" + ende;
					break;
				}
			} else {
				addFehler( fehlerListenID, {
					nutzer: "Ungültiger Exponent",
					debug: "encloseLatexPower: ungültiger Exponent" } );
				return input;
			}

			//Wenn hier angekommen, dann handelt es sich tatsächlich
			// um eine Potenz und nicht um Grenzen eines Konstruktes
			// ==> Einklammern des gesamten Ausdrucks

			//Eingabe weiter zerlegen
			var basis = anfang.slice( basisAnfang );
			var rumpf = anfang.slice( 0, basisAnfang );
			var exponent = ende.slice( 0, exponentEnde );
			var rest = ende.slice( exponentEnde );

			//Wieder zusammensetzen
			input = rumpf + "{" + basis + "^" + exponent + "}" + rest;

		}

		return input;
	}

	/*
	*  Wandelt Brüche im Input um in LaTeX-Brüche
	*  der Form "\frac{..}{..}"
	* */
	function latexFractions( input, fehlerListenID ) {
		//Verarbeite alle "/" im input
		for( var slashPos = input.search( "/" ); slashPos != -1; slashPos = input.search( "/" ) ) {
			var anfang = input.slice( 0, slashPos );
			var ende = input.slice( slashPos + 1 );

			//Linke Seite bearbeiten
			var rexWert = RegExp( "(\\\\?[a-z]+|[0-9]+(\\.[0-9]+)?)!*$", "i" );   //Zahl oder Variable ( inklusive "!" bei Fakultät )
			var rexKlammer = RegExp( "[" + characterClassZu + "](!*)$", "" ); //schließende Klammer am Ende ( inklusive "!" bei Fakultät )
			if( rexWert.test( anfang ) )  {  //Zahl oder Variable am Ende des Strings
				anfang = anfang.replace( rexWert, "{\\frac{$&}" );
			} else if( rexKlammer.test( anfang ) ) { //Klammerausdruck im Zähler
				var treffer = rexKlammer.exec( anfang );
				var klammerZuPos = treffer.index;
				var pos = sucheKlammern( anfang, klammerZuPos );
				if( pos < 0 ) {
					addFehler( fehlerListenID, {
						nutzer: "Fehlende öffnende Klammer",
						debug: "latexFractions: fehlende öffnende Klammer"} );
					return input;
				}

				//Weiter nach links, bis Anfang einer eventuellen vorhergehenden Funktion:
				// ...5+\arcsin(.....)
				//      ^<----^
				for( pos--; ( pos >= 0 ) && /[a-z\\]/i.test( anfang[pos] ); pos-- ) {}
				pos++;  //Korrigiere letztes "--" der For-Schleife

				var zaehler = anfang.slice( pos );
				anfang = replaceByPos( anfang, pos, anfang.length, "{\\frac{" + zaehler + "}" );
			} else {
				addFehler( fehlerListenID, {
					nutzer: "Ungültiger Dividend",
					debug: "latexFractions: ungültiger Dividend" } );
				return input;
			}

			//Rechte Seite bearbeiten
			rexWert = RegExp( "^(\\\\?[a-z]+|[0-9]+(\\.[0-9]+)?)!*", "i" );   //Zahl oder Variable ( inklusive "!" bei Fakultät )
			rexKlammer = RegExp( "^(\\\\?[a-z]+)?([" + characterClassAuf + "])", "i" ); //öffnende Klammer oder Funktion am Anfang
			if( rexKlammer.test( ende ) ) { //Klammerausdruck oder Funktion im Nenner
				var pos = ende.search( RegExp( "[" + characterClassAuf + "]", "" ) );
				pos = sucheKlammern( ende, pos );
				if( pos < 0 ) {
					addFehler( fehlerListenID, {
						nutzer: "Fehlende schließende Klammer",
						debug: "latexFractions: fehlende schließende Klammer"} );
					return input;
				}

				//Folgende "!" mit berücksichtigen
				for(; ( ende.length > pos + 1 ) && ( ende[pos+1] == '!' ); pos++ ) {}

				var nenner = ende.slice( 0,  pos + 1 );
				ende = replaceByPos( ende, 0, pos + 1, "{" + nenner + "}}" );
			} else if( rexWert.test( ende ) ) {    //Zahl oder Variable am Anfang des Strings
				ende = ende.replace( rexWert, "{$&}}" );
			} else {
				addFehler( fehlerListenID, {
					nutzer: "Ungültiger Divisor",
					debug: "latexFractions: ungültiger Divisor" } );
				return input;
			}

			input = anfang + ende;
		}

		return input;
	}

	/*
	 * Setzt Klammern um Funktionsaufrufe.
	 *
	 * input: String, in dem die Funktionen umklammert werden sollen.
	 * klammer: Klammer, mit der umklammert werden soll.
	 **/
	function encloseFunctions( input, klammer, fehlerListenID ) {
		var rex = RegExp( "([^" + characterClassAuf + "\\\\a-z]|^)([a-z]+)\\([^\\(]", "i" );

		var lastInput;
		do {
			lastInput = input;
			var treffer;
			do { //Überspringe konstrukte, da diese sonst nicht mehr geparsed werden können
				treffer = rex.exec( input );
			} while( (treffer != null) && /.(sum\(|int\(|prod\()/.test( input ) );
			if( treffer == null ) {
				break;
			} 

			var klammerAufPos = treffer.index + treffer[1].length + treffer[2].length;
			var klammerZuPos = sucheKlammern( input, klammerAufPos );
			if( klammerZuPos == -1 ) {
				addFehler( fehlerListenID,
						{ nutzer: "Fehlende schließende Klammer",
						debug: "encloseFunctions: fehlende schließende Klammer" } );
				break;
			}
			var functionCall = input.slice( treffer.index + treffer[1].length, klammerZuPos + 1 );
			input = replaceByPos( input, treffer.index + treffer[1].length, klammerZuPos + 1, klammer + functionCall + klammernPaare[klammer] );
		} while( input != lastInput );

		return input;
	}

	/**
	 * Prüft einen String auf nicht geschlossenen Klammern.
	 * Gibt entweder true oder False zurück.
	 **/
	function checkBrackets (input) {
		var stack = new Array();
		var abs = 0;

		for (var i = 0; i < input.length; i++) {
			if (input[i] === '|') {
				//überspringen von Betragszeichen
				abs++;
				continue;
			}
			//Ist es eine schließende Klammer
			if (getArrayKey(klammernPaare, input[i]) !== undefined) {
				//passt die klammer auf dem Stack nicht zu der schließenden?
				if (stack.pop() != getArrayKey(klammernPaare, input[i])) {
					return false;	
				}
			} else if (klammernPaare.hasOwnProperty(input[i])) { //öffnende Klammer
				stack.push(input[i]);
			}
		}
		
		if ((stack.length == 0) && (abs % 2 == 0)) {
			return true;
		}

		return false;
	}

	/*
	*  Nimmt die eingabe des Nutzers und verarbeitet Sie zu einem LaTeX-String,
	*  einem Parserstring und einem MathJS-String ( letzteres ist momentan nur eine
	*  Kopie des Parserstrings ).
	*
	*  Hierzu werden schritt für Schritt Teile der Eingabe ersetzt, bis das Endergebnis 
	*  erreicht ist.
	*
	*  integrationsSchritte: Anzahl der Schritte beim Integrieren
	*
	*  Der Rückgabewert ist ein Objekt der folgenden Form:
	*  {
	*     latex: "{\sum_{i=1}^{10}i}",
	*     mathjs: "konstrukt(sum,i,1,10,(stuetzvariable_i),100)"
	*     fehlerListe: Array mit aufgetretetenen Fehlern. Wenn dieser nicht leer
	*     				ist, sollte das Ergebnis nicht weiterverwendet werden.
	*  }
	*  Bei einer Beispieleingabe von "sum_(i=0)^(10)i"
	* */
	mparser.convertMathInput = function(input, integrationsSchritte ) {
		//Standardwert für integrationsSchritte
		integrationsSchritte = typeof integrationsSchritte !== 'undefined' ? integrationsSchritte : 1000;

		//"\" aus input entfernen
		input = input.replace( RegExp( "\\\\", "g" ), "" );

		// Erstelle Objekt fuer Rueckgabewert
		var result = {
			latex: input,   //String zur Anzeige
			mathjs: input   //String fuer MathJS
		};

		/*
		* Ein Array aus Einträgen der Form
		*  {
		*      nutzer: "Fehlermeldung an Benutzer",
		*      debug:   "Interne Fehlermeldung für Debug-Zwecke"
		*  }
		* */
		var fehlerListenID = globalMap.add( new Array() ); 


		//Einfache Ersetzungen durchführen (ohne Klammerausdrücke)
		result.latex = simpleReplace( result.latex, "latex", fehlerListenID );
		result.mathjs = simpleReplace( result.mathjs, "mathjs", fehlerListenID );

		//Klammerausdrücke bearbeiten
		result.latex = bracketReplace( result.latex, "latex", fehlerListenID );
		result.mathjs = bracketReplace( result.mathjs, "mathjs", fehlerListenID );
		
		//Funktionsaufrufe umklammern
		result.latex = encloseFunctions( result.latex, "{", fehlerListenID );
		result.mathjs = encloseFunctions( result.mathjs, "(", fehlerListenID );

		//Klammersetzung für Grenzen/Exponenten, die einzeln vorkommen
		//_74.3 -> _{74.3}, ^\alpha -> ^{\alpha} ...
		var rex = RegExp( "(_|\\^)(-?\\\\?[a-z]+|-?[0-9]+(?:\\.[0-9]+)?)", "gi" );
		result.latex = result.latex.replace( rex, " $1{$2}" );
		result.mathjs = result.mathjs.replace( rex, "$1($2)" );

		//Negative Zahlen in Klammern setzen, um parsen zu vereinfachen
		rex = RegExp( "([+\\-*/]|^)(-\\\\?[a-z]+|-[0-9]+(?:\\.[0-9]+)?)([^a-z" + regexEscape( characterClassAuf ) +  "]|$)", "gi" );
		result.latex = replaceAllMatches( result.latex, rex, "$1{$2}$3" );

		//Differentiale in LaTeX-String ersetzen durch {d{..}}
		result.latex = preprocessDifferentials( result.latex, '{', fehlerListenID )
		//Klammern um Konstrukte in LaTeX-String als vorbereitung für Bruchdarstellung
		result.latex = encloseLatexConstructs( result.latex, fehlerListenID );
		//Klammern um Potenzen in LaTeX-String als Vorbereitung für Bruchdarstellung
		result.latex = encloseLatexPower( result.latex, fehlerListenID );
		//Bruchdarstellung in LaTeX umsetzen
		result.latex = latexFractions( result.latex, fehlerListenID );

		//(wert)! -> wert! in LaTeX
		rex = RegExp( "(\\()(\\\\?[a-z]+|[0-9]+(\\.[0-9]+)?)(\\))!", "gi" );    //Zahlen oder Variablen in Klammern mit Fakultät
		result.latex = result.latex.replace( rex, "$2!" );


		//MathJSstring nachbearbeiten
		rex = RegExp( "[{]", "g" );  //Oeffnende Klammern
		result.mathjs = result.mathjs.replace( rex, "(" );
		rex = RegExp( "[}]", "g" );  //Schliessende Klammern
		result.mathjs = result.mathjs.replace( rex, ")" );
		//Differentiale ersetzen (wichtig: vor dem entfernen von Leerzeichen und nach dem Ersetzen von Klammern )
		result.mathjs = preprocessDifferentials( result.mathjs, '(', fehlerListenID );
		rex = RegExp( "\\s+", "g" );      //Leerzeichen
		result.mathjs = result.mathjs.replace( rex, "" );

		//obere und untere Grenzen von Konstrukten gegebenenfalls vertauschen
		result.mathjs = swapBoundaries( result.mathjs, fehlerListenID );

		//Konstrukte ( prod, int, sum ) verarbeiten
		var temp = replaceConstructs( result.mathjs, integrationsSchritte, fehlerListenID );
		result.mathjs = temp.mathjs;

		//Klammern in LaTeX durch "\left(" bzw. "\right)" ersetzen
		//Hierbei werden ersteinmal alle \left und \right entfernt,
		//weil ich keine einfache Regex gefunden habe, um das in einem Schritt zu machen.
		rex = RegExp( "(\\\\left|\\\\right)(\\(|\\))", "g");
		result.latex = result.latex.replace( rex, "$2");
		result.latex = result.latex.replace( /\(/g, "\\left(" );
		result.latex = result.latex.replace( /\)/g, "\\right)" );

		//Fehlerliste zu Rückgabewert hinzufügen und auf globalMap löschen
		result.fehlerListe = globalMap.get( fehlerListenID );
		globalMap.remove( fehlerListenID );

		//left und right aus LaTeX entfernen, wenn
		//die Klammern noch nicht vollständig sind
		if (!checkBrackets(result.latex)) {
			result.latex = result.latex.replace(/\\left\(/g, '(');
			result.latex = result.latex.replace(/\\right\)/g, ')');
		}

		logMessage(VERBOSEINFO, "convertMathinput Rückgabeobjekt: " + JSON.stringify(result));

		return result;
	};

	/*
	* Auswerten eines Ausdrucks mit gegebenen Werten für Variablen.
	* Gibt einen Array aus Ergebnissen zurück.
	*
	* expression: Auszuwertender Ausdruck ( String )
	*
	* variables: Objekt, das den Variablennamen einen Array aus Werten zuweist:
	*  z.B.:
	*  var variables = {
	*      x: [ 1, 2, 3, 4 ],
	*      y: [ 5, 6, 7, 8 ]
	*  };
	*
	*  Ist variables nicht vorhanden, so wird ohne Variablenwerte ausgewertet!
	*
	*  !Hinweis: Die Funktion benutzt die Anzahl der Werte irgendeiner beliebigen
	*  Variable im Scope um die Anzahl der Werte zu bestimmen. Dies kann zu
	*  Fehlverhalten führen, wenn für verschiedene Variablen verschieden
	*  viele Werte angegeben wurden.
	* */
	mparser.evalMathJS = function( expression, variables ) {
		//Parsen und Kompilieren des Ausdrucks
		var code = mathJS.compile( expression );

		//Wenn "variables" nicht gesetzt, direkt auswerten
		if( (typeof variables) == "undefined" ) {
			return code.eval();
		}

		//Bestimmen der Anzahl an Variablenwerten
		var anzahl = variables[Object.keys(variables)[0]].length;   //Länge des ersten Arrays in variables

		var ergebnisse = []; //Array für die Rechenergebnisse

		//Werte Ausdruck für alle Variablenwerte aus
		for( var i = 0; i < anzahl; i++ ) {
			var scope = {};
			//Füge alle Variablen mit entsprechenden Werten zu Scope hinzu ( Schleife über alle Variablen )
			jQuery.each( variables, 
				function ( property, value ) {
					scope[property] = value[i]; //i-ten Wert für Variable in Scope einfügen
				}
			);

			ergebnisse[i] = code.eval( scope );
		}
		return ergebnisse;
	};
	
	/*
	 * Erhält ein Lineares Gleichungssystem in form einer Koeffizientenmatrix, 
	 * einen Vektor der rechten Seite des Gleichungssystems und eine Eingabe vom Nutzer,
	 * die auf eine Richtige Lösung überprüft wird.
	 *
	 * Parameter:
	 * coefficientMatrix: Array von Strings, die die Spalten der Koeffizientenmatrix enthalten
	 * 			["(1,2,3)", "(4,5,6)", "(7,8,9)"]
	 * rightHandSide: String mit dem Vektor der rechten Seit des Gleichungssystems
	 * userSolution: String mit dem Array der vom Nutzer angegebenen Lösung
	 * accuracy: Mindestens diese Anzahl von Stellen müssen übereinstimmen
	 *
	 * Rückgabewert ist true, falls die Lösung richtig ist und false, falls nicht.
	 * */
	mparser.checkSetOfLinearEquations = function( coefficientMatrix, rightHandSide, userSolution, accuracy ) {
		//Standardwert für accuracy
		accuracy = typeof accuracy !== 'undefined' ? accuracy : 3;

		//Baue Koeffizientenmatrix zusammen
		var matrix = "["; //Koeffizientenmatrix in mathjs-Notation als String
		coefficientMatrix.forEach(
			function( input ) {
				var returnObject = mparser.convertMathInput( input );
				if( returnObject.fehlerListe.length != 0 ) {
					throw "FEHLER: Parsen der Koeffizientenmatrix fehlgeschlagen";
				}
				matrix += returnObject.mathjs + ',';	//Spalte zu Matrix hinzufügen
			}
		);
		//Letztes Komma durch eine schließende Klammer ersetzen
		matrix = matrix.replace( /,$/, "]" );

		//Vom Nutzer eingegebene "Lösung" vorverarbeiten
		var returnObject = mparser.convertMathInput( userSolution );
		if( returnObject.fehlerListe.length != 0 ) {
			throw "FEHLER: Parsen der vom Nutzer eingegebenen Lösung fehlgeschlagen";
		}
		userSolution = returnObject.mathjs;

		//rechte Seite des Gleichungssystems vorverarbeiten
		var returnObject = mparser.convertMathInput( rightHandSide );
		if( returnObject.fehlerListe.length != 0 ) {
			throw "FEHLER: Parsen der rechten Seite des Gleichungssystems fehlgeschlagen";
		}
		rightHandSide = returnObject.mathjs;

		//Umwandeln in mathjs-Datentypen
		var mathjsKoeffMatrix;
		var mathjsRightHandSide;
		var mathjsUserSolution;
		mathjsKoeffMatrix = mathJS.matrix( mathJS.transpose( mathJS.eval( matrix ) ) );
		mathjsRightHandSide = mathJS.matrix(  mathJS.eval( rightHandSide ) );
		mathjsUserSolution = mathJS.matrix( mathJS.eval( userSolution ) );

		//Einsetzen der "Lösung" des Nutzers
		var mathjsUserRightHandSide = mathJS.multiply( mathjsKoeffMatrix, mathjsUserSolution );

		//Berechnen der Differenz
		try {
			var mathjsDelta = mathJS.subtract( mathjsUserRightHandSide, mathjsRightHandSide );
			mathjsDelta.forEach( 
					function( value ) {
						if( mathJS.abs( extround(value, accuracy) ) > mathJS.pow(10,(accuracy+2)*(-1)) ) {
							throw false;
						}

					}
			);
		} catch( e ) {
			return e;
		}

		return true;
	};

	//Dieses Return-Objekt definiert das öffentliche Interface
	return mparser; 
})(); //ENDE der Closure

