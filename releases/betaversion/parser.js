// @todo: checkgroup, displaymath und handlerchange updaten, objektlokalisiert am besten
// encoding: latin1


var red = "#FF0066"; 
var green = "#33FF33";
var fctname = ["EXP","LN","ABS","ACOS","ASIN","ATAN","COS","SQRT","TAN","SIN"];      // zuerst asin, dann sin , etc.
var nameRep = ["EXP","LN","ABS","ACO#","ASI#","ATA#","COS","SQRT","TAN","SIN"];


// ********* Vergleich von numerischen Werten ******************************
function numericalCheck(eingabe,ausgabe,wert,stellen,nbKlapp)
{
    var ergebnis,ein;
       
    wert = wert.replace(/,/,".");
    ergebnis = doParse(eingabe,ausgabe);
    if(ausgabe=="") ausgabe = eingabe;
    if(Math.abs(extround(ergebnis,stellen)-extround(wert,stellen)) <= Math.pow(10,(stellen+2)*(-1)))
    {
        document.getElementById(ausgabe).style.backgroundColor = green;
    } else
    {
        document.getElementById(ausgabe).style.backgroundColor = red;
    }   
    if(document.getElementById("da"+nbKlapp).style.visibility == 'hidden')
    {
     document.getElementById("da"+nbKlapp).style.visibility = 'visible';
     document.getElementById("da"+nbKlapp).style.display = 'inline';   
    }
                                                        
}

// *********** Runden mit Stellengenauigkeit **********************************

function extround(zahl,n_stelle) 
{
    var i;
    i = Math.pow(10,n_stelle);
    zahl = (Math.round(zahl * i) / i);
    return zahl;
}


// ********* Checker für Eingabe bei Input-Felder, ob numerisch sinnvolle Zeichen angegeben wurden ****************************

function numericalInputChecker(eingabe)
{
    var ein,s; //string
    
    ein = document.getElementById(eingabe).value;
    ein = ein.replace(/,/,".");
    if(isNaN(ein))
    {
      ein = ein.replace(/a/gi,"");         // ersetzen aller nichtnumerischen Zeichen. Besser als nur letztes zu ersetzen, falls Prüfaufruf zu langsam
      ein = ein.replace(/b/gi,"");
      ein = ein.replace(/c/gi,"");
      ein = ein.replace(/d/gi,"");
      ein = ein.replace(/f/gi,"");
      ein = ein.replace(/g/gi,"");
      ein = ein.replace(/h/gi,"");
      ein = ein.replace(/i/gi,"");
      ein = ein.replace(/j/gi,"");
      ein = ein.replace(/k/gi,"");
      ein = ein.replace(/l/gi,"");
      ein = ein.replace(/m/gi,"");  
      ein = ein.replace(/n/gi,"");
      ein = ein.replace(/o/gi,"");
      ein = ein.replace(/p/gi,"");
      ein = ein.replace(/q/gi,""); 
      ein = ein.replace(/r/gi,"");
      ein = ein.replace(/s/gi,"");
      ein = ein.replace(/t/gi,"");
      ein = ein.replace(/u/gi,"");   
      ein = ein.replace(/v/gi,"");
      ein = ein.replace(/w/gi,"");
      ein = ein.replace(/x/gi,"");
      ein = ein.replace(/y/gi,"");      
      ein = ein.replace(/z/gi,"");
      ein = ein.replace(/#/g,"");
      ein = ein.replace(/'/g,"");
      ein = ein.replace(/ä/g,"");
      ein = ein.replace(/ü/g,"");
      ein = ein.replace(/ö/g,"");
      ein = ein.replace(/"/g,"");               
      ein = ein.replace(/§/g,"");
      ein = ein.replace(/$/g,"");
      ein = ein.replace(/\%/g,"");
      ein = ein.replace(/&/g,"");
      ein = ein.replace(/\=/g,"");
      ein = ein.replace(/\?/g,"");
      ein = ein.replace(/´/g,"");
      ein = ein.replace(/^/g,"");                 
      ein = ein.replace(/°/g,"");
      ein = ein.replace(/\t/g,"");
      ein = ein.replace(/\</g,"");
      ein = ein.replace(/\>/g,"");         
      ein = ein.replace(/_/g,"");
      ein = ein.replace(/:/g,"");
      ein = ein.replace(/;/g,"");
      ein = ein.replace(/\~/g,"");
      ein = ein.replace(/}/g,"");
      ein = ein.replace(/\{/g,""); 
      ein = ein.replace(/\\/g,"");
      ein = ein.replace(/²/g,"");
      ein = ein.replace(/³/g,"");
      ein = ein.replace(/µ/g,"");
      ein = ein.replace(/|/g,"");
      ein = ein.replace(/€/g,"");   
      ein = ein.replace(/,/g,"");
      
      ein = ein.replace(/\./,",");
      ein = ein.replace(/\./g,"");                   
    }
    ein = ein.replace(/\./,",");
    document.getElementById(eingabe).value = ein;
}








//********* Funktionsparser *************************************************************************


// Hauptfunktion für den Aufruf zum Parsen einer Funktion  ; eingabe = FeldId mit der Eingabe; ausgabe = FeldId für die Ausgabe, leerer String heißt nicht ausgeben. Funktion liefert immer das Ergebnis auch als result zurück.
function doParse(eingabe,ausgabe)
{
    var d=document;
    var s = d.getElementById(eingabe).value;
    s = applyMVARValues(s);
    var t = pureParse(s);
    ausgabe.value = t;
    return t;
}

// Elementare Funktion mit Strings als Ein- und Ausgabe
function pureParse(eingabe)
{
        var result;
        var a,b;
        var pi = Math.PI; // 
        var sh; // string
       
        i = 0;
        a = 0;
        b = 0;      
	eingabe = eingabe.replace(/,/,".");           // Punkt-Komma-Problem beseitigen    
    
        eingabe = eingabe.replace(/\[/gi,"(");        // Klammern () und [] gleichsetzen
        eingabe = eingabe.replace(/]/gi,")");
        

        eingabe = eingabe.toUpperCase();               // Großschreibung

        
        // Konstanten ersetzen und E+00 und E-00 zu E00 bzw. E~00
        eingabe = eingabe.replace(/PI/gi,pi.toString());
        eingabe = eingabe.replace(/eu/gi,Math.E.toString());
        
        eingabe = eingabe.replace(/E\+/gi,"E");
        eingabe = eingabe.replace(/E-/gi,"E~");
        eingabe = eingabe.replace(/ /gi,"");
        
        
        

    if(checkFunction(eingabe) == 0)
        {
        if(eingabe.substring(0,1) == "-" || eingabe.substr(0,1) == "+")
                {
                        result =  parseFunction("0"+eingabe);
                } else
                {
                        result = parseFunction(eingabe);
                }   
                sh = "Es sind folgende Fehler bei der Eingabe aufgetreten:\n\n - Überprüfen Sie die Eingabe nach ungültigen Zeichen oder Formulierungen.";
        if(isNaN(result)) {result = "keine gültige Eingabe"; /*alert(sh);*/}
    }  
        return result;
}


function checkFunction(str)
{
  var i,a,b,result,res,j; // int 
  var sh; // string
  
  a = 0;
  b = 0;
  result = 0;
  i = 0;
 
  if(str == "") result = -1;
 
  while(i<str.length) // Klammern prüfen
  {
    if(str.substring(i,i+1) == "(") a++;
    if(str.substring(i,i+1) == ")") b++;
    i++;

  }
  if(a!=b)
  {
      if(result<1) result = result + 1;
      //alert("Überprüfen Sie die Klammern")
  }
 
 
  if(str.substr(0,1) =="*" || str.substr(0,1) == "/")    // Anfangsoperator prüfen
  {
           if(result<2) result = result + 2;
           // alert("Formel beginnt mit einem unzulässigen Operator")
  }
   
  for(i=0;i<fctname.length;i++)
  {
    sh = str; 
    while(sh.indexOf(fctname[i])>-1)
    { 
        j = sh.indexOf(fctname[i]);
        sh = sh.substring(j+fctname[i].length,sh.length)
        if(sh.substring(0,1) != "(")
        {
            if(result<4) result = result + 4;
        }
    }
  }
  
  sh = "Es sind folgende Fehler bei der Eingabe aufgetreten:\n\n";
  res = result;
  if(res >3) {res = res-4; sh = sh+"- Funktionsaufrufe sind mit einer Klammer zu versehen, z.B. exp(2)\n"; }
  if(res >1) {res = res-2; sh = sh+"- Formel beginnt mit einem unzulässigen Operator, z.B. *\n"; }
  if(res >0) {res = res-1; sh = sh+"- Überprüfen Sie die Klammern"; }
  
  //if(result>0) alert(sh);
  // if(result == -1) alert("Bitte machen Sie eine Eingabe.");

  return result;
    
}



function parseFunction(str)
{
                var sh,s,sout,srep;  //string
                var i,j,a,b,k,n;    //int
                var result,res;   //double
                
                var error;     //boolean
                
                error = false;
                
                result = "Fehler";
                
        
        


                
                //Klammern um Funktionen setzen !!      --> Exp(x) wird zu (Exp(x)), dient der Abarbeitung
                
                
                for(k=0;k<fctname.length;k++)              // aus acos wird aco#, damit beim Ersetzen von cos zu (cos nicht a(cos passiert 
                {
            srep = eval("/"+fctname[k]+"/gi");  
            str = str.replace(srep,nameRep[k]);    
        }
                
                for(k=0;k<fctname.length;k++)
                {
          srep = eval("/"+nameRep[k]+"/gi");
          
                  str = str.replace(srep,"("+nameRep[k]);
                  sh = str;
                  s = str;
                  str = "";
                  while(sh.indexOf("("+nameRep[k])>-1)
                  {
                        i = sh.indexOf("("+nameRep[k]);

                        str = str+sh.substring(0,i+5);
                        s = sh.substring(i+5,sh.length);
                        a = 1;
                        b = 0;
                        i = 0;
                        while(a>b && i <s.length)
                        {
                                if(s.substring(i,i+1) == "(") a++;
                                //if(s.substring(i,i+1) == ")") a--;
                                if(s.substring(i,i+1)  == ")") b++;
                                i++;
                                //System.err.println(i+","+a);
                        }
                    s = s.substring(0,i)+ ")"+s.substring(i);
                    sh = s;
                  }
                  str = str+s;
        }               
                
        for(k=0;k<fctname.length;k++)              //  Rückgängig: aus acos wird aco#, damit beim Ersetzen von cos zu (cos nicht a(cos passiert
                {
            srep = eval("/"+nameRep[k]+"/gi");
            str = str.replace(srep, fctname[k]);
        }
        
                        
         
//     alert("0:  "+str);
        str = parseKlammer(str);
//      alert("1:  "+str);      
                str = parsePotenz(str); 
//          alert("2:  "+str);
                str = parsePunktStrich(str);
//      alert("3:  "+str);
                str = parseExpressions(str);
//              alert(str);
                result = parseTranslatedFunction(str);
                result = result.replace(/E~/gi,"E-");
            return result;
}


function parsePotenz(str)
{
        var i,j,k,vze; // int
    var a,b,res; // double
        var se,sb;  // String:  se:Exponent, sb: Basis
                
        str = str.replace(/E-/gi, "E~"); 
    k = str.lastIndexOf("^");
        while(k>-1 && !str== "")
        {
                se = str.substring(k+1,str.length);
                vze = 0;
           
                if(str.substring(k+1,k+2)=="-") 
        {
            vze = 1;
            se = se.substring(1,se.length);
                
        }
                i = se.length;
                if(se.indexOf("+") < i && se.indexOf("+")>(-1)) {i = se.indexOf("+"); j = 0;};
                if(se.indexOf("-") < i && se.indexOf("-")>(-1)) {i = se.indexOf("-"); j = 1;};
                if(se.indexOf("*") < i && se.indexOf("*")>(-1)) {i = se.indexOf("*"); j = 2;};
                if(se.indexOf("/") < i && se.indexOf("/")>(-1)) {i = se.indexOf("/"); j = 3;};
                if(se.indexOf("^") < i && se.indexOf("^")>(-1)) {i = se.indexOf("^"); j = 4;};
                se = se.substring(0,i); 
                if(isNaN(se)) se = "NaN";
                if(se=="") se= "NaN";
                        
                sb = str.substring(0,k);
                j = -1;
                if(sb.lastIndexOf("+") > j) {j = sb.lastIndexOf("+");};
                if(sb.lastIndexOf("-") > j ) {j = sb.lastIndexOf("-"); };
                if(sb.lastIndexOf("*") > j ) {j = sb.lastIndexOf("*"); };
                if(sb.lastIndexOf("/") > j ) {j = sb.lastIndexOf("/");};
                if(sb.lastIndexOf("^") > j ) {j = sb.lastIndexOf("^");};
                
                sb = sb.substring(j+1,sb.length);
                sb = sb.replace("E~", "E-");
                se = se.replace("E~", "E-");
                sb = sb.replace(/~/gi, "-"); 
                a = sb*1.0;  // Typumwandlung
                b = se*1.0;    // Typumwandlung
                res = Math.pow(a,b);
                if(vze == 1) res = 1.0/res;
                str = str.substring(0,j+1)+res.toString()+str.substring(k+se.length+1+vze,str.length);
                k = str.lastIndexOf("^");
        }       
//      alert(str);
        return str;
}


function parseTranslatedFunction(str)  // nur + und -
{
                var result,res;       //double
                var s,st;              //string
                var i,j,k;              //int
                
      
                str = str.replace(/E-/gi, "E~");
                str = str.replace(/~/gi, "-"); 
                //alert(str);
                if(str.substring(0,1) == "-" || str.substring(0,1) == "+")
                {
                        str = "0"+str;
                }
                
        
                result = "Fehler";
                
                i = str.length+1;
                j = -1;
                if(str.indexOf("+")<i && str.indexOf("+")>0) {i = str.indexOf("+"); j = 0;}
                if(str.indexOf("-")<i && str.indexOf("-")>0) {i = str.indexOf("-"); j= 1;}
        k = str.length;
                
                
                s = str.substring(0,i);
                s = s.replace(/E~/gi,"E-");
                result = s.toExponential;       // Zahl umwandeln
                //alert("test:"+s);
                result = s*1.0;    //Zahl umwandeln
                str = str.substring(i);
                //alert(result);
        while(j>-1)
                {
          
            str = str.replace(/E-/gi,"E~");
                        st = str.substring(1,str.length);
                //      alert(st);

                        if(str.indexOf("+")==0) j = 0;
                        if(str.indexOf("-")==0) j = 1;
                        
                        i = st.length;
                        if(st.indexOf("+")<i && st.indexOf("+")>-1) i = st.indexOf("+");
                        if(st.indexOf("-")<i && st.indexOf("-")>-1) i = st.indexOf("-");
            st = st.substring(0,i);
           // alert("st;"+st);
                        st = st.replace("E~","E-");
                //      alert("s:"+st);
                    if(isNaN(st)) st = "NaN";
                    if(st=="") st= "NaN";
                        res = st*1.0;  //zahl umwandeln         
                        if(j==1) result = result - res;
                        if(j==0) result = result + res;

                
                        str = str.substring(i+1,str.length);   
                        j = -1;
                        if(str.indexOf("+")==0) j = 0;
                        if(str.indexOf("-")==0) j = 1;
            
                //      alert("str"+str);
                }
        str = str.replace("E~","E-");
        str = result.toString();        
                return str;
                
}
        
    
function parseKlammer(str)
        {
                var i,j,k,a,b; //int
                var sh;   // string
                var res;  // double
                
          // alert(str);        
                while(str.indexOf("(")>-1)
                {
                        i = str.indexOf("(")+1;
                        a = 1;
                        b = 0;
                        j = i-1;
                        k = str.length;
                        while(b==0 && i<str.length && i>-1)
                        {
                                if(str.substring(i,i+1)=="(") {a++; j = i;}
                                if(str.substring(i,i+1)==")") {b++; k = i;}
                                i++;
                        }
                        
                        sh =str.substring(j+1,k);
                        sh = sh.replace(/E-/gi,"E~");
                        //alert(sh);
                        sh = parsePotenz(sh);
                        sh = parsePunktStrich(sh);
                        sh = parseExpressions(sh);
                        res = parseTranslatedFunction(sh);
                        sh = res.toString();
                        if(sh.indexOf("-") == 0) sh = sh.replace(/-/,"~");
                        if(k<str.length) 
                        {
                                sh =sh+str.substring(k+1);
                        }
                        if(j>0) 
                        {
                                str = str.substring(0,j) + sh;
                        } else
                        {
                                str = sh;
                        }
                //      alert(str);             
                }
                return str;
                
        }       
        
        
        
        
        
function parseExpressions(eStr)
{

        var res,a; // double
        var s; // string
        var e = Math.E, pi = Math.PI;     //double              
                //long p = 3141592653589793;
        var i,j,k,n;     //int                                               
                
        eStr = eStr.replace(/"E-"/gi, "E~");
        //alert(eStr);
    eStr = eStr.replace(/~/gi, "-"); 

        
    for(n=0;n<fctname.length;n++)
    {
       i = eStr.lastIndexOf(fctname[n]);
           while(i>-1)
           {
                  s = eStr.substring(i+fctname[n].length,eStr.length);
                  j = s.length;
                  if(s.indexOf("+") < j && s.indexOf("+")>(0)) {j = s.indexOf("+"); };
                  if(s.indexOf("-") < j && s.indexOf("-")>(0)) {j = s.indexOf("-"); };
                  if(s.indexOf("*") < j && s.indexOf("*")>(-1)) {j = s.indexOf("*"); };
                  if(s.indexOf("/") < j && s.indexOf("/")>(-1)) {j = s.indexOf("/"); };

                  s = s.substring(0,j);

                  s = s.replace("E~","E-");
                  if(s=="")
          {
              s = "NaN";
              // alert("fehlendes oder falsches Argument")
          }
                  res = s*1.0; // Umwandlung s nach Zahl
                  if(isNaN(res))
          {
             res = Number.NaN;
          } else
          {
            switch(n)                 // ["EXP","LN","SIN","ABS","ACOS","ASIN","ATAN","COS","SQRT","TAN"];
            {
                case 0: 
                    res = Math.pow(e, res);
                break;
                
                case 1:
                    res = Math.log(res); 
                break;
                            
                case 2:
                    res = Math.abs(res);
                break;
                
                case 3:
                    res = Math.acos(res);
                break;
                
                case 4:
                    res = Math.asin(res);
                break;
                
                case 5:
                    res = Math.atan(res);
                break;
                
                case 6:
                    res = Math.cos(res);
                break;
                
                case 7:
                    res = Math.sqrt(res);
                break;
                
                case 8:
                    res = Math.tan(res);
                break;
                
                case 9:
                    res = Math.sin(res);
                break;
                
                default:
                    // alert("Funktion nicht gefunden");     
            }
          }
                  eStr = eStr.substring(0,i)+res.toString();  // Umwandlung res to String
                  i= eStr.lastIndexOf(fctname[n]);
            }
    }                        
        return eStr; 

}


function parsePunktStrich(str)
        {
                var i,j,k; // int
                var a,b,res; // double
                var se,sb;  // String:  se:nach *, sb: vor *     bzw. se: nach /; sb: vor *
                var invert;
                
                
                str = str.replace(/~/gi, "-"); 
                // Umdrehen der Brüche

                k = str.lastIndexOf("/");
                while(k>-1 && str != "")
                {
                        invert = false;
                        se = str.substring(k+1,str.length);
                        i = se.length;
                        if(se.indexOf("+") < i && se.indexOf("+")>(0)) {i = se.indexOf("+"); };
                        if(se.indexOf("-") < i && se.indexOf("-")>(0)) {i = se.indexOf("-"); };
                        if(se.indexOf("*") < i && se.indexOf("*")>(-1)) {i = se.indexOf("*"); };
                        if(se.indexOf("/") < i && se.indexOf("/")>(-1)) {i = se.indexOf("/");};

                        se = se.substring(0,i);


                        sb = str.substring(0,k);
                        j = -1;
                        if(sb.lastIndexOf("+") > j) {j = sb.lastIndexOf("+");};
                        if(sb.lastIndexOf("-") > j ) {j = sb.lastIndexOf("-"); };
                        if(sb.lastIndexOf("*") > j ) {j = sb.lastIndexOf("*"); };
                        if(sb.lastIndexOf("/") > j ) {j = sb.lastIndexOf("/"); invert= true;};
                        sb = sb.substring(j+1,sb.length);

                        sb = sb.replace("E~","E-");
                        se = se.replace("E~","E-");

                        a = sb*1.0;
                        b = se*1.0;
                        res = a/b;
                        if(invert) res = a*b;
                        str = str.substring(0,j+1)+res.toString()+str.substring(k+se.length+1,str.length);
                        k = str.lastIndexOf("/");
                        //System.err.println("str:"+str);
                }


            // Multiplikation   
        
                k = str.lastIndexOf("*");

                while(k>-1 && str!="")
                {       
            str = str.replace(/E-/gi, "E~");
                        se = str.substring(k+1,str.length);
                        i = se.length;
                        if(se.indexOf("+") < i && se.indexOf("+")>(0)) {i = se.indexOf("+"); j = 0;};
                        if(se.indexOf("-") < i && se.indexOf("-")>(0)) {i = se.indexOf("-"); j = 1;};
                        if(se.indexOf("*") < i && se.indexOf("*")>(-1)) {i = se.indexOf("*"); j = 2;};
                        if(se.indexOf("/") < i && se.indexOf("/")>(-1)) {i = se.indexOf("/"); j = 3;};
                        
            se = se.replace("E~","E-");
                        se = se.substring(0,i);
                        
                        if(isNaN(se)) se = "NaN";
                    if(se=="") se= "NaN";
                        
                        sb = str.substring(0,k);
                        j = -1;
                        if(sb.lastIndexOf("+") > j) {j = sb.lastIndexOf("+");};
                        if(sb.lastIndexOf("-") > j ) {j = sb.lastIndexOf("-"); };
                        if(sb.lastIndexOf("*") > j ) {j = sb.lastIndexOf("*"); };
                        if(sb.lastIndexOf("/") > j ) {j = sb.lastIndexOf("/");};
                        sb = sb.substring(j+1);
                        
                        sb = sb.replace("E~","E-");

                        
                        a = sb*1.0;
                        b = se*1.0;
                        res = a*b;
                        str = str.substring(0,j+1)+res.toString()+str.substring(k+se.length+1,str.length);
                //      alert(str);
                        k = str.lastIndexOf("*");
                        //System.err.println("str:"+str);
                }
                
                
                
                return str;
        }


// Konstruiert einen String, der nicht Teilstring von ausdruck ist
function findDummy(ausdruck) {
  bs = "MT";
  rex = new RegExp(bs,'gi');
  while(ausdruck.search(rex) != -1) {
    bs = bs + "X";
    rex = new RegExp(bs,'gi');
  }
  return bs;
}


// Ersetzt die im Parser verwendeten Funktionsnamen durch Potenzen von bs
// Es wird angenommen, dass bs nicht im ausdruck vorkommt!
function pushFunctions(ausdruck,bs) {
  var result;
  
  result = ausdruck;

  for (i=0;i<fctname.length;i++) {
    rex = new RegExp(fctname[i],'gi');
    s = "";
    for (j=0;j<=i;j++) s = s + bs;
    result = result.replace(rex,s);
  }
  
  return result;
}

// Macht pushFunctions wieder rueckgaengig
function popFunctions(ausdruck,bs) {
  var result;
  
  result = ausdruck;

  for (i=fctname.length-1;i>=0;i--) {
    s = "";
    for (j=0;j<=i;j++) s = s + bs;
    rex = new RegExp(s,'g');
    result = result.replace(rex,fctname[i]);
  }
  
  return result;
}

// Wertet eine Funktion in der Variablen v an einer Stelle x aus (case-insensitive)
// Funktioniert auch, wenn v ein Teilstring eines Funktionsnamens ist!
function evaluateFunction(ausdruck, v, x) {

    ausdruck = applyMVARValues(ausdruck);

  var bs = findDummy(ausdruck+x);
  var result = ausdruck;
 
  var y;
  if (x<0) y = "(0"+x+")"; else y = "("+x+")";
  
  result = pushFunctions(result,bs);
  var rex = new RegExp(v,'gi');
  result = result.replace(rex,y);
  result = popFunctions(result,bs);
//  var r = result;
  result = pureParse(result);
//  alert("PureParse: " + r + "  -->  " + result);
  return result;
}


//---------------------------- Baumology ---------------------------------------------

// Operationen werden als Objekte im Array verwahrt, die entsprechende Patterns matchen
// und zugehörige Auswertungen und LaTeX-Ausdrücke rekursiv liefern
// Stelligkeit in Komponente arity: 0 (Konstante), 1 (Funktion) , 2 (nur binär), 3 (2 oder mehr Operanden)
// Operatorkennung: symb (nicht case-sensitive), Textstring der in Ausdruck gematcht wird
// evaluate: Auswertungsfunktion welche ein Array aus durch arity bestimmten Stelligkeiten bekommt und Zahlenwert liefert
// latex: Auswertungsfunktion, welche ein Array aus LaTeX-Ausdrücken bekommt analog zur evaluate-Funktion
// notation: 0 = prefix, 1 = infix, 2 = postfix
// preference: niederiger Wert hat Preferenz vor hohem Wert

var BOperations;

function setupBOperations() {
  var op = null;
  BOperations = new Array();
  
  // Konstanten
  op = { preference: 1, notation: 0, arity: 0, symb: "pi", evaluate: function(args) { return 3.14; }, latex: function(args) { return "\\pi";} };
  BOperations.push(op);

  // Funktionen
  op = { preference: 2, notation: 0, arity: 1, symb: "exp", evaluate: function(args) { return Math.exp(args[0]); }, latex: function(args) { return "\\exp\\left({" + args[0] + "}\\right)";} };
  BOperations.push(op);
  op = { preference: 2, notation: 0, arity: 1, symb: "sin", evaluate: function(args) { return Math.sin(args[0]); }, latex: function(args) { return "\\sin\\left({" + args[0] + "}\\right)";} };
  BOperations.push(op);
  op = { preference: 3, notation: 2, arity: 1, symb: "!", evaluate: function(args) { return 0; }, latex: function(args) { return args[0] + "!";} };
  BOperations.push(op);

  // Binaere Operationen
  op = { preference: 4, notation: 1, arity: 2, symb: "^", evaluate: function(args) { return Math.pow(args[0],args[1]); }, latex: function(args) { return "{" + args[0] + "}^{" + args[1] + "}"; } };
  BOperations.push(op);

  // Mindestens zweistellige infix-Operationen
  op = { preference: 5, notation: 1, arity: 3, symb: "*", evaluate: function(args) { var i; var v = 1; for (i=0; i<args.length; i++) v = v *= args[i]; return v; }, latex: function(args) { var i; var s = args[0]; for (i=1; i<args.length; i++) s = s + " \cdot " + args[i]; return s; } };
  BOperations.push(op);


}

// Knotentypen:
// 1: Urtext,
// 2: Operation mit children-Array
// 3: Klammerwert
// 4: Numerischer Wert
// Nur die beiden letzten implementieren jeweils latex() und evaluate()


// Eingabe: s = die Formel als String
// Ausgabe: Baum
function parseBOperations(s) {
  var b = { expanded: false, root: { type: 1, text: s} };
  parseNode(b);
  return b;
}

// Eingabe: b = ein zu expandierender Knoten
// Ausgabe: Ein bei einem Knoten expandierter Baum
function parseNode(b) {
  
}
