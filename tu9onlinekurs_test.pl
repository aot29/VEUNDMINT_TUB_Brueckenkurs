# Globale Einstellungen fuer mconvert.pl und conv.pl (sowie die darin eingebundenen modules)

testonly        =>      0       , # =1 -> Zahlreiche Funktionen (z.B. Einstellungen) werden deaktiviert
scormlogin      =>      0       , # =1 -> Alle Anmeldesysteme werden deaktiviert, und Teilnehmer ueber SCORM identifiziert
nosols          =>      0       , # =0: Alle Loesungsumgebungen uebersetzen, =1: Loesungsumgebungen nicht uebersetzen wenn SolutionSelect-Pragma aktiviert ist
doscorm         =>      0       , # =0: Kein SCORM, =1 -> SCORM-Manifest und Definitionsdateien miterzeugen, html-Baum kann dann als SCORM-Lernmodul Version 4 verwendet werden, dann muss auch entsprechendes Flag in conv.pl gesetzt werden
qautoexport     =>      0       , # =1 Alle MExercise-Umgebungen werden auch als Export verpackt
diaok           =>      0       , # =1 dia/convert-Kette durchfueren, wenn im Programmablauf auf 0 gesetzt wird dia/convert fuer alle files nicht mehr ausgefuehrt
cleanup         =>      1       , # =1 -> trunk-Verzeichnis wird nach Erstellung entfernt (fuer Releases unbedingt aktivieren)
localjax        =>      0       , # =1 -> lokales MathJax-Verzeichnis wird eingerichtet (andernfalls ist netservice-Flag in conv.pl erforderlich)
borkify         =>      0       , # =1 html und js-Dateien werden borkifiziert
dorelease       =>      0       , # In Release-Versionen werden z.B. bestimmte Logmeldungen unterdrueckt
doverbose       =>      0       , # Schaltet alle Debugmeldungen auf der Browserkonsole an
docollections   =>      0       , # Schaltet Export der collection-Exercises ein (schließt qautoexport und nosols aus)
dopdf           =>      0       , # =1 -> PDF wird erstellt und Downloadbuttons erzeugt
dotikz          =>      0       , # =1 -> TikZ wird aufgerufen um Grafiken zu exportieren, diese werden sofort in den Kurs eingebunden
dozip           =>      0       , # =1 -> html-Baum wird als zip-Datei geliefert (Name muss in output stehen)
consolecolors   =>      1       , # =1 -> Ausgabe der Meldungen auf der Konsole wird eingefaerbt
output          =>      "tu9onlinekurstest", # Zielverzeichnis relativ zur Position der Konfigurationsdatei = Aufrufverzeichnis
source          =>      "module_veundmint",  # Quellverzeichnis relativ zur Position der Konfigurationsdatei = Aufrufverzeichnis
module          =>      "tree_tu9onlinekurs.tex",  # tex-Hauptdatei des Kurses (relativ zum Quellverzeichnis!) fuer HTML-Erzeugung
outtmp          =>      "tmp",               # Temporaeres Verzeichnis im cleanup-Teil des Ausgabeverzeichnisses fuer Erstellungsprozesse fuer mconvert.pl und conv.pl
description     =>      "Onlinebrückenkurs Mathematik",
author          =>      "Projekt VE&MINT",
moduleprefix    =>      "Onlinebrückenkurs Mathematik",  # Wird vor Browser-Bookmarks gesetzt
variant         =>      "std",  # zu erzeugende Varianten der HTML-files, "std" ist die Hauptvariante, waehlt Makropakete fuer Mathematikumsetzung aus

stylesheets     =>      ["qtip2/jquery.qtip.min.css", "datatables/min.css"], # Array, grundlagen.css wird automatisch eingesetzt

scriptheaders   =>      ["es5-sham.min.js",
                         "qtip2/jquery-1.10.2.min.js",
                         "qtip2/jquery.qtip.min.js",
                         "datatables/datatables.min.js",
                         "knockout-3.0.0.js",
                         "math.js",
                         "dynamiccss.js",
                         "convinfo.js",
                         "mparser.js",
                         "scormwrapper.js",
                         "dlog.js",
                         "userdata.js",
                         "intersite.js",
                         "exercises.js",
                         "mintscripts.js",
                         "servicescripts.js"],

parameter => {                                        # Benutzeridentifizierung haengt von diesen drei Teilen ab!
  signature_main          => "OBM_VEUNDMINT",         # Identifizierung des Kurses, die drei signature-Teile machen den Kurs eindeutig
  signature_version       => "10000",                 # Versionsnummer, nicht relevant fuer localstorage-userget!
  signature_localization  => "DE_MINT",               # Lokalversion des Kurses, hier die bundesweite MINT-Variante
  do_feedback             => "0",                     # Feedbackfunktionen aktivieren?
  do_export               => "0",                     # Aufgabenexport aktivieren?
  reply_mail              => "admin\@ve-und-mint.de", # Wird in mailto vom Admin-Button eingesetzt
  data_server             => ($server = "https://mintlx3.scc.kit.edu/dbtest"),
  exercise_server         => $server,
  feedback_service        => "$server/feedback.php",  # Absolute Angabe
  data_server_description => "Server 3 (KIT)",        
  data_server_user        => "$server/userdata.php",  # Absolute Angabe
  footer_middle           => "Onlinebrückenkurs Mathematik",
  footer_right            => "Lizenz: CC BY-SA 3.0",
  mainlogo                => "veundmint_netlogo.png", # Im Pfad files/images
  stdmathfont             => "0"                      # Erzwingt Standard-Arial-Font in Text in Formeln
},

# Hash der Form texname => Beschreibung
generate_pdf => {
  tree1_tu9onlinekurs  => "GesamtPDF Onlinekurs"
},

strings => {
  module_starttext    => "Modul starten",
  module_solutionlink => "L&#246;sung ansehen",
  module_solution     => "L&#246;sung",
  module_solutionback => "Zur&#252;ck zur Aufgabe",
},

fonts => {

  # BASICFONTFAMILY  => "Open Sans Condensed"
  BASICFONTFAMILY  => "open-sans"
  # BASICFONTFAMILY =>    "\"HelveticaNeue-Light\", \"Helvetica Neue Light\", \"Helvetica Neue\", Helvetica, Arial, \"Lucida Grande\", Verdana, Arial, Helvetica , sans-serif"
},

sizes =>  {
    CONTENTMINWIDTH =>    800,                    # Breite unter die der content nicht geschrumpft werden kann ohne Scrollbalken zu aktivieren
    MENUWIDTH       =>    ($menuwidth = 160),     # Breite der Menueleiste am linken Rand
    TOCWIDTH        =>     $menuwidth - 21,
    STARTFONTSIZE   =>    ($mybasicfontsize = 16),# Grundlage zur dynamischen Veraenderung der anderen fontsizes
    BASICFONTSIZE   =>     $mybasicfontsize,
    SMALLFONTSIZE   =>     $mybasicfontsize - 2,
    BIGFONTSIZE     =>     $mybasicfontsize + 2
},

colors => {
    CONTENTBACKGROUND => "FFFFFF",
    GENERALBORDER => "A0B0D0",

    TOCBACKGROUND => "7CA5C4",
    TOCFIRSTMENUBACKGROUND => "BFBFBF",
    TOCMENUBACKGROUND => "CFEFCF",
    TOCHOVER => "F2FFF2",
    TOCMENUBORDER => "404040",
    TOCNAVSYMBBACKGROUND => "14D2FF",

    TOCMINBUTTONHOVER => "B6F3FF",
    TOCMINBORDER => "2564AC",
    TOCMINBUTTON => "9EE3FF",
    TOCMINCOLOR => "00528C",
    TOCBORDERCOLOR => "000090",

    XSYMBHOVER => "FAF4FF",
    XSYMB => "C4EDFF",

    HEADBACKGROUND => "00528C",

    NAVIBACKGROUND => "296D9E",
    NAVISELECTED => "4080A0",
    NAVIHOVER => "EBFFFF",

    FOOTBACKGROUND => "2F6C97",

    INFOBACKGROUND => "CBEFFF",
    INFOLINE => "5680E4",

    EXMPBACKGROUND => "FFDCEC",
    EXMPLINE => "EFC2C3",

    EXPEBACKGROUND => "DFDCBC",
    EXPELINE => "CFC2A3",

    HINTBACKGROUND => "E4E4E4",
    HINTBACKGROUNDC => "E0FFE0",
    HINTBACKGROUNDWARN => "C5DFC5",
    HINTLINE => "C4C4C4",

    REPLYBACKGROUND => "E4FFF4",

    LOGINBACKGROUND => "D5D5FF",

    # font colors
    NAVI => ($menucolor = "000090"),
    TOCMINBUTTONCOLOR => $menucolor,
    LOGINCOLOR => "000000",
    FOOT => "202070",
    HEAD => "FFFFFF",
    XSYMBCOLOR => $menucolor,
    TOC => $menucolor,
    TOCSELECTED => "4080A0",
    TOCB => "202070",
    TOCBSELECTED => "D02030",
    CONTENT => "000000",
    CONTENTANCHOR => "483AA1",
    REPLYCOLOR => "000000"
}
  
