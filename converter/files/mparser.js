/*
 * Additional functions for parsing LaTeX and maths
 * Max Bruckner 2014-2015
 *
 * The purpose of this file is to convert a string (which has been entered
 * into a textfield for example) into a LaTeX string that can be displayed
 * by MathJax and a string that can be parsed and evaluated by math.js. This
 * is done by the function convertMathInput()
 *
 * With the function evalMathJS() it is possible to evaluate a math.js
 * compatible string with an array of values.
 * */

//initialise mathjs
var mathJS = math;
//additional functions for the scope of mathjs
var mathJSFunctions = (function( mathjsInstance ) {
	const epsilonAbstand = 0.0001;    //delta for which a floating point value should still be treated as integer

	var functions = {};

	functions.ln = function( x ) {
		return mathjsInstance.log( x );
	};

	/*
	 * evaluates integrals, sums and products
	 *
	 * typ: "int", "sum" or "prod"
	 * variable: variable of integration/summation/multiplication
	 * unten: lower bound
	 * oben: upper bound
	 * inhalt: content of the construct
	 * schritte: number of calculation steps (only relevant for integrals)
	 * */
	functions.konstrukt = function( args, mathjsInstance, scope  ) {
		//get parameters
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
		//if integral, swap bounds if necessary
		if( (unten > oben) && ( typ == "int" ) ) {
			var swap = oben;
			oben = unten;
			unten = swap;
			faktor = -1;
		}

		var intervallbreite;    //size of the calculation steps
		var operation;  //operation that gets calculated in every step ( operation( total, current, next, intervallbreite ) )
		var wert;       //Anfangswert
		//define operation and step size for respective types
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
					return mathjsInstance.add( total, mathjsInstance.multiply( mathjsInstance.divide( mathjsInstance.add(current, next), 2 ), intervallbreite ) ); //middle sum
				}
				intervallbreite = mathjsInstance.divide( mathjsInstance.subtract(oben, unten), schritte );
				wert = 0;
				break;
			default:
				return  0;
		}

		//abort if when step size if 0
		if( intervallbreite == 0 ) {
			return 0;
		}

		//evaluate the construct
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
	 * calculate the factorial of a number
	 *
	 * special feature: if the value differs from an integer
	 * only by 'epsilonAbstand', then it get's rounded to the
	 * respective integer
	 * */
	functions.fakultaet = function( zahl ) {
		if( mathjsInstance.subtract( zahl, mathjsInstance.round( zahl ) ) <= epsilonAbstand ) {
			return mathjsInstance.factorial( mathjsInstance.round(zahl) );
		}

		return mathjsInstance.factorial( zahl );
	};

	/*
	 * Berechnen des Binomialkoeffizienten n über k.
	 * calculate the binomial n over k
	 *
	 * As with factorial, this respects 'epsilonAbstand'.
	 *
	 * This is a modified version of the algorithm used here:
	 * https://de.wikipedia.org/wiki/Binomialkoeffizient
	 * */
	functions.binomial = function( n, k ) {
		//negative values for k aren't valid
		if( k < 0 ) {
			throw "FEHLER: Negatives k bei Binomialkoeffizient";
		} else if( k > n ) {
			throw "FEHLER: Im Binomialkoeffizient darf k nicht groesser als n sein.";
		}

		//convert values to integers (if they differ maximally by 'epsilonAbstand')
		if( mathjsInstance.subtract( n, mathjsInstance.round( n ) ) <= epsilonAbstand ) {
			n = mathjsInstance.round( n );
		}
		if( mathjsInstance.subtract( k, mathjsInstance.round( k ) ) <= epsilonAbstand ) {
			k = mathjsInstance.round( k );
		}

		//calculation
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

	/*
	 * calculate expressions of the form sqrt[2^k](n)
	 *
	 * @param {Number} zweierexponent
	 * @param {Number} radikand
	 */
	functions.broot = function (zweierexponent, radikand) {
		function isNonNegativeInteger (number) {
			return (number % 1 === 0) && (number >= 0);
		}

		if (zweierexponent == 0) {
			return radikand;
		}
		else if (radikand == 0) {
			return 0;
		}
		else if (!isNonNegativeInteger(zweierexponent)) {
			return new TypeError('broot: Der Zweierexponent muss eine natürliche Zahl sein.');
		}
		else if (radikand < 0) {
			return new TypeError('broot: Der Radikand muss eine positive Zahl sein.');
		}

		for (; zweierexponent > 0; zweierexponent--) {
			radikand = mathJS.sqrt(radikand);
		}

		return radikand;
	};

	//add references to functions
	functions.arcsin = mathjsInstance.asin;
	functions.arccos = mathjsInstance.acos;
	functions.arctan = mathjsInstance.atan;
	functions.arccot = mathjsInstance.acot;
	functions.arcsinh = mathjsInstance.asinh;
	functions.arccosh = mathjsInstance.acosh;
	functions.arctanh = mathjsInstance.atanh;
	functions.arccoth = mathjsInstance.acoth;
	functions.konstrukt.rawArgs = true;	//enable custom argument parsing

	//this return object defines the public interface
	return functions;
})( mathJS ); //mathJS gets passed as mathjsInstance

//import the functions into the namespace of mathjs
mathJS.import( mathJSFunctions );



//-------------------------------------------------------------------------------------------------------------------
/*
 * closure that defines the mparser module. This encapsules all of the functions that shouldn't be publicly visible.
 **/
var mparser = (function() {
	var mparser = {};
	/*
	 * returns the key to a given value in an associative array.
	 * This only works correclty if the the value is only used once.
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
	 * Replaces everything from 'start' to 'ende' in 'input' by 'replace'.
	 * This works like String.prototype.slice (excluding the character at 'ende')
	 * */
	function replaceByPos( input, anfang, ende, replace ) {
		var rumpf = input.slice( 0, anfang );
		var rest = input.slice( ende );
		return rumpf + replace + rest;
	}

	//escape strings for use in regular expressions
	function regexEscape( input ) {
		return input.replace( /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&" );
	}

	/*
	 * Repeatedly replace all matches of 'regex' until no matches are found.
	 * This is necessary if matches overlap.
	 *
	 * regex: RegExp object
	 * WARNING: It's easy to run into an infinite loop when using this function
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
	 * Replace every occurence of 'word' in 'input'
	 *
	 * A word is only then matched, if is preceded or followed by letters or '\'
	 * */
	function replaceWord( input, word, replacement ) {
		var lastChar = " ";
		var letter = RegExp( "[a-zA-Z\\\\]", "" );
		for( var pos = 0; pos < input.length; pos++ ) {
			if( (! letter.test( lastChar ) ) && ( input[pos] == word[0] ) ) {
				var suchPos;
				for( suchPos = 0; (suchPos < word.length) && (word[suchPos] == input[pos+suchPos]); suchPos++ ) {}
				//found
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
	 * Global lists of replacements etc.
	 * -------------------------------------
	 * */


	/* TODO: remove this in favor of a single object that gets passed through the functions instead of an error id
	 * global map with unique ids
	 *
	 * - add objects with globalMap.add(object), returns an id.
	 * - delete objects with globalMap.remove(id)
	 * - get objects with globalMap.get(id)
	 * - ovwerwrite objects with globalMap.set(id, object)
	 * */
	var globalMap = {
		lastID: 0,
		add: function( objekt ) {
			var id = this.lastID + 1;
			//this is an infinite loop if the map has 9007199254740992 entries (shouldn't happen)
			//this loop ensures that even after an overflow of the counter, no id gets used twice
			for(; typeof this[id] != "undefined"; id++ ) {
			}
			if( typeof objekt === "undefined" ) {
				//replace 'undefined' by 'null' to be able to distinguish empty from nonexistent objects
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
					//replace 'undefined' by 'null' to be able to distinguish empty from nonexistent objects
					objekt = null;
				}
				this[id] = objekt;
			}
	};

	/*
	*  add an error message to the list of errors
	* */
	function addFehler( fehlerListenID, fehler ) {
		var fehlerListe = globalMap.get( fehlerListenID );
		fehlerListe.push( fehler );
		globalMap.set( fehlerListenID, fehlerListe );
	}

	/*
	 * expressions to be replaced (without brackets)
	 *
	 * array of objects of the form:
	 *
	 *	{	ausdruck: [ "a", "b" ], 	//Array of expressions
	 *		replace: {
	 *			"latex": "LaTeXString",
	 *			"mathjs": "Parserstring"
	 *			//replaces "$0" by the expression
	 *		},
	 *		word: true	//should the expression be replaced as entire word only (no letters or '\' before/after the expression [important distinction because some expressions are subsets of others] )
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
				"latex": " ^{1}",	//NOTE: the space is important
				"mathjs": "^1"
			},
			word: false
		},
		{
			ausdruck: [ "²" ],
			replace: {
				"latex": " ^{2}",	//NOTE: the space is important
				"mathjs": "^2"
			},
			word: false
		},
		{
			ausdruck: [ "³" ],
			replace: {
				"latex": " ^{3}",	//NOTE: the space is important
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
			ausdruck: [ "_", "^" ],	//important for parenthesis
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
		"|": "|"   //'|' only useful for replacing, not searching (because opening and closing characters are identical)
	};

	//the following strings get treated as differentials if preceded by a 'd'
	var differentiale = [ "x", "y", "z", "t", "u" ];

	//construct character classes for opening and closing parentheses
	var characterClassAuf = "";
	var characterClassZu = "";
	Object.keys( klammernPaare ).forEach(
		function( key ) {
			characterClassAuf += regexEscape( key );
			characterClassZu += regexEscape( klammernPaare[key] );
		}
	);

	//expressions that need other parentheses when used in LaTeX
	// {
	//     ausdruck: "expression to search for",
	//     replace: {
	//        0: "replacement for an arbitrary number of parameters",
	//        1: "replacement for expression with one parameter",
	//        2: "replacement for expression with two parameters"
	//        //$1 gets replaced by the first parameter, $2 by te second ...
	//        //$0 gets replaced by the expression itself
	//        },
	//     klammern: "all of the brackets for which the expression applies"
	//
	// }
	//
	// In case of 0 (meaning an arbitrary number of parameters) the object looks like the following:
	// 0: {
	// 	anfang: "beginning of the resulting expression",
	// 	argument: "what the argument gets replaced by",
	// 	trenner: "Trenner zwischen Argumenten",
	// 	ende: "ending of the resulting expression"
	// }
	// In case of an arbitrary number of parameters, $i gets replaced by the respective parameter
	var toReplaceKlammern =  [
		{
			//trigonometric and other functions that can be converted to latex by adding '\\' at the beginning of the string
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
		{ //differentials
			ausdruck: [ "d" ],
			replace: {
				"latex": {
					1: " {~d{$1}} "	//NOTE: The spaces are important
				},
				"mathjs": {
					1: "(d($1))"
				}
			}
		},
		//IMPORTANT: The entry for vectors has to be the last one because the empty
		//string will always be matched --> subsequent entries will be ignored!
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
	 * Replace expressions in in 'input' using the patterns defined in 'toReplace'
	 *
	 * input: string to be processed
	 * mode: which kind of replacement should be performed ("latex", "mathjs")
	 * */
	function simpleReplace( input, mode, fehlerListenID ) {
		//step through replacement patterns
		toReplace.forEach(
			function( element ) {
				//step through 'names' of this expression ("ausdruck") (e.g. asin, arcsin for the arcus sine)
				element.ausdruck.forEach(
					function( ausdruck ) {
						var ersetzung = element.replace[mode];
						ersetzung = ersetzung.replace( RegExp( "\\$0", "g" ), ausdruck ); //replace $0 by the matched expression
						if( element.word ) { //replace only complete words? ("sin" would only match "sin" but not "arcsin" )
							input = replaceWord( input, ausdruck, ersetzung );
						} else {
							input = input.replace( RegExp( regexEscape( ausdruck ), "g" ), ersetzung  );
						}
					}
				);
			}
		);
		return input;
	}


	/*
	 * Recursively replaces expressions with parentheses (like functions).
	 * A word followed by parentheses that contain one or multiple comma
	 * separated expressions.
	 *
	 * Example (including variable names):
	 * 	gamma+log(alpha,beta)+epsilon
	 *   ---------^----- ----^--------
	 *    ^       |   ^   ^  |     ^
	 *    |  anfang   |   |  ende  |
	 *    rumpf       |   |        rest
	 *       inhalte[0]   inhalte[1]
	 *
	 * The patterns in 'toReplaceKlammern' are used.
	 *
	 * Parameters:
	 *  input: input string
	 *  mode: which kind of replacement should be performed ("latex", "mathjs")
	 * */
	function bracketReplace( input, mode, fehlerListenID ) {
		//find an opening bracket
		var rex = RegExp( "[" + characterClassAuf + "]", "" );	//opening bracket
		var treffer = rex.exec( input );
		if( treffer != null ) {
			var klammerAuf = treffer[0];
			var anfang = treffer.index;	//position of the opening bracket
			var ende = sucheKlammern( input, anfang );	//closing bracket
			if( ende < 0 ) {
				addFehler( fehlerListenID, {
					nutzer: "Fehlende schließende Klammer!",
					debug: "bracketReplace: fehlende schließende Klammer" }
				);
				return input;
			}

			var inhalte = [];	//array of arguments contained by the brackets
			//split content of the brackets using comma
			for( var pos = anfang + 1; (pos > 0) && (pos < ende); pos = nextKomma + 1 ) {
				var nextKomma = findeAufKlammerEbene( input, ",", 0, pos );
				if( (nextKomma == -1 ) || (nextKomma > ende) ) {
					nextKomma = ende;
				}
				inhalte.push( bracketReplace( input.slice( pos, nextKomma ), mode, fehlerListenID ) );
			}

			//strings in front of and afther the expression
			var rumpf = input.slice( 0, anfang );
			var rest = input.slice( ende + 1 );

			//string to put the new content of the brackets into
			var inhalt = "";

			//step through replacements
			var i;
			treffer = null;
			for( i = 0; (i < toReplaceKlammern.length) && (treffer == null); i++ ) {
				// skip if the type of parentheses isn't in the list
				var klammern = toReplaceKlammern[i].klammern;
				if( (typeof klammern == "undefined") || (klammern.search( regexEscape(klammerAuf) ) != -1 ) ) {
					//step through the patterns to search for
					for( j in toReplaceKlammern[i].ausdruck ) {
						var ausdruck = toReplaceKlammern[i].ausdruck[j];
						//search for the expression at the end of 'rumpf'
						rex = RegExp( "(^|[^a-zA-Z\\\\])(" + regexEscape( ausdruck ) + ")$", "" );
						treffer = rex.exec( rumpf );
						if( treffer != null ) {
							rumpf = rumpf.replace( rex, "$1" );	//remove expression from 'rumpf'
							//is a replacement with the given number of commas defined?
							if( (typeof toReplaceKlammern[i].replace[mode][inhalte.length]) != "undefined" ) {
								inhalt = toReplaceKlammern[i].replace[mode][inhalte.length];
							} else if( (typeof toReplaceKlammern[i].replace[mode][0]) != "undefined" ) {	//is there a replacement for an arbitrary number of parameters?
								var replaceObject = toReplaceKlammern[i].replace[mode][0];

								//concatenate replacement string
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

							//replace all '$' expressions in 'inhalt'
							//replace "$0" with "ausdruck"
							rex = RegExp( "\\$0", "g" );
							inhalt = inhalt.replace( rex, ausdruck );
							//replace remaining arguments ($1, $2, ... )
							for( var j = inhalte.length; j > 0; j-- ) {	//count down to e.g. replace $11 before $1
								rex = RegExp( "\\$" + j, "g" );
								inhalt = inhalt.replace( rex, inhalte[j-1] );
							}

							break;	//break out of loop because the matching expression has already been found
						}
					}
				}
			}

			//if no match, create "inhalt" by concatenating "inhalte" (otherwise stuff like '{\cdot}' wouldn't work
			if( (i == toReplaceKlammern.length) && (treffer == null)   ) {
				inhalt = klammerAuf + inhalte.join( ',' ) + klammernPaare[klammerAuf];
			}

			return rumpf + inhalt + bracketReplace( rest, mode, fehlerListenID );
		}
		return input;
	}

	/*
	 * search for the matching bracket to a given bracket.
	 *
	 * returns the position of the bracket or -1 if not found.
	**/
	function sucheKlammern( input, klammerPos ) {
		//klammerAuf doesn't have to be an opening bracket, it can also be a closing one
		//in which case function would search from right to left
		var klammerAuf = input[klammerPos];
		var klammerZu = '';
		var delta;  //search direction ( -1: left, +1: right )
		//bestimme Suchrichtung und setze Klammernpaare
		if( klammernPaare[klammerAuf] != undefined ) { //'klammerAuf' is opening bracket
			klammerZu = klammernPaare[klammerAuf];
			delta = 1;  //search right
		} else if( getArrayKey( klammernPaare, klammerAuf ) ) { //check if 'klammerAuf' is a closing bracket
			klammerZu = getArrayKey( klammernPaare, klammerAuf );
			delta = -1; //search left
		} else {
			return -1;
		}

		//now do the actual search
		var klammerZuPos;
		var zaehler = 1;
		for( klammerZuPos = klammerPos + delta; (zaehler > 0) && (klammerZuPos >= 0) && (klammerZuPos < input.length); klammerZuPos += delta ) {
			if( input[klammerZuPos] == klammerZu ) {
				zaehler--;
			} else if( input[klammerZuPos] ==  klammerAuf ) {
				zaehler++;
			}
		}
		klammerZuPos -= delta;  //compensate for the last "+= delta" in the loop

		//matching bracket found?
		if( zaehler == 0 ) {
			return klammerZuPos;
		} else {
			return -1;
		}
	}

	/*
	 * Searches for a string but only matches on a given level of brackets.
	 * ( "klammerebene" 0 by default, "startPos" 0 by default).
	 *
	 * Returns the position of the match or -1 if no match is found.
	 *
	 * NOTICE: Treat's all bracket's equally. It doesn't check if they actually match
	 * TODO: Make this distinction possible
	 * */
	function findeAufKlammerEbene( input, suchString, klammerEbene, startPos ) {
		//set default value if undefined
		klammerEbene = (typeof klammerEbene != 'undefined') ? klammerEbene : 0;
		startPos = (typeof startPos != 'undefined') ? startPos : 0;

		//abort if "suchString" is empty
		if( suchString.length < 1 ) {
			return -1;
		}

		//replace all parentheses by round brackets:
		input = input.replace( RegExp( "[" + characterClassAuf + "]", "g"), "(" );
		input = input.replace( RegExp( "[" + characterClassZu + "]", "g"), ")" );
		suchString = suchString.replace( RegExp( "[" + characterClassAuf + "]", "g"), "(" );
		suchString = suchString.replace( RegExp( "[" + characterClassZu + "]", "g"), ")" );

		var aktuelleEbene = 0;
		var pos;			//position in the input
		//search for "suchString"
		for( pos = startPos; (pos < input.length); pos++ ) {
			if( (aktuelleEbene == klammerEbene) && (input[pos] == suchString[0]) ) {
				var suchPos;
				for( suchPos = 0; (suchPos < suchString.length) && (suchString[suchPos] == input[pos+suchPos]); suchPos++ ) {}
				if( suchPos == suchString.length ) {	//found
					return pos;
				}
			}

			//count brackets
			if( input[pos] == '(' ) {
				aktuelleEbene++;
			} else if( input[pos] == ')' ) {
				aktuelleEbene--;
			}
		}

		return -1;
	}

	/*
	 * swaps '^(...) _(...)' --> '_(...)^(...)'
	 *
	 * This only works in the mathjs string, not the latex string
	 *
	 * NOTICE: bounds inside of bounds aren't supported
	 * ( like "int_{int_{a}^{b}}^{c}" )
	 *                 --------
	 * */
	function swapBoundaries( input, fehlerListenID ) {
		//remove whitespaces
		input = input.replace( /\s+/g, '' );

		var untereGrenzeStart = findeAufKlammerEbene( input, "_(", 0 ); // "anfang"->_(...)
		if( untereGrenzeStart != -1 ) { //Wenn "_(" gefunden
			var untereGrenzeEnde = sucheKlammern( input, untereGrenzeStart + 1 ); //_(...)<-"ende"
			if( untereGrenzeEnde < 0 ) {
				addFehler( fehlerListenID, {
					nutzer: "Untere grenze endet nicht",    //TODO: find better name because "Grenze" only fits with integrals
					debug: "swapBoundaries: untere Grenze endet nicht" } );
				return input;
			}

			//strings in front of and after '_(...)'
			var anfang = input.slice( 0, untereGrenzeStart );
			var ende = input.slice( untereGrenzeEnde + 1 );

			var untereGrenze = input.slice( untereGrenzeStart + 2, untereGrenzeEnde );

			//the position of the upper bound isn't relative to 'input', but 'anfang'
			//or 'ende', depending on where the upper bound is
			var obereGrenzeStart;
			var obereGrenzeEnde;

			//search for '^(..)' after '_(..)'
			var obereGrenzeStart = findeAufKlammerEbene( ende, "^(", 0 );
			if( obereGrenzeStart == 0 ) { // "^(" at the beginning of  'ende'
				obereGrenzeEnde = sucheKlammern( ende, 1 );
				if( obereGrenzeEnde >= 0 ) {
					var obereGrenze = ende.slice( obereGrenzeStart + 2, obereGrenzeEnde );
					var endeRest = ende.slice( obereGrenzeEnde + 1 );   //remaining part of 'ende' that doesn't belong to the upper bound
					//return the string without swapping
					return anfang + "_(" + untereGrenze + ")" + "^(" +  obereGrenze + ")" + swapBoundaries( endeRest, fehlerListenID );
				} else {
					addFehler( fehlerListenID, {
						nutzer: "Obere grenze endet nicht",    //TODO: find better name because "Grenze" only fits with integrals
						debug: "swapBoundaries: obere Grenze endet nicht" } );
					return input;
				}
			} else {
				//search for '^(...)' in front of '_(...)'
				if( anfang[anfang.length - 1] == ')' ) {	//does 'anfang' end with ')'?
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

		return input;   //this line should never be reached
	}

	/*
	 * process differentials to be of the form '(d(x))'
	 * (both LaTeX and mathjs strings)
	 *  input: input string
	 *  klammerTyp: opening bracket of the type to be used in the replacement
	 *              ( mainly '(' for the mathjs string and '{' for the LaTeX string )
	 *
	 * differentials of the form 'd(...)' are processed via 'toReplaceKlammern'
	 * */
	function preprocessDifferentials( input, klammerTyp, fehlerListenID ) {
		var klammerAuf = klammerTyp;
		var klammerZu = klammernPaare[klammerTyp];
		//erstellen der Regex für einfache Differentiale ( dx, dy ... )
		//create regular expression for simple differentials
		var regexString = "(";      //goal: '(x|y.....)'
		differentiale.forEach( //TODO: use Array.prototype.join ?
			function( differential ) {
				regexString += differential + "|";
			}
		);
		regexString = regexString.slice( 0, -1);      //remove last '|'
		regexString += ')';

		var rex = RegExp( "(^|[^a-zA-Z])d" + regexString + "($|[^a-zA-Z])", 'g' );
		input = replaceAllMatches( input, rex, "$1" + klammerAuf + "d" + klammerAuf + "$2" + klammerZu + klammerZu + " $3" );
		return input;
	}

	/*
	 * Determines the content of a construct and it's differential (for integrals) and formats it:
	 *
	 *
	 *   mathjs-string: int_(...)^(...)(...)(d(x))
	 *                                ^   ^
	 *                          'anfang' 'ende'
	 *
	 * Returns an object with the elements 'mathjs' and 'mathjs' TODO: WTF?
	 * */
	function replaceConstructs( input, integrationsSchritte, fehlerListenID ) {
		var result = {
			mathjs: input,
			mathjs: input
		};
		var rex = new RegExp( "(int|sum|prod)_\\(" );
		var treffer = rex.exec( input );
		if( treffer != null ) {
			var typ = treffer[1];   //type ( sum, int, prod )

			//bounds and content
			var untenStart = treffer.index + typ.length + 1; // "int_" = typ.length + 1
			var obenStart = sucheKlammern( input, untenStart ) + 2; // ")^" = 2
			if( obenStart < 2 ) {	//0 (length of sucheKlammern) + 2 = 2
				addFehler( fehlerListenID, {
					nutzer: "fehlende schließende Klammer",
					debug: "replaceConstructs: fehlende schließende Klammer"} );
				return input;
			}
			var unten = input.slice( untenStart + 1, obenStart - 2 );   //lower bound
			var inhaltStart = sucheKlammern( input, obenStart ) + 1; // ")" = 1
			if( inhaltStart < 1 ) {	//0 + 1 = 1
				addFehler( fehlerListenID, {
					nutzer: "fehlende schließende Klammer",
					debug: "replaceConstructs: fehlende schließende Klammer"} );
				return input;
			}
			var oben = input.slice( obenStart + 1, inhaltStart - 1 );   //upper bound
			var inhaltEnde = inhaltStart;   //isn't determined yet

			var rumpf = input.slice( 0, treffer.index );	//everything in front of the construct
			var variable = "";  //control variable, differential for integrals ( without "(d(" and ")" )
			var rest = "";     //remaining part of the input string (after 'inhalt', including the differential (for integrals)

			if( typ == "int" ) {    //integral
				var dAuf,dZu;   //position of the brackets around the differential

				dAuf = findeAufKlammerEbene( input, "(d(", 0, inhaltStart );	//beginning of the differential

				inhaltEnde = dAuf - 1;

				if( ( dAuf >= input.length ) || ( dAuf < 0 ) ) {
					addFehler( fehlerListenID, {
						nutzer: "Differential fehlt",
						debug: "replaceConstructs: kein Differential" } );
					return input;
				}

				dZu = sucheKlammern( input, dAuf + 2 );	//first closing bracket of the differential "(d(...)<---"
				if( dZu < 0 ) {
					addFehler( fehlerListenID, {
						nutzer: "Differential hat kein Ende",
						debug: "replaceConstructs: Differential hat kein Ende" } );
					return input;
				}

				//get the variable ( of the differential )
				variable = input.slice( dAuf + 3, dZu );

				rest = input.slice( dZu + 2 );
			} else {    //no integral
				//get the control variable by splitting the lower bound
				var untenSplit = unten.split( '=' );
				variable = untenSplit.shift();	//remove first element of 'untenSplit' and store it inside 'variable'
				unten = untenSplit.join('=');	//put the remaining part of 'untenSplit' back together (important for nested constructs)

				//get content
				if( input[inhaltStart] == "(" ) {   //content enclosed in parenthesest?
					inhaltEnde = sucheKlammern( input, inhaltStart );
				} else {    //else content up to either "," (in vectors) or the end of the string
					inhaltEnde = findeAufKlammerEbene( input, ",", 0, inhaltStart );
					if( inhaltEnde < 0 ) {	//no comma found -> end of string
						inhaltEnde = input.length - 1;
					}
				}

				if( inhaltEnde < 0 ) {  //error handling
					addFehler( fehlerListenID, {
						nutzer: "Fehlerhafte Klammersetzung",
						debug: "replaceConstructs: Konstrukt wird nicht beendet" } );
					return input;
				}
				rest = input.slice( inhaltEnde + 1 );
			}

			var inhalt = input.slice( inhaltStart, inhaltEnde + 1 );

			//replace the variable by a keyword
			//( "(stuetzvariable_$variable)" ( replace $variable by the actual name of the variable )
			var variableEscaped = regexEscape( variable );  //escape special characters (for proper regex syntax)
			if( variableEscaped.length <= 0 ) { //check for empty variable to prevent infinite loop
				addFehler( fehlerListenID, {
					nutzer: "",
					debug: "replaceConstructs: Leere Variable" } );
				return input;
			}
			var rex = RegExp( "(^|[^a-zA-Z_])" + variableEscaped + "($|[^a-zA-Z])", "" );
			var lastInhalt;
			inhalt = replaceAllMatches( inhalt, rex, "$1(stuetzvariable_" + variableEscaped + ")$2" );

			//recursive call to process nested constructs
			var untenObjekt = replaceConstructs( unten, integrationsSchritte, fehlerListenID );
			var obenObjekt = replaceConstructs( oben, integrationsSchritte, fehlerListenID );
			var inhaltObjekt = replaceConstructs( inhalt, integrationsSchritte, fehlerListenID );
			var restObjekt = replaceConstructs( rest, integrationsSchritte, fehlerListenID );

			//create result object
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
	 * encloses constructs in the LaTeX string with curly braces to make subsequent parsing easier
	* */
	function encloseLatexConstructs( input, fehlerListenID ) {
		//regex for finding the beginning of constructs that aren't in curly braces yet
		var rex = RegExp( "(^|[^" + characterClassAuf + "]\\s*)\\\\(int|prod|sum)\\s*(\\^|_)", "" );

		//process all constructs
		var treffer = rex.exec( input );
		while( treffer != null ) {
			var typ = treffer[2]; //extract type from the second regex submatch (int, prod or sum)
			var startPos = treffer.index + treffer[1].length; //position of the '\' in front of typ

			//search end of the construct
			var ende = startPos
			if( typ == "int" ) {        //integral?
				//search for the differential
				var rest = input.slice( startPos );
				ende = findeAufKlammerEbene( rest, "{d{", 0 );
				if( ende < 0 ) {  //error handling
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

				ende += startPos;	//Mache ende zu Postion in input statt rest TODO: ??????
			} else {
				//search for the end of the third curly brace, comma or end of the string
				// "...\prod_{..}^{..}{...}..." or "...\prod_{..}^{..}....."
				//                        ^                                 ^

				//go to end of the lower bound
				var pos = findeAufKlammerEbene( input, "{", 0, startPos );
				pos = sucheKlammern( input, pos );
				//go to end of the upper bound ( beginning of content )
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

			var konstrukt = input.slice( startPos, ende + 1 );  //entire construct
			input = replaceByPos( input, startPos, ende + 1, "{" + konstrukt + "}" );   //enclose construct in curly braces

			treffer = rex.exec( input );
		}
		return input;
	}

	/*
	 * search for exponentiation in the LaTeX string and enclose
	 * them with curly braces to make it easier to display fractions
	 * later.
	 *
	 * the important part is the distinction between '^' as exponentiation operator
	 * and '^' as beginning of an upper bound
	 * */
	function encloseLatexPower( input, fehlerListenID ) {
		//TODO: less copy and paste
		//replace any number of whitespaces by only one whitespace (e.g "  " -> " ")
		input = input.replace( /\s+/g, " " );

		//process all " ^" in the input
		//IMPORTANT: All " ^" have to be replaced by "^" otherwise this is an infinite loop
		for( var hochPos = input.lastIndexOf( " ^" ); hochPos != -1; hochPos = input.lastIndexOf( " ^" ) ) {	//go through all " ^" from end to start
			var anfang = input.slice( 0, hochPos );
			var ende = input.slice( hochPos + 2 ); //" ^".length == 2

			//examine lefthand side
			var rexWert = RegExp( "(\\\\?[a-z]+|[0-9]+(\\.[0-9]+)?)!*$", "i" );   //number or variable (including '!' in case of factorial)
			var rexKlammer = RegExp( "[" + characterClassZu + "](!*)$", "" ); //closing bracket the the end (including '!' in case of factorial)
			var wertPos = anfang.search( rexWert );
			var klammerPos = anfang.search( rexKlammer );
			var basisAnfang;	//position of the beginning of the base of the exponentiation
			if( wertPos != -1 ) {	//simple expression in front of " ^"
				if( ( wertPos > 0 ) && ( anfang[wertPos - 1 ] == "_" ) ) {	//lower bound in front ( ==> no exponentiation )
					input = anfang + "^" + ende;
					break;
				}
				basisAnfang = wertPos;
			} else if( klammerPos != -1 ) {	//bracket expression in front of " ^"
				var treffer = rexKlammer.exec( anfang );
				klammerPos = treffer.index;
				klammerPos = sucheKlammern( anfang, klammerPos );	//jump to opening bracket
				if( klammerPos < 0 ) {
					addFehler( fehlerListenID, {
						nutzer: "Fehlende öffnende Klammer",
						debug: "encloseLatexPower: fehlende öffnende Klammer" } );
					return input;
				}

				//go on left up to the beginning of a function if there is any
				// ...5+\arcsin(.....)
				//      ^<----^
				for( klammerPos--; ( klammerPos >= 0 ) && /[a-z\\]/i.test( anfang[klammerPos] ); klammerPos-- ) {}
				if( (klammerPos >= 0) && (anfang[klammerPos] == "_") ) {	//lower bound in front ( ==> no exponentiation )
					input = anfang + "^" + ende;
					break;
				}
				klammerPos++;  //compensate last '--' of the loop

				basisAnfang = klammerPos;
			} else {
				addFehler( fehlerListenID, {
					nutzer: "Ungültige Basis in Potenz",
					debug: "encloseLatexPower: ungültige Basis in Potenz" } );
				return input;
			}

			//process righthand side
			rexWert = RegExp( "^(\\\\?[a-z]+|[0-9]+(\\.[0-9]+)?)", "i" );   //number or variable (without factorial)
			rexKlammer = RegExp( "^(\\\\?[a-z]+)?([" + characterClassAuf + "])", "i" ); //opening bracket or function
			var exponentEnde;
			if( rexKlammer.test( ende ) ) {	//bracket expression or function in the exponent
				exponentEnde = ende.search( RegExp( "[" + characterClassAuf + "]" ), "" );
				exponentEnde = sucheKlammern( ende, exponentEnde );
				if( exponentEnde < 0 ) {
					addFehler( fehlerListenID, {
						nutzer: "Fehlende schließende Klammer",
						debug: "encloseLatexPower: fehlende schließende Klammer"} );
					return input;
				}

				if( ( ende.length > exponentEnde + 2 ) && ( ende[exponentEnde + 2] == "_" ) ) {	//lower bound following ( ==> no exponentiation )
					input = anfang + "^" + ende;
					break;
				}
			} else if( rexWert.test( ende ) ) { //number or variable at the beginning
				var treffer = rexWert.exec( ende );
				exponentEnde = treffer[0].length;
				if( ( ende.length > exponentEnde + 2 ) && ( ende[exponentEnde + 2] == "_" ) ) { //lower bound following ( ==> no exponentiation )
					input = anfang + "^" + ende;
					break;
				}
			} else {
				addFehler( fehlerListenID, {
					nutzer: "Ungültiger Exponent",
					debug: "encloseLatexPower: ungültiger Exponent" } );
				return input;
			}

			//at this point it's clear that it really is an exponentiation
			//and not the bounds of a construct
			// ==> enclose entire expression in brackets

			//split input further
			var basis = anfang.slice( basisAnfang );
			var rumpf = anfang.slice( 0, basisAnfang );
			var exponent = ende.slice( 0, exponentEnde );
			var rest = ende.slice( exponentEnde );

			//put together againt
			input = rumpf + "{" + basis + "^" + exponent + "}" + rest;

		}

		return input;
	}

	/*
	 * Transform fractions in the input into LaTeX fractions
	 * of the form "\frac{..}{..}"
	 * */
	function latexFractions( input, fehlerListenID ) {
		//process all '/' in the input
		for( var slashPos = input.search( "/" ); slashPos != -1; slashPos = input.search( "/" ) ) {
			var anfang = input.slice( 0, slashPos );
			var ende = input.slice( slashPos + 1 );

			//process lefthand side
			var rexWert = RegExp( "(\\\\?[a-z]+|[0-9]+(\\.[0-9]+)?)!*$", "i" );   //number or variable ( including "!" in case of factorial )
			var rexKlammer = RegExp( "[" + characterClassZu + "](!*)$", "" ); //closing bracket at the end ( including "!" in case of factorial )
			if( rexWert.test( anfang ) )  {  //number or variable at the end of the string
				anfang = anfang.replace( rexWert, "{\\frac{$&}" );
			} else if( rexKlammer.test( anfang ) ) { //bracket expression in the numerator
				var treffer = rexKlammer.exec( anfang );
				var klammerZuPos = treffer.index;
				var pos = sucheKlammern( anfang, klammerZuPos );
				if( pos < 0 ) {
					addFehler( fehlerListenID, {
						nutzer: "Fehlende öffnende Klammer",
						debug: "latexFractions: fehlende öffnende Klammer"} );
					return input;
				}

				//continue going left up to the beginning of a function in front (if there is any)
				// ...5+\arcsin(.....)
				//      ^<----^
				for( pos--; ( pos >= 0 ) && /[a-z\\]/i.test( anfang[pos] ); pos-- ) {}
				pos++;  //compensate last '--' of the loop

				var zaehler = anfang.slice( pos );
				anfang = replaceByPos( anfang, pos, anfang.length, "{\\frac{" + zaehler + "}" );
			} else {
				addFehler( fehlerListenID, {
					nutzer: "Ungültiger Dividend",
					debug: "latexFractions: ungültiger Dividend" } );
				return input;
			}

			//process right hand side
			rexWert = RegExp( "^(\\\\?[a-z]+|[0-9]+(\\.[0-9]+)?)!*", "i" );   //number or variable ( including "!" in case of factorial )
			rexKlammer = RegExp( "^(\\\\?[a-z]+)?([" + characterClassAuf + "])", "i" ); //opening bracket or function at the beginning
			if( rexKlammer.test( ende ) ) { //bracket expression or function in the denominator
				var pos = ende.search( RegExp( "[" + characterClassAuf + "]", "" ) );
				pos = sucheKlammern( ende, pos );
				if( pos < 0 ) {
					addFehler( fehlerListenID, {
						nutzer: "Fehlende schließende Klammer",
						debug: "latexFractions: fehlende schließende Klammer"} );
					return input;
				}

				//take following '!' into account
				for(; ( ende.length > pos + 1 ) && ( ende[pos+1] == '!' ); pos++ ) {}

				var nenner = ende.slice( 0,  pos + 1 );
				ende = replaceByPos( ende, 0, pos + 1, "{" + nenner + "}}" );
			} else if( rexWert.test( ende ) ) {    //number or variable at the beginning of the string
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
	 * enclose functions in brackets
	 *
	 **/
	function encloseFunctions( input, klammer, fehlerListenID ) {
		var rex = RegExp( "([^" + characterClassAuf + "\\\\a-z]|^)([a-z]+)\\([^\\(]", "i" );

		var lastInput;
		do {
			lastInput = input;
			var treffer;
			do { //skip constructs so that they still can be parsed TODO: this might be obsolete, not quite sure
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

	/*
	 * check a string for missing closing brackets.
	 *
	 * returns true or false
	 **/
	function checkBrackets (input) {
		var stack = new Array();
		var abs = 0;

		for (var i = 0; i < input.length; i++) {
			if (input[i] === '|') {
				//skip '|' (absolute value function)
				abs++;
				continue;
			}
			//closing bracket?
			if (getArrayKey(klammernPaare, input[i]) !== undefined) {
				//does the closing bracket fit the opening bracket on top of the stack?
				if (stack.pop() != getArrayKey(klammernPaare, input[i])) {
					return false;
				}
			} else if (klammernPaare.hasOwnProperty(input[i])) { //opening bracket
				stack.push(input[i]);
			}
		}

		if ((stack.length == 0) && (abs % 2 == 0)) {
			return true;
		}

		return false;
	}

	/*
	 * Takes the input from the user and transforms it into a LaTeX string
	 * and a string that can be parsed by mathjs.
	 *
	 * This is achieved by going through the entire string mutliple times an replacing
	 * parts of it until the endresult ist complete.
	 *
	 * integrationsSchritte: number of steps when integrating
	 *
	 * This returns an object of the following form:
	 *  {
	 *     latex: "{\sum_{i=1}^{10}i}",
	 *     mathjs: "konstrukt(sum,i,1,10,(stuetzvariable_i),100)"
	 *     fehlerListe: array containing every error that occured. If it isn't empty, the output shouldn't be used.
	 *  }
	 *  example: "sum_(i=0)^(10)i"
	 * */
	mparser.convertMathInput = function(input, integrationsSchritte ) {
		//default value for integrationsSchritte
		integrationsSchritte = typeof integrationsSchritte !== 'undefined' ? integrationsSchritte : 1000;

		//remove "\" from input
		input = input.replace( RegExp( "\\\\", "g" ), "" );

		//create object with return values
		var result = {
			latex: input,   //latex string for displaying with mathjax
			mathjs: input   //string for parsing with mathjs
		};

		/*
		* An array with entries of the form:
		*  {
		*      nutzer: "Error message to display to the user",
		*      debug:   "Debugging message"
		*  }
		* */
		var fehlerListenID = globalMap.add( new Array() );


		//perform simple replacementes (without bracket expressions)
		result.latex = simpleReplace( result.latex, "latex", fehlerListenID );
		result.mathjs = simpleReplace( result.mathjs, "mathjs", fehlerListenID );

		//process bracket epxressions
		result.latex = bracketReplace( result.latex, "latex", fehlerListenID );
		result.mathjs = bracketReplace( result.mathjs, "mathjs", fehlerListenID );

		//enclose functions with curly braces
		result.latex = encloseFunctions( result.latex, "{", fehlerListenID );
		result.mathjs = encloseFunctions( result.mathjs, "(", fehlerListenID );

		//enclose bounds/exponents in brackets
		//_74.3 -> _{74.3}, ^\alpha -> ^{\alpha} ...
		var rex = RegExp( "(_|\\^)(-?\\\\?[a-z]+|-?[0-9]+(?:\\.[0-9]+)?)", "gi" );
		result.latex = result.latex.replace( rex, " $1{$2}" );
		result.mathjs = result.mathjs.replace( rex, "$1($2)" );

		//enclose negative numbers in brackets to ease parsing
		rex = RegExp( "([+\\-*/]|^)(-\\\\?[a-z]+|-[0-9]+(?:\\.[0-9]+)?)([^a-z" + regexEscape( characterClassAuf ) +  "]|$)", "gi" );
		result.latex = replaceAllMatches( result.latex, rex, "$1{$2}$3" );

		//replace differentials in the LaTeX string with '{d{..}}'
		result.latex = preprocessDifferentials( result.latex, '{', fehlerListenID )
		//enclose constucts in brackets to prepare for fractions
		result.latex = encloseLatexConstructs( result.latex, fehlerListenID );
		//enclose exponentiation in brackets to prepare for fractions
		result.latex = encloseLatexPower( result.latex, fehlerListenID );
		//create LaTeX fractions
		result.latex = latexFractions( result.latex, fehlerListenID );

		//'(value)!' -> 'value!' in LaTeX
		rex = RegExp( "(\\()(\\\\?[a-z]+|[0-9]+(\\.[0-9]+)?)(\\))!", "gi" );    //numbers or variables in brackest with factorial
		result.latex = result.latex.replace( rex, "$2!" );


		//postprocess mathjs string
		rex = RegExp( "[{]", "g" );  //opening bracktes
		result.mathjs = result.mathjs.replace( rex, "(" );
		rex = RegExp( "[}]", "g" );  //closing brackets
		result.mathjs = result.mathjs.replace( rex, ")" );
		//replace differentials (IMPORTANT: This needs to be done after replacing brackets and before removing whitespaces)
		result.mathjs = preprocessDifferentials( result.mathjs, '(', fehlerListenID );
		rex = RegExp( "\\s+", "g" );      //whitespaces
		result.mathjs = result.mathjs.replace( rex, "" );

		//swap upper and lower bounds if necessary
		result.mathjs = swapBoundaries( result.mathjs, fehlerListenID );

		//process constructs ( prod, int, sum )
		var temp = replaceConstructs( result.mathjs, integrationsSchritte, fehlerListenID );
		result.mathjs = temp.mathjs;

		//replace brackets in the LaTeX string with '\left' and '\right'
		//in the first step every '\left' and '\right' get removed
		//because I couldn't find a simple regex that does this in one step
		rex = RegExp( "(\\\\left|\\\\right)(\\(|\\))", "g");
		result.latex = result.latex.replace( rex, "$2");
		result.latex = result.latex.replace( /\(/g, "\\left(" );
		result.latex = result.latex.replace( /\)/g, "\\right)" );

		//add fehlerListe to the return object and remove from globalMap TODO: replace global map by passing an object from the local scope
		result.fehlerListe = globalMap.get( fehlerListenID );
		globalMap.remove( fehlerListenID );

		//remove '\left' and '\richt' from the LaTeX string
		//if the brackets aren't complete (necessary for the preview)
		if (!checkBrackets(result.latex)) {
			result.latex = result.latex.replace(/\\left\(/g, '(');
			result.latex = result.latex.replace(/\\right\)/g, ')');
		}

		logMessage(VERBOSEINFO, "convertMathinput Rückgabeobjekt: " + JSON.stringify(result));

		return result;
	};

	/*
	 * Evaluate an expression with a set of different values for given variables.
	 * Returns an array of results.
	 *
	 * expression: expresion to evaluate (string)
	 *
	 * variables: object mapping variable names to values
	 *  e.g.:
	 *  var variables = {
	 *      x: [ 1, 2, 3, 4 ],
	 *      y: [ 5, 6, 7, 8 ]
	 *  };
	 *
	 * I there is no 'variables' array then the expression get's evaluated without them!
	 *
	 * !Notice: this function uses the number of values of an arbitratry variable
	 * to determine the number of values. This can lead to undefined behaviour if
	 * different variables have a different number of values.
	 * */
	mparser.evalMathJS = function( expression, variables ) {
		//parse and compile the expression
		var code = mathJS.compile( expression );

		//if 'variables' isn't set, evaluate as is
		if( (typeof variables) == "undefined" ) {
			return code.eval();
		}

		//determine number of values
		var anzahl = variables[Object.keys(variables)[0]].length;   //length of the first array in 'variables'

		var results = []; //array to put the results of the evaluation into

		//evaluate the expression for every value
		for( var i = 0; i < anzahl; i++ ) {
			var scope = {};
			//add all variables to the scope
			jQuery.each( variables,
				function ( property, value ) {
					scope[property] = value[i]; //add i-th value of the variable to the scope
				}
			);

			results[i] = code.eval( scope );
		}
		return results;
	};

	/*
	 * Gets a set of linear equations in form of a coefficient matrix, a vector of the
	 * right side of the set of equations and an input from the user which will
	 * be checked if it solves the set of equations.
	 *
	 * parameters:
	 * coefficientMatrix: array of strings that contain the columns of the coefficient matrix
	 *          ["(1,2,3)", "(4,5,6)", "(7,8,9)"]
	 * rightHandSide: string containing the vector of the right side of the set of equations
	 * userSolution: string with an array of the proposed solution by the user
	 * accuracy: at least this number of digits has to match
	 *
	 * return value is true in case of a correct solution, false otherwise.
	 * */
	mparser.checkSetOfLinearEquations = function( coefficientMatrix, rightHandSide, userSolution, accuracy ) {
		//default value for accuracy
		accuracy = typeof accuracy !== 'undefined' ? accuracy : 3;

		//create coefficient matrix from it's columns
		var matrix = "["; //coefficient matrix in mathjs notation as a string TODO: use Array.prototype.join for this
		coefficientMatrix.forEach(
			function( input ) {
				var returnObject = mparser.convertMathInput( input );
				if( returnObject.fehlerListe.length != 0 ) {
					throw "FEHLER: Parsen der Koeffizientenmatrix fehlgeschlagen";
				}
				matrix += returnObject.mathjs + ',';	//add column to matrix
			}
		);
		//replace last comma with a closing bracket TODO: this is unnecessary when using Array.prototype.join
		matrix = matrix.replace( /,$/, "]" );

		//process proposed solution by the user
		var returnObject = mparser.convertMathInput( userSolution );
		if( returnObject.fehlerListe.length != 0 ) {
			throw "FEHLER: Parsen der vom Nutzer eingegebenen Lösung fehlgeschlagen";
		}
		userSolution = returnObject.mathjs;

		//prepare righthand side of the set of equations
		var returnObject = mparser.convertMathInput( rightHandSide );
		if( returnObject.fehlerListe.length != 0 ) {
			throw "FEHLER: Parsen der rechten Seite des Gleichungssystems fehlgeschlagen";
		}
		rightHandSide = returnObject.mathjs;

		//convert to mathjs datatypes
		var mathjsKoeffMatrix;
		var mathjsRightHandSide;
		var mathjsUserSolution;
		mathjsKoeffMatrix = mathJS.matrix( mathJS.transpose( mathJS.eval( matrix ) ) );
		mathjsRightHandSide = mathJS.matrix(  mathJS.eval( rightHandSide ) );
		mathjsUserSolution = mathJS.matrix( mathJS.eval( userSolution ) );

		//apply proposed solution of the user
		var mathjsUserRightHandSide = mathJS.multiply( mathjsKoeffMatrix, mathjsUserSolution );

		//calculate the difference
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

	//this return object defines the public interface
	return mparser;
})(); //end of the closure

