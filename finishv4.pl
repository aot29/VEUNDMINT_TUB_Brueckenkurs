# Globale Einstellungen fuer mconvert.pl und conv.pl (sowie die darin eingebundenen modules)

scormlogin      =>      1       , # =1 -> Alle Anmeldesysteme werden deaktiviert, und Teilnehmer ueber SCORM identifiziert
nosols          =>      0       , # =0: Alle Loesungsumgebungen uebersetzen, =1: Loesungsumgebungen nicht uebersetzen wenn SolutionSelect-Pragma aktiviert ist
doscorm         =>      1       , # =0: Kein SCORM, =1 -> SCORM-Manifest und Definitionsdateien miterzeugen, html-Baum kann dann als SCORM-Lernmodul Version 4 verwendet werden, dann muss auch entsprechendes Flag in conv.pl gesetzt werden
qautoexport     =>      0       , # =1 Alle MExercise-Umgebungen werden auch als Export verpackt
diaok           =>      0       , # =1 dia/convert-Kette durchfueren, wenn im Programmablauf auf 0 gesetzt wird dia/convert fuer alle files nicht mehr ausgefuehrt
cleanup         =>      1       , # =1 -> trunk-Verzeichnis wird nach Erstellung entfernt (fuer Releases unbedingt aktivieren)
localjax        =>      0       , # =1 -> lokales MathJax-Verzeichnis wird eingerichtet (andernfalls ist netservice-Flag in conv.pl erforderlich)
borkify         =>      1       , # =1 html und js-Dateien werden borkifiziert
dorelease       =>      1       , # In Release-Versionen werden z.B. bestimmte Logmeldungen unterdrueckt
doverbose       =>      0       , # Schaltet alle Debugmeldungen auf der Browserkonsole an
docollections   =>      0       , # Schaltet Export der collection-Exercises ein (schließt qautoexport und nosols aus)
dopdf           =>      0       , # =1 -> PDF wird erstellt und Downloadbuttons erzeugt
dotikz          =>      0       , # =1 -> TikZ wird aufgerufen um Grafiken zu exportieren, diese werden sofort in den Kurs eingebunden
dozip           =>      0       , # =1 -> html-Baum wird als zip-Datei geliefert (Name muss in output stehen)
output          =>      "mathev4frelease",  # Zielverzeichnis relativ zur Position der Konfigurationsdatei = Aufrufverzeichnis
source          =>      "module_veundmint", # Quellverzeichnis relativ zur Position der Konfigurationsdatei = Aufrufverzeichnis
module          =>      "tree_mathev4.tex", # tex-Hauptdatei des Kurses (relativ zum Quellverzeichnis!)
outtmp          =>      "tmp",              # Temporaeres Verzeichnis im cleanup-Teil des Ausgabeverzeichnisses fuer Erstellungsprozesse fuer mconvert.pl und conv.pl
description     =>      "KIT Onlinevorkurs Mathematik V4 WS 2015/2016"
