README.txt des Repositories ve-und-mint
Autor: Daniel Haase 04/2016

Dies ist der Hauptordner des Repositories ve-und-mint,
es dient der Entwicklung der nicht-öffentlichen Version des
VE&MINT-Onlinebrückenkurses im Rahmen einer TU9-Initiative.


Beschreibung der git-Zweige (branches) im Projekt ve-und-mint:

Hauptzweige:
 - master                     [aktuelle getestete Version von Technik und Inhalt, das eigentliche Projekt]
 - TU9Onlinekurs              [Live-Version des Onlinekurses, FINGER WEG]

Entwicklungszweige:
 - develop_software           [Arbeitsversion der Technik, hier werden Erweiterungen programmiert und Programmfehler korrigiert]
 - develop_content            [Arbeitsversion der Inhalte, hier werden inhaltliche Änderungen in die TeX-Dateien eingepflegt]
 - tuberlin_brueckenkurs      [Arbeitsversion der TU Berlin für den mehrsprachigen Kurs]

Abspaltungen:
 - MatheV4_2015vak            [Der Online-Mathevorkurs V4 für WiIng und TVWL am KIT verwendet gleiche Technik, aber andere Inhalte]
 - hm1test_unihannover_ws2015 [Sonderversion für die Uni Hannover, die nur den Eingangstest des Kurses als eTest vor Ort haben will]
 - develop_python             [Wurde für die Entwicklung der Python-Version des Konverters eingesetzt, ist jetzt obsolet]
 - VMBeta                     [Alte Beta-Version des Onlinekurses, ist jetzt obsolet]
 
Sonstige:
 - playground                 [Hier darf mit dem Code und den Modulen frei herumgespielt werden]

 
Beschreibung der Ordner innerhalb der Zweige:
 - module_veundmint           [Die LaTeX-Quelldateien des Onlinebrückenkurses Mathematik]
 - module_physik              [Die LaTeX-Quelldateien des Onlinebrückenkurses Physik]
 - module_hannovertest        [Quellen für den eTest der Uni Hannover]
 - src                        [Programmcode und Konvertermaterialien]
 - releases                   [Enthält die Releases der Kurse und die Beschreibungsdatei, wird automatisch durch das Programm
                               src/compile_variants.py beschrieben und SOLLTE NICHT MANUELL EDITIERT WERDEN]
 
 
------------------------- Der Autokonverter ---------------------------------------------------------------------

Der Autokonverter kann genutzt werden, um die aktuellen Änderungen im Branch develop_content
zu konvertieren und anzuzeigen: http://mintlx3.scc.kit.edu/autoconverter/autoconv.php

Dort ist immer der aktuelle Konverter hinterlegt, dies ist die bevorzugte Konvertierungsmethode für Autoren.
 
------------------------- Manuelles Konvertieren der Module -----------------------------------------------------

Die Einstellungen für den Kurs finden sich in der Datei src/plugins/VEUNDMINT/Option.py
in dieser stehen alle für das Kurspaket relevanten Daten (tex-Hauptdatei, Bezeichnung,
ob PDF erstellt werden soll, Verbindungsdaten, Farbeinstellungen und vieles mehr).

Der (aktuelle) Python-Konverter wird gestartet mit

python3 tex2x.py VEUNDMINT

innerhalb des Verzeichnisses src [option=wert, ...]

Das Optionen-Objekt wird über eine Zuweisung der Form options=DATEINAME eingestellt,
wird es leer gelassen, so wird das Standardobjekt src/plugins/VEUNDMINT/Option.py genommen
(es gehört zum TU9-Onlinebrückenkurs Mathematik).

Für die Nutzung des Konverters muss python3 installiert sein (mindestens Version 3.4)
sowie die Python-Module GitPython, html5lib, lxml, pytidylib, simplejson (mindestens, ggf. mehr Module).
Diese kann man (als root) mit dem Kommando python3 -m pip install <name>
automatisch installieren lassen.

Beim Aufruf des Konverters können einzelne Optionen überschrieben werden, typische Zusätze sind
python3 tex2x.py VEUNDMINT dopdf=1  [erstellt HTML und PDF gleichzeitig]
python3 tex2x.py VEUNDMINT dotikz=1  [erstellt alle tikz-Dateien neu, auch wenn sie schon im Repository sind]
python3 tex2x.py VEUNDMINT cleanup=0  [löscht nicht die Zwischen- und Hilfsdateien der Übersetzung]
Die Zusätze können kombiniert werden, alle (elementaren) Variablen aus dem Optionen-Objekt
können in dieser Form überschrieben werden.

Der Konverter selbst gibt nur wichtige Fehler- und Informationsmeldungen aus,
eine vollständige Liste aller Meldungen und Zeitangaben werden in die Datei
conversion.log im Hauptverzeichnis geschrieben.

Das Konvertierungstool an sich (tex2struct, tex2x, VE&MINT-Plugins) stehen unter GPL.
Die Makro- und Hilfsdateien für den VE&MINT-Kurs (js/tex/html/css/php-Dateien) stehen unter der LGPL.

------------------------- Alter PERL-Konverter -----------------------------------------------------

Der (veraltete) PERL-Konverter wird gestartet mit

src/mconvert.pl <Parameterdatei>

und erzeugt in der Regel ein Verzeichnis mit dem HTML-Baum.
Er ist seit April 2016 nicht mehr kompatibel zu den Makrobefehlen in mintmod.tex !

DER ALTE PERL-KONVERTER IST NICHT OPEN-SOURCE UND DARF NICHT AN DRITTE WEITERGEGEBEN WERDEN

