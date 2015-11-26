README.txt des Repositories ve-und-mint
Autor: Daniel Haase 2015

Dies ist der Hauptordner des Repositories ve-und-mint,
es dient der Entwicklung der nicht-öffentlichen Version des
VE&MINT-Onlinebrückenkurses im Rahmen einer TU9-Initiative.

Beschreibung der git-Zweige (branches) im Projekt ve-und-mint:

Hauptzweige:
 - master                     [aktuelle getestete Version von Technik und Inhalt, das eigentliche Projekt]
 - TU9Onlinekurs              [Live-Version des Onlinekurses]

Entwicklungszweige:
 - develop                    [Arbeitsversion der Technik, hier werden Erweiterungen programmiert und Programmfehler korrigiert]
 - develop_content            [Arbeitsversion der Inhalte, hier werden inhaltliche Änderungen in die TeX-Dateien eingepflegt]

Abspaltungen:
 - VMBeta                     [Alte Beta-Version des Onlinekurses]
 - MatheV4_2015vak            [Der Online-Mathevorkurs V4 für WiIng und TVWL am KIT verwendet gleiche Technik, aber andere Inhalte]
 - hm1test_unihannover_ws2015 [Sonderversion für die Uni Hannover, die nur den Eingangstest des Kurses als eTest vor Ort haben will]

 
 Beschreibung der Ordner innerhalb der Zweige:
 - module_veundmint           [Die LaTeX-Quelldateien des Projekts, neben den TU9-Modulen noch einige Sondermodule]
 - module_hannovertest        [Quellen für den eTest der Uni Hannover]
 - converter                  [Programmcode und Konvertermaterialien]
 
 
Jedes Kurspaket hat eine Parameterdatei im Hauptordner, z.B. tu9onlinekurs_test.pl
in dieser stehen alle für das Kurspaket relevanten Daten (tex-Hauptdatei,
Bezeichnung, ob PDF erstellt werden soll, Verbindungsdaten, Farbeinstellungen und vieles mehr).

Der Konverter wird (unter Linux) gestartet mit

converter/mconvert.pl <Parameterdatei>

und erzeugt in der Regel ein Verzeichnis mit dem HTML-Baum.
