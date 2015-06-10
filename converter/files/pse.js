var MyFolder = ""; // Relativer Ordner der pse.js und radio.png enthaelt
var leftpadding = 230;    //220;
var toppaddingstart = 180;
var spacing = 10;
var fsize;
var metalCol = "#A0A05A";
var elementCol = "#C0C0C0";
var halbmetalCol = "#CEDF73";
var nichtmetalCol = "#DEFFBB";
var alkaliCol = "#FFB5B5";
var erdalkaliCol = "#C26060";
var halogenCol ="#FFC82F";
var edelgasCol = "#FFFF7D";
var lanthanCol = "#9393FF";
var actiniumCol = "#5F5FFF";
var id;
var elements;


    var p1 = ["H","He"];
    var name1 = ["Wasserstoff","Helium"];
    var m1 = ["1.008","4.003"]
    var oz1= ["1","2"];
    var ag1 = ["g","g"];
    var rad1 = ["",""];

    var p2 = ["Li","Be","B","C","N","O","F","Ne"];
    var name2 = ["Lithium","Beryllium","Bor","Kohlenstoff","Stickstoff","Sauerstoff","Fluor","Neon"];
    var m2 = ["6.941","9.012","10.811","12.011","14.007","15.999","18.998","20.180"];
    var oz2= ["3","4","5","6","7","8","9","10"];
    var ag2= ["f","f","f","f","g","g","g","g"];
    var rad2= ["","","","","","","",""];
     
    var p3 = ["Na","Mg","Al","Si","P","S","Cl","Ar"];
    var name3 = ["Natrium","Magnesium","Aluminium","Silizium","Phosphor","Schwefel","Chlor","Argon"];
    var m3 = ["22.990","24.305","26.982","28.086","30.974","32.065","35.453","39.948"];
    var oz3= ["11","12","13","14","15","16","17","18"];
    var ag3= ["f", "f", "f", "f", "f", "f", "g","g"];
    var rad3= ["", "", "", "", "", "", "",""];
    
    var p4 = ["K","Ca","Sc","Ti","V","Cr","Mn","Fe","Co","Ni","Cu","Zn","Ga","Ge","As","Se","Br","Kr"];
    var name4 = ["Kalium","Calcium","Scandium","Titan","Vanadium","Chrom","Mangan","Eisen","Cobalt","Nickel","Kupfer","Zink","Gallium","Germanium","Arsen","Selen","Brom","Krypton"];
    var m4 = ["39.098","40.078","44.956","47.867","50.942","51.996","54.938","55.845","58.933","58.693","63.546","65.409","69.723","72.64","74.922","78.96","79.904","83.798"];
    var oz4= ["19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36"];    
    var ag4= ["f", "f", "f", "f", "f", "f", "f","f", "f" , "f", "f", "f", "f", "f", "f", "f", "l", "g"];
    var rad4= ["", "", "", "", "", "", "","", "" , "", "", "", "", "", "", "", "", ""];
    
    var p5 = ["Rb","Sr","Y","Zr","Nb","Mo","Tc","Ru","Rh","Pd","Ag","Cd","In","Sn","Sb","Te","I","Xe"];
    var name5 = ["Rubidium","Strontium","Yttrium","Zirconium","Niob","Molybd\u00e4n","Technetium","Ruthenium","Rhodium","Palladium","Silber","Cadmium","Indium","Zinn","Antimon","Tellur","Iod","Xenon"];
    var m5 = ["85.468","87.621","88.906","91.224","92.906","95.941","(98","101.07","102.906","106.42","107.868","112.411","114.818","118.710","121.760","127.60","126.904","131.293"];
    var oz5= ["37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54"];    
    var ag5= ["f", "f", "f", "f", "f", "f", "f","f", "f" , "f", "f", "f", "f", "f", "f", "f", "f", "g"];
    var rad5= ["", "", "", "", "", "", "r","", "" , "", "", "", "", "", "", "", "", ""];
    
    var p6 = ["Cs","Ba","La-Lu","Hf","Ta","W","Re","Os","Ir","Pt","Au","Hg","Tl","Pb","Bi","Po","At","Rn"];
    var name6 = ["C\u00e4sium","Barium","","Hafnium","Tantal","Wolfram","Rhenium","Osmium","Iridium","Platin","Gold","Quecksilber","Thallium","Blei","Bismut","Polonium","Astat","Radon"];
    var m6 = ["132.905","137.327","174.967","178.49","180.948","183.84","186.207","190.23","192.217","195.078","196.967","200.59","204.383","207.2","208.980","(209","(210","(222"];
    var oz6= ["55","56","","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86"];    
    var ag6= ["f", "f", "f", "f", "f", "f", "f","f", "f" , "f", "f", "l", "f", "f", "f", "f", "f", "g"];
    var rad6= ["", "", "", "", "", "", "","", "" , "", "", "", "", "", "", "r", "r", "r"];
    
    var p7 = ["Fr","Ra","Ac-No","Rf","Db","Sg","Bh","Hs","Mt","Ds","Rg","Cn","Uut","Uuq","Uup","Uuh","Uus","Uuo"];
    var name7 = ["Francium","Radium","","Rutherfordium","Dubnium","Seaborgium","Bohrium","Hassium","Meitnerium","Darmstadtium","Roentgenium","Copernicium","Ununtrium","Ununquadium","Ununpentium","Ununhexium","Ununseptium","Ununoctium"];
    var m7 = ["(223","(226","","(261","(262","(266","(264","(277","(268","(281","(272","(285","(284","(289","(288","(292","(294","(293"];
    var oz7= ["87","88","","104","105","106","107","108","109","110","111","112","113","114","115","116","117","118"];
    var ag7= ["f", "f", "f", "f", "f", "f",  "f",  "f",  "f" , "f",  "f",   "l",  "f", "f",  "f",  "f",  "f", "g"];
    var rad7= ["r", "r", "r", "r", "r", "r",  "r",  "r",  "r" , "r",  "r",   "r",  "r", "r",  "r",  "r",  "r", "r"];
    
    var la = ["La","Ce","Pr","Nd","Pm","Sm","Eu","Gd","Tb","Dy","Ho","Er","Tm","Yb","Lu"];
    var name8 = ["Lanthan","Cer","Praseodym","Neodym","Promethium","Samarium","Europium","Gadolinium","Terbium","Dysprosium","Holmium","Erbium","Thulium","Ytterbium","Lutetium"];
    var m8 = ["138.906","140.116","140.908","144.243","(145","150.36","151.964","157.25","158.92","162.500","164.930","167.259","168.934","173.04","174.967"];
    var oz8= ["57","58","59","60","61","62","63","64","65","66","67","68","69","70","71"];
    var ag8= ["f", "f", "f", "f", "f", "f", "f","f", "f" , "f", "f", "f", "f", "f", "f"]; 
    var rad8= ["f", "f", "f", "f", "r", "f", "f","f", "f" , "f", "f", "f", "f", "f", "f"]; 
    
    var ac = ["Ac","Th","Pa","U","Np","Pu","Am","Cm","Bk","Cf","Es","Fm","Md","No","Lr"];
    var name9 = ["Actinium","Thorium","Protactnium","Uran","Neptunium","Plutonium","Americium","Curium","Berkelium","Californium","Einsteinium","Fermium","Mendelevium","Nobelium","Lawrencium"];
    var m9 = ["(227","232.038","231.036","238.029","(237","(244","(243","(247","(247","(251","(252","(257","(258","(259","(262"];
    var oz9= ["89","90","91","92","93","94","95","96","97","98","99","100","101","102","103"];   
    var ag9= ["f", "f", "f", "f", "f", "f", "f","f", "f" , "f", "f", "f", "f", "f", "f"]; 
    var rad9= ["r", "r", "r", "r", "r", "r", "r","r", "r" , "r", "r", "r", "r", "r", "r"]; 



function startpse(divId,folder)      // erzeugen der Buttons mit Beschriftung
{
    MyFolder = folder;
    var doc = document.getElementById(divId);
    id = divId;
    var nextNode = doc.nextSibling;
    var button;
    var buttontext;
    var elements,ag,rad;
    var t;
    var dw,dh,t;
    
    var i; // integer
    var j,h; // Abstand, größe integer 
    var toppadding;
    
    toppadding = toppaddingstart;

   

    elements = p1;
    elements = elements.concat(p2);
    elements = elements.concat(p3);
    elements = elements.concat(p4);
    elements = elements.concat(p5);
    elements = elements.concat(p6);
    elements = elements.concat(p7);
    elements = elements.concat(la);
    elements = elements.concat(ac);
    
    ag = ag1;
    ag = ag.concat(ag2);
    ag = ag.concat(ag3);
    ag = ag.concat(ag4);
    ag = ag.concat(ag5);
    ag = ag.concat(ag6); 
    ag = ag.concat(ag7); 
    ag = ag.concat(ag8);
    ag = ag.concat(ag9);
    
    rad = rad1;
    rad = rad.concat(rad2);
    rad = rad.concat(rad3);
    rad = rad.concat(rad4);
    rad = rad.concat(rad5);
    rad = rad.concat(rad6);
    rad = rad.concat(rad7);
    rad = rad.concat(rad8);
    rad = rad.concat(rad9);

    t = 0;

   /* if (navigator.appName.indexOf("Internet Explorer") == -1)     // IE kennt innerXYZ-Attribute nicht
    { 
      dw = document.body.innerWidth;
      dh = document.body.innerHeight;
            dw = document.body.clientWidth;
      dh = document.body.clientHeight;
         alert(dh); 
    } else 
    {
      dw = document.body.clientWidth;
      dh = document.body.clientHeight;
    }*/
    
    dw = document.body.clientWidth;
    dh = document.body.clientHeight;
    // alert(dw);
  //  dw = dw - 210;  // Feste Breite 210px der toc-Liste aus default.css vom Kasseler Konverter

    //if (navigator.appName.indexOf("Internet Explorer") == -1) dw = dw+leftpadding;
    
  //  leftpadding = Math.round(0.15*dw);
  //  toppadding = Math.round(0.9*dh); 

    // Begrenzung im neuen Design beachten
    if (dw>1000) dw = 1000;

    spacing = dw/1600*10; 
    h = Math.abs((dw-leftpadding-spacing*18)/18);
    if(h<24) h = 24;
    j = 0;
    fsize = h*0.45;
    toppadding = toppadding + 0*fsize;

    for(i = 1;i<19;i++)                          // Gruppennummer erzeugen         IUPAC
    {
        button = document.createElement('obj');
        button.setAttribute("hg"+i, "button");
        buttontext = document.createTextNode(i);
        button.appendChild(buttontext);
        button.id = "hg"+i;
        if (doc.nextSibling)
        {
            doc.parentNode.appendChild(button, nextNode);
        } else
        {
            doc.parentNode.appendChild(button);
        } 
        
        
        var name = "hg"+i;
        var elem = document.getElementById(name);
        elem.style.backgroundColor = "transparent";
        elem.style.fontSize = fsize*0.7 + "px";
        elem.style.position="absolute";
        elem.style.left = leftpadding+h*(i-1)+spacing*(i-1) + "px";
        elem.style.textAlign = "center";
        elem.style.height = h + "px";
        elem.style.width = h+ "px";
        elem.disabled = "true";
        elem.style.top = toppadding-fsize-spacing-fsize + "px";             
    }
    
    for(i = 1;i<19;i++)                          // Gruppennummer erzeugen  veraltet
    {
        button = document.createElement('obj2');
        button.setAttribute("ng"+i, "button");
        s="";
        if(i==1) s = "1 A";
        if(i==2) s = "2 A";
        if(i==3) s = "3 B";
        if(i==4) s = "4 B";
        if(i==5) s = "5 B";
        if(i==6) s = "6 B";
        if(i==7) s = "7 B";
        if(i==8) s = "8 B";
        if(i==9) s = "8 B";
        if(i==10) s = "8 B";
        if(i==11) s = "1 B";
        if(i==12) s = "2 B";
        if(i==13) s = "3 A";
        if(i==14) s = "4 A";
        if(i==15) s = "5 A";
        if(i==16) s = "6 A";
        if(i==17) s = "7 A";
        if(i==18) s = "8 A";
        
        
        buttontext = document.createTextNode(s);
        button.appendChild(buttontext);
        button.id = "ng"+i;
        if (doc.nextSibling)
        {
            doc.parentNode.appendChild(button, nextNode);
        } else
        {
            doc.parentNode.appendChild(button);
        }


        var name = "ng"+i;
        var elem = document.getElementById(name);
        elem.style.backgroundColor = "transparent";
        elem.style.color = "lightgray";
        elem.style.fontSize = fsize*0.7 + "px";
        elem.style.position="absolute";
        elem.style.left = leftpadding+h*(i-1)+spacing*(i-1) + "px";
        elem.style.textAlign = "center";
        elem.style.height = h + "px";
        elem.style.width = h+ "px";
        elem.disabled = "true";
        elem.style.top = toppadding-spacing-fsize + "px";
        
        
    }
         
         
    
    


    //------------------------------------------------------------
        button = document.createElement('obj');         // Wort Lanthanoid
        button.setAttribute("lanthanText", "obj");
        buttontext = document.createTextNode("Lanthanoide:");
        button.appendChild(buttontext);
        button.id = "lanthanText";
        if (doc.nextSibling)
        {
            doc.parentNode.appendChild(button, nextNode);
        } else
        {
            doc.parentNode.appendChild(button);
        }


        var name = "lanthanText";
        var elem = document.getElementById(name);
        elem.style.backgroundColor = "transparent";
        elem.style.fontSize = fsize*0.8 + "px";
        elem.style.position="absolute";
        elem.style.left = leftpadding+spacing+ "px";
        elem.style.textAlign = "right";
        elem.style.height = h + "px";
        elem.style.width = h+ "px";
        elem.disabled = "true";
        elem.style.top = toppadding+8*spacing+h*7+h/2 + "px";
        
        button = document.createElement('obj');         // Wort Actinoide
        button.setAttribute("actinoidText", "obj");
        buttontext = document.createTextNode("Actinoide:");
        button.appendChild(buttontext);
        button.id = "actinoidText";
        if (doc.nextSibling)
        {
            doc.parentNode.appendChild(button, nextNode);
        } else
        {
            doc.parentNode.appendChild(button);
        }


        var name = "actinoidText";
        var elem = document.getElementById(name);
        elem.style.backgroundColor = "transparent";
        elem.style.fontSize = fsize*0.8 + "px";
        elem.style.position="absolute";
        elem.style.left = leftpadding+spacing+ "px";
        elem.style.textAlign = "right";
        elem.style.height = h + "px";
        elem.style.width = h+ "px";
        elem.disabled = "true";
        elem.style.top = toppadding+9*spacing+h*8+h/2 + "px";
        doc.style.height = 10*spacing+h*10+"px";;
        //doc.style.height =  29*fsize+"px"; // h*10+8*spacing+toppadding + "px"          // für PSE Unterschrift gasförmig etc.
       // if (navigator.appName.indexOf("Internet Explorer") == -1)  doc.style.height =    31*fsize+"px";

    for(i = 0;i<elements.length; i++)           // Elemente erzeugen --> Das sind die Element-Buttons mit Beschriftung
    {
        if(i == 90) t = t + 2*spacing;       // für Lanthanoide und Actinoide
        if(i == 1) j = 17;
        if(i == 4) j = 12;
        if(i == 12) j = 12;
        if(j > 17) 
        {
            t = t + h+spacing;
            j = 0;
            if(i > 89) j = 2.5;           
        }
        if(elements[i] != "" && elements[i] != "next")
        {
            button = document.createElement('button');
            button.setAttribute("elm"+i, "button");
            buttontext = document.createTextNode(elements[i]+" ");
            button.appendChild(buttontext);
            //button.style.backgroundImage = "url(radio.png)";
            button.id = "elm"+i;
            if (doc.nextSibling)
            {
                doc.parentNode.appendChild(button, nextNode);
            } else
            {
                doc.parentNode.appendChild(button);
            } 
            
            var name = "elm"+i;
            var elem = document.getElementById(name);
            elem.style.backgroundColor = "#CFCFCF";
            elem.style.fontSize = fsize + "px";
            elem.style.fontWeight = "bold";
            if(elements[i]== "La-Lu" || elements[i]== "Ac-No"  ) elem.style.fontSize = fsize/2 + "px";
            if(i>83 && i<90  ) 
            {
                elem.style.fontSize = fsize/1.2 + "px";
                elem.style.fontStyle = "italic"; 
            }
            if(rad[i]=="r")
            {
                 elem.style.backgroundImage = "url(" + folder + "/radio.png)";
                elem.style.backgroundRepeat = "no-repeat";
                elem.style.backgroundPosition = "right top";           
            }

            elem.style.position="absolute";
            elem.style.left = leftpadding+h*j+spacing*j + "px";
            elem.style.height = h + "px";
            elem.style.width = h + "px";
            elem.style.backgroundColor = elementCol;
            elem.style.textAlign = "center";
            elem.style.paddingLeft = 0 + "px";
            elem.style.border = "solid black 1px";
            
           // elem.style.backgroundAttachment = "fixed";
            elem.style.top = toppadding+t + "px";   
            if(ag[i]=="g") elem.style.color = "#FF0000";
            if(ag[i]=="l") elem.style.color = "#0000FF";

            
    
            addEvent(elem,"click",info);               // Ereignis einbinden
            addEvent(elem,"mouseover",msg);            // Ereignis einbinden
            addEvent(elem,"mouseout",out);                 // Ereignis einbinden
            //alert(event.button);                     

            j++;     
        } else
        {
          if(elements[i]!="next") j++; 
          if(elements[i]=="next") 
          {
            t = t + h+spacing;
            j = 0;   
          } 
        }   
    } 

    
    
   
    button = document.createElement('button');             // großes Symbol Mitte
    button.setAttribute("anzeige", "button");
    buttontext = document.createTextNode("Element    "+"\n"+"symbol");    
    button.appendChild(buttontext);
    button.id = "anzeige";
    if (doc.nextSibling)
    {
        doc.parentNode.appendChild(button, nextNode);
    } else
    {
        doc.parentNode.appendChild(button);
    }
    var name = "anzeige";
    var elem = document.getElementById(name);
    elem.style.backgroundColor = "transparent";
    elem.style.fontSize = fsize*1.5+ "px";
    elem.style.border = "none";
    elem.style.position="absolute";
    elem.style.left = leftpadding+h*3+spacing*3 + "px";
    elem.style.height = h*3 + "px";
    elem.style.width = h*3 + "px";
    elem.style.top = toppadding + "px";
    
    button = document.createElement('button');             // Ordnungszahl
    button.setAttribute("ordnungszahl", "button");
    buttontext = document.createTextNode("Ordnungszahl");
    button.appendChild(buttontext);
    button.id = "ordnungszahl";
    if (doc.nextSibling)
    {
        doc.parentNode.appendChild(button, nextNode);
    } else
    {
        doc.parentNode.appendChild(button);
    }
    var name = "ordnungszahl";
    var elem = document.getElementById(name);
    elem.style.backgroundColor = "transparent";
    elem.style.fontSize = fsize*0.5+ "px";
    elem.style.border = "none";
    elem.style.position="absolute";
    elem.style.textAlign = "right";
    elem.style.left = leftpadding+h*1.8+spacing*2 + "px";
    elem.style.height = h + "px";
    elem.style.width = 2*h + "px";
    elem.style.top = toppadding + "px";
    
    
    button = document.createElement('button');             // Name
    button.setAttribute("elemname", "button");
    buttontext = document.createTextNode("Name");
    button.appendChild(buttontext);
    button.id = "elemname";
    if (doc.nextSibling)
    {
        doc.parentNode.appendChild(button, nextNode);
    } else
    {
        doc.parentNode.appendChild(button);
    }
    var name = "elemname";
    var elem = document.getElementById(name);
    elem.style.backgroundColor = "transparent";
    elem.style.fontSize = fsize*1+ "px";
    elem.style.border = "none";
    elem.style.position="absolute";
    elem.style.left = leftpadding+h*3+spacing*2 + "px";
    elem.style.height = h + "px";
    elem.style.width = h*3+2*spacing + "px";
    elem.style.top = toppadding + 2.1*h+"px";
    
    button = document.createElement('button');             // Masse
    button.setAttribute("masse", "button");
    buttontext = document.createTextNode("Masse");
    button.appendChild(buttontext);
    button.id = "masse";
    if (doc.nextSibling)
    {
        doc.parentNode.appendChild(button, nextNode);
    } else
    {
        doc.parentNode.appendChild(button);
    }
    var name = "masse";
    var elem = document.getElementById(name);
    elem.style.backgroundColor = "transparent";
    elem.style.fontSize = fsize*1+ "px";
    elem.style.border = "none";
    elem.style.position="absolute";
    elem.style.left = leftpadding+h*3+spacing*3 + "px";
    elem.style.height = h + "px";
    elem.style.width = h*3 + "px";
    elem.style.top = toppadding + 2.1*h+fsize*1+"px";
    
 
    
  /*  button = document.createElement('button');             // Aggeregatszustand
    button.setAttribute("aggregat", "button");
    buttontext = document.createTextNode("");
    button.appendChild(buttontext);
    button.id = "aggregat";
    if (doc.nextSibling)
    {
        doc.parentNode.appendChild(button, nextNode);
    } else
    {
        doc.parentNode.appendChild(button);
    }
    var name = "aggregat";
    var elem = document.getElementById(name);
    elem.style.backgroundColor = "transparent";
    elem.style.fontSize = fsize*0.6+ "px";
    elem.style.border = "none";
    elem.style.position="absolute";
    elem.style.left = leftpadding+h*2+spacing*2 + "px";
    elem.style.height = h + "px";
    elem.style.width = h*2 + "px";
    elem.style.textAlign = "left";
    elem.style.top = toppadding + 2.1*h+fsize*1+"px";   */
    
    //----------------------------------------
    
    button = document.createElement('button');             // Button Metalle
    button.setAttribute("metalle", "button");
    buttontext = document.createTextNode("Metalle");
    button.appendChild(buttontext);
    button.id = "metalle";
    if (doc.nextSibling)
    {
        doc.parentNode.appendChild(button, nextNode);
    } else
    {
        doc.parentNode.appendChild(button);
    }
    var name = "metalle";
    var elem = document.getElementById(name);
   // elem.style.backgroundColor = "transparent";
    elem.style.fontSize = fsize*0.7+ "px";
    elem.style.border = "none";
    elem.style.position="absolute";
    elem.style.left = leftpadding+h*6+spacing*6 + "px";
    elem.style.height = h*0.8 + "px";
    elem.style.width = h*2 + "px";
    elem.style.top = toppadding + 0*h+fsize*1+"px";
    elem.style.backgroundColor = metalCol;
    addEvent(elem,"mouseover",metalle);            // Ereignis einbinden
    addEvent(elem,"mouseout",metalleOut);            // Ereignis einbinden
    
    
    
    //--------------------------------------- 
    button = document.createElement('button');             // Button Halb-Metalle
    button.setAttribute("halbmetalle", "button");
    buttontext = document.createTextNode("Halbmetalle");
    button.appendChild(buttontext);
    button.id = "halbmetalle";
    if (doc.nextSibling)
    {
        doc.parentNode.appendChild(button, nextNode);
    } else
    {
        doc.parentNode.appendChild(button);
    }
    var name = "halbmetalle";
    var elem = document.getElementById(name);
   // elem.style.backgroundColor = "transparent";
    elem.style.fontSize = fsize*0.7+ "px";
    elem.style.border = "none";
    elem.style.position="absolute";
    elem.style.left = leftpadding+h*6+spacing*6 + "px";
    elem.style.height = h*0.8 + "px";
    elem.style.width = h*2 + "px";
    elem.style.top = toppadding + 1*h+fsize*1+"px";
    elem.style.backgroundColor = halbmetalCol;
    addEvent(elem,"mouseover",halbmetalle);            // Ereignis einbinden
    addEvent(elem,"mouseout",halbmetalleOut);            // Ereignis einbinden
    
    
        //---------------------------------------
    button = document.createElement('button');             // Button Nicht-Metalle
    button.setAttribute("nichtmetalle", "button");
    buttontext = document.createTextNode("Nichtmetalle");
    button.appendChild(buttontext);
    button.id = "nichtmetalle";
    if (doc.nextSibling)
    {
        doc.parentNode.appendChild(button, nextNode);
    } else
    {
        doc.parentNode.appendChild(button);
    }
    var name = "nichtmetalle";
    var elem = document.getElementById(name);
   // elem.style.backgroundColor = "transparent";
    elem.style.fontSize = fsize*0.7+ "px";
    elem.style.border = "none";
    elem.style.position="absolute";
    elem.style.left = leftpadding+h*6+spacing*6 + "px";
    elem.style.height = h*0.8 + "px";
    elem.style.width = h*2 + "px";
    elem.style.top = toppadding + 2*h+fsize*1+"px";
    elem.style.backgroundColor = nichtmetalCol;
    addEvent(elem,"mouseover",nichtmetalle);            // Ereignis einbinden
    addEvent(elem,"mouseout",nichtmetalleOut);            // Ereignis einbinden

        //---------------------------------------
    button = document.createElement('button');             // Button Alkali-Metalle
    button.setAttribute("alkalimetalle", "button");
    buttontext = document.createTextNode("Alkalimetalle");
    button.appendChild(buttontext);
    button.id = "alkalimetalle";
    if (doc.nextSibling)
    {
        doc.parentNode.appendChild(button, nextNode);
    } else
    {
        doc.parentNode.appendChild(button);
    }
    var name = "alkalimetalle";
    var elem = document.getElementById(name);
   // elem.style.backgroundColor = "transparent";
    elem.style.fontSize = fsize*0.7+ "px";
    elem.style.border = "none";
    elem.style.position="absolute";
    elem.style.left = leftpadding+h*8+spacing*7 + "px";
    elem.style.height = h*0.8 + "px";
    elem.style.width = h*2 + "px";
    elem.style.top = toppadding + 0*h+fsize*1+"px";
    elem.style.backgroundColor = alkaliCol;
    addEvent(elem,"mouseover",alkalimetalle);            // Ereignis einbinden
    addEvent(elem,"mouseout",alkalimetalleOut);            // Ereignis einbinden     
    
        //---------------------------------------
    button = document.createElement('button');             // Button Erdalkali-Metalle
    button.setAttribute("erdalkalimetalle", "button");
    buttontext = document.createTextNode("Erdalkalimet.");
    button.appendChild(buttontext);
    button.id = "erdalkalimetalle";
    if (doc.nextSibling)
    {
        doc.parentNode.appendChild(button, nextNode);
    } else
    {
        doc.parentNode.appendChild(button);
    }
    var name = "erdalkalimetalle";
    var elem = document.getElementById(name);
   // elem.style.backgroundColor = "transparent";
    elem.style.fontSize = fsize*0.7+ "px";
    elem.style.border = "none";
    elem.style.position="absolute";
    elem.style.left = leftpadding+h*8+spacing*7 + "px";
    elem.style.height = h*0.8 + "px";
    elem.style.width = h*2 + "px";
    elem.style.top = toppadding + 1*h+fsize*1+"px";
    elem.style.backgroundColor = erdalkaliCol;
    addEvent(elem,"mouseover",erdalkalimetalle);            // Ereignis einbinden
    addEvent(elem,"mouseout",erdalkalimetalleOut);            // Ereignis einbinden
    
    
    //---------------------------------------
    button = document.createElement('button');             // Button Halogene-Metalle
    button.setAttribute("halogene", "button");
    buttontext = document.createTextNode("Halogene");
    button.appendChild(buttontext);
    button.id = "halogene";
    if (doc.nextSibling)
    {
        doc.parentNode.appendChild(button, nextNode);
    } else
    {
        doc.parentNode.appendChild(button);
    }
    var name = "halogene";
    var elem = document.getElementById(name);
   // elem.style.backgroundColor = "transparent";
    elem.style.fontSize = fsize*0.7+ "px";
    elem.style.border = "none";
    elem.style.position="absolute";
    elem.style.left = leftpadding+h*8+spacing*7 + "px";
    elem.style.height = h*0.8 + "px";
    elem.style.width = h*2 + "px";
    elem.style.top = toppadding + 2*h+fsize*1+"px";
    elem.style.backgroundColor = halogenCol;
    addEvent(elem,"mouseover",halogen);            // Ereignis einbinden
    addEvent(elem,"mouseout",halogenOut);            // Ereignis einbinden
    
    
    //---------------------------------------
    button = document.createElement('button');             // Button Edelgase-Metalle
    button.setAttribute("edelgase", "button");
    buttontext = document.createTextNode("Edelgase");
    button.appendChild(buttontext);
    button.id = "edelgase";
    if (doc.nextSibling)
    {
        doc.parentNode.appendChild(button, nextNode);
    } else
    {
        doc.parentNode.appendChild(button);
    }
    var name = "edelgase";
    var elem = document.getElementById(name);
   // elem.style.backgroundColor = "transparent";
    elem.style.fontSize = fsize*0.7+ "px";
    elem.style.border = "none";
    elem.style.position="absolute";
    elem.style.left = leftpadding+h*10+spacing*8 + "px";
    elem.style.height = h*0.8 + "px";
    elem.style.width = h*2 + "px";
    elem.style.top = toppadding + 0*h+fsize*1+"px";
    elem.style.backgroundColor = edelgasCol;
    addEvent(elem,"mouseover",edelgas);            // Ereignis einbinden
    addEvent(elem,"mouseout",edelgasOut);            // Ereignis einbinden
    
    
    //---------------------------------------
    button = document.createElement('button');             // Button Lanthanoide-Metalle
    button.setAttribute("lanthanoide", "button");
    buttontext = document.createTextNode("Lanthanoide");
    button.appendChild(buttontext);
    button.id = "lanthanoide";
    if (doc.nextSibling)
    {
        doc.parentNode.appendChild(button, nextNode);
    } else
    {
        doc.parentNode.appendChild(button);
    }
    var name = "lanthanoide";
    var elem = document.getElementById(name);
   // elem.style.backgroundColor = "transparent";
    elem.style.fontSize = fsize*0.7+ "px";
    elem.style.border = "none";
    elem.style.position="absolute";
    elem.style.left = leftpadding+h*10+spacing*8 + "px";
    elem.style.height = h*0.8 + "px";
    elem.style.width = h*2 + "px";
    elem.style.top = toppadding + 1*h+fsize*1+"px";
    elem.style.backgroundColor = lanthanCol;
    addEvent(elem,"mouseover",lanthan);            // Ereignis einbinden
    addEvent(elem,"mouseout",lanthanOut);            // Ereignis einbinden
    
        //---------------------------------------
    button = document.createElement('button');             // Button Actinoide-Metalle
    button.setAttribute("actinoide", "button");
    buttontext = document.createTextNode("Actinoide");
    button.appendChild(buttontext);
    button.id = "actinoide";
    if (doc.nextSibling)
    {
        doc.parentNode.appendChild(button, nextNode);
    } else
    {
        doc.parentNode.appendChild(button);
    }
    var name = "actinoide";
    var elem = document.getElementById(name);
   // elem.style.backgroundColor = "transparent";
    elem.style.fontSize = fsize*0.7+ "px";
    elem.style.border = "none";
    elem.style.position="absolute";
    elem.style.left = leftpadding+h*10+spacing*8 + "px";
    elem.style.height = h*0.8 + "px";
    elem.style.width = h*2 + "px";
    elem.style.top = toppadding + 2*h+fsize*1+"px";
    elem.style.backgroundColor = actiniumCol;
    addEvent(elem,"mouseover",actinium);            // Ereignis einbinden
    addEvent(elem,"mouseout",actiniumOut);            // Ereignis einbinden  
    //if (!window.Weite && window.innerWidth) {window.onresize=resize;}
    addEvent(window,"resize",resize);
    addEvent(window,"maximize",resize);
                                                    
}

function resize()
{
    var i,elements;
    
   /* for(i=0;i<document.getElementById(id).length;i++)
    {
            document.getElementById(id).parentNode.removeChild(document.getElementById(id).childnodes[i]);
    }*/ 

  //  var k = document.getElementById(id);
  //  var AnzahlZeichen = document.getElementsByTagName("div")[0].firstChild.nodeValue.length;
  //  document.getElementsByTagName("div")[0].frstChild.deleteData(0, AnzahlZeichen);
   // document.getElementsByTagName("div")[0].firstChild.nodeValue.length;
   
    elements = p1;
    elements = elements.concat(p2);
    elements = elements.concat(p3);
    elements = elements.concat(p4);
    elements = elements.concat(p5);
    elements = elements.concat(p6);
    elements = elements.concat(p7);
    elements = elements.concat(la);
    elements = elements.concat(ac);
    
    for(i=1;i<19;i++)
    {
        removeElement("hg"+i);    
        removeElement("ng"+i);
    }
    removeElement("lanthanText");
    removeElement("actinoidText");
    
    for(i=0;i<elements.length;i++)
    {
        removeElement("elm"+i);    
    }
    removeElement("anzeige");
    removeElement("ordnungszahl");
    removeElement("elemname");
    removeElement("masse");
    removeElement("metalle");
    removeElement("halbmetalle");
    removeElement("nichtmetalle");
    removeElement("edelgase");
    removeElement("halogene");
    removeElement("alkalimetalle");
    removeElement("erdalkalimetalle");
    removeElement("actinoide");
    removeElement("lanthanoide");
    
    startpse(id,MyFolder);
}


function removeElement(divNum) 
{

  var d = document.getElementById(id);

  var olddiv = document.getElementById(divNum);

  d.parentNode.removeChild(olddiv);

}




function metalle(e)   // Metalle anzeigen
{
    var element;
    var i,j;
    var metal = [3,4,11,12,13,19,20,21,22,23,24,25,26,27,28,29,30,31,37,38,39,40,41,42,43,44,45,46,47,48,49,50,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120];

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = metalCol;        
    }   
}

function metalleOut(e)   // Metalle anzeigen
{
    var element;
    var i,j;
    var metal = [3,4,11,12,13,19,20,21,22,23,24,25,26,27,28,29,30,31,37,38,39,40,41,42,43,44,45,46,47,48,49,50,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120];

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = elementCol;
    }
}


function halbmetalle(e)   // Halb-Metalle anzeigen
{
    var element;
    var i,j;
    var metal = [5,14,32,33,34,51,52,71,89];

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = halbmetalCol;
    }
}

function halbmetalleOut(e)   // 
{
    var element;
    var i,j;
    var metal = [5,14,32,33,34,51,52,71,89]

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = elementCol;
    }
}


function nichtmetalle(e)   // Nicht-Metalle anzeigen
{
    var element;
    var i,j;
    var metal = [1,2,6,7,8,9,10,15,16,17,18,35,36,53,54,72,90];

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = nichtmetalCol;
    }
}

function nichtmetalleOut(e)   
{
    var element;
    var i,j;
    var metal = [1,2,6,7,8,9,10,15,16,17,18,35,36,53,54,72,90];

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = elementCol;
    }
}


function alkalimetalle(e)   // AlkaliMetalle anzeigen
{
    var element;
    var i,j;
    var metal = [3,11,19,37,55,73];

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = alkaliCol;
    }
}

function alkalimetalleOut(e)   
{
    var element;
    var i,j;
    var metal = [3,11,19,37,55,73]

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = elementCol;
    }
}


function erdalkalimetalle(e)   // Erdalkalimetalle anzeigen
{
    var element;
    var i,j;
    var metal = [4,12,20,38,56,74];

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = erdalkaliCol;
    }
}

function erdalkalimetalleOut(e)   // 
{
    var element;
    var i,j;
    var metal = [4,12,20,38,56,74];

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = elementCol;
    }
}

function halogen(e)   // Halogene anzeigen
{
    var element;
    var i,j;
    var metal = [9,17,35,53,71,89];

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = halogenCol;
    }
}

function halogenOut(e)   // 
{
    var element;
    var i,j;
    var metal = [9,17,35,53,71,89];

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = elementCol;
    }
}


function edelgas(e)   // Edelgase anzeigen
{
    var element;
    var i,j;
    var metal = [2,10,18,36,54,72,90];

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = edelgasCol;
    }
}

function edelgasOut(e)   // 
{
    var element;
    var i,j;
    var metal = [2,10,18,36,54,72,90];

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = elementCol;
    }
}


function lanthan(e)   // Lanthanoide anzeigen
{
    var element;
    var i,j;
    var metal = [57,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105];

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = lanthanCol;
    }
}

function lanthanOut(e)   // Actinoide anzeigen
{
    var element;
    var i,j;
    var metal = [57,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105];

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = elementCol;
    }
}


function actinium(e)   // Actinioide anzeigen
{
    var element;
    var i,j;
    var metal = [75,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120];

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = actiniumCol;
    }
}

function actiniumOut(e)   // Metalle anzeigen
{
    var element;
    var i,j;
    var metal = [75,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120];;

    for(i=0;i<metal.length;i++)
    {
        j = metal[i]-1;
        element = document.getElementById("elm"+j);
        element.style.backgroundColor = elementCol;
    }
}

function msg(e)  // Anzeige des aktuellen Elements
{

    var targ,s;
    var elements, masse,names,oz,ag;
    var i;  
    if (!e) var e = window.event;
    if (e.target) targ = e.target;
        else if (e.srcElement) targ = e.srcElement;
    if (targ.nodeType == 3) // defeat Safari bug
    targ = targ.parentNode;
 
   
    elements = p1;
    elements = elements.concat(p2);
    elements = elements.concat(p3);
    elements = elements.concat(p4);
    elements = elements.concat(p5);
    elements = elements.concat(p6);
    elements = elements.concat(p7);
    elements = elements.concat(la);
    elements = elements.concat(ac);
    
    masse = m1;
    masse = masse.concat(m2);
    masse = masse.concat(m3);
    masse = masse.concat(m4);
    masse = masse.concat(m5);
    masse = masse.concat(m6);
    masse = masse.concat(m7);
    masse = masse.concat(m8);
    masse = masse.concat(m9);
    
    names = name1;
    names = names.concat(name2);
    names = names.concat(name3);
    names = names.concat(name4);
    names = names.concat(name5);
    names = names.concat(name6);
    names = names.concat(name7);
    names = names.concat(name8); 
    names = names.concat(name9);    
    
    oz = oz1;
    oz = oz.concat(oz2);
    oz = oz.concat(oz3);
    oz = oz.concat(oz4);
    oz = oz.concat(oz5);
    oz = oz.concat(oz6);
    oz = oz.concat(oz7);   
    oz = oz.concat(oz8);
    oz = oz.concat(oz9);
    
    ag = ag1;
    ag = ag.concat(ag2);
    ag = ag.concat(ag3);
    ag = ag.concat(ag4);
    ag = ag.concat(ag5);
    ag = ag.concat(ag6);
    ag = ag.concat(ag7);
    ag = ag.concat(ag8);
    ag = ag.concat(ag9); 
    
    
    //alert(targ.id.substring(3,targ.id.length));
    i = targ.id.substring(3,targ.id.length);
    var name = "anzeige";
    var but = document.getElementById(name);
    //but.value = elements[i];       
    //but.replaceChild(0,1);
    but.style.fontSize = fsize*3 + "px";
    if(elements[i]== "La-Lu" || elements[i]== "Ac-No"  ) 
    {
        but.style.fontSize = fsize*1 + "px";
        if(elements[i]== "La-Lu") s = "Lanthanoide";
        if(elements[i]== "Ac-No") s = "Actinoide";
        var buttontext = document.createTextNode(s);
        but.replaceChild(buttontext,but.childNodes[0]);

        buttontext = document.createTextNode("");
        document.getElementById("masse").replaceChild(buttontext,document.getElementById("masse").childNodes[0]);

        buttontext = document.createTextNode("");
        document.getElementById("ordnungszahl").replaceChild(buttontext,document.getElementById("ordnungszahl").childNodes[0]);

        buttontext = document.createTextNode("");
        document.getElementById("elemname").replaceChild(buttontext,document.getElementById("elemname").childNodes[0]);        
    } else
    {
        
        var buttontext = document.createTextNode(elements[i]);
        but.replaceChild(buttontext,but.childNodes[0]);

        s = masse[i]+ " u";
        if(masse[i] == "unbekannt") s = masse[i];
        if(s.search(/\(/) == 0) s = s+")"; 
        buttontext = document.createTextNode(s);
        document.getElementById("masse").replaceChild(buttontext,document.getElementById("masse").childNodes[0]);

        buttontext = document.createTextNode(oz[i]);
        if(i>83 && i < 90  ) {document.getElementById("ordnungszahl").style.textAlign = "left";} else {document.getElementById("ordnungszahl").style.textAlign = "right"; }
        document.getElementById("ordnungszahl").replaceChild(buttontext,document.getElementById("ordnungszahl").childNodes[0]); 
        document.getElementById("ordnungszahl").style.fontSize = fsize*2+ "px";

        buttontext = document.createTextNode(names[i]);
        document.getElementById("elemname").replaceChild(buttontext,document.getElementById("elemname").childNodes[0]);
        
     /*   s = "fest";
        if(ag[i]== "g") s = "gasförmig";
        if(ag[i]== "l") s = "flüssig";
        buttontext = document.createTextNode(s);
        document.getElementById("aggregat").replaceChild(buttontext,document.getElementById("aggregat").childNodes[0]);*/
    }
    
}


function info(e)        // klick auf Element
{
    var targ;
    var i;

    if (!e) var e = window.event;
    if (e.target) targ = e.target;
        else if (e.srcElement) targ = e.srcElement;
    if (targ.nodeType == 3) // defeat Safari bug
    targ = targ.parentNode;
    i = targ.id.substring(3,targ.id.length);
    i = i*1;
    //newWindow("../../data/h.html","La",800,600);
    switch(i)
    {
        case 0:
            //popUp("elements/h.xhtml");  
        break;
        case 1:
            //popUp("elements/he.xhtml");
        break;       
        case 2:
            //popUp("elements/li.xhtml");
        break;
        case 3:
            //popUp("elements/be.xhtml");
        break;
        case 4:
            //popUp("elements/b.xhtml");
        break;
        case 5:
            //popUp("elements/c.xhtml");
        break;
        case 6:
            //popUp("elements/n.xhtml");
        break;
        case 7:
            //popUp("elements/f.xhtml");
        break;
        case 8:
            //popUp("elements/ne.xhtml");
        break;
        case 9:
            //popUp("elements/na.xhtml");
        break;  
        case 10:
            //popUp("elements/mg.xhtml");
        break;      
        
        default:
    }
 
}

function out(e)        // klick auf Element
{
        var but = document.getElementById("anzeige");
        but.style.fontSize = fsize*1.5 + "px";    
        var buttontext = document.createTextNode("Element    \nsymbol"); 
        but.replaceChild(buttontext,document.getElementById("anzeige").childNodes[0]);
        //document.getElementById("anzeige").fontSize = fsize*1.5+ "px";  
        
        buttontext = document.createTextNode("Masse");
        document.getElementById("masse").replaceChild(buttontext,document.getElementById("masse").childNodes[0]);
        var but2 = document.getElementById("ordnungszahl");
        but2.style.fontSize = fsize*0.5 + "px" 
        buttontext = document.createTextNode("Ordnungszahl");
        but2.replaceChild(buttontext,document.getElementById("ordnungszahl").childNodes[0]);
        buttontext = document.createTextNode("Name");
        document.getElementById("elemname").replaceChild(buttontext,document.getElementById("elemname").childNodes[0]);
}


function addEvent( obj, type, fn )
{
   if (obj.addEventListener) 
   {
      //fn = fn+"f";
      obj.addEventListener( type, fn, false );
      //alert("firefox");
   } else if (obj.attachEvent) {
      obj["e"+type+fn] = fn;
      obj[type+fn] = function() { obj["e"+type+fn]( window.event ); }
      obj.attachEvent( "on"+type, obj[type+fn] );
   }
}

function removeEvent( obj, type, fn )
{
   if (obj.removeEventListener) {
      obj.removeEventListener( type, fn, false );
   } else if (obj.detachEvent) {
      obj.detachEvent( "on"+type, obj[type+fn] );
      obj[type+fn] = null;
      obj["e"+type+fn] = null;
   }
}


function popUp(file)
{
        var w = document.body.clientWidth;
        var h = document.body.clientHeight;
        x = w/4;
        y = h/4;
        w = w/2;
        h = h/2;
        w = 640;
        h = 600;
        var popupWindow = window.open(file,'','width='+w+',height='+h+',left='+x+',top='+y+'toolbar=no, directories=no, location=no, resizable=no,status=0, toolbar = no, location = no, menubar= no,navigation=no,resize=none');
        popupWindow.focus();
        //popupWindow.document.write(this);
}

