"""    
    VEUNDMINT plugin package
    Copyright (C) 2016  VE&MINT-Projekt - http://www.ve-und-mint.de

    The VEUNDMINT plugin package is free software; you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation; either version 3 of the License, or (at your
    option) any later version.

    The VEUNDMINT plugin package is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
    License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with the VEUNDMINT plugin package. If not, see http://www.gnu.org/licenses/.
"""

import os.path
import json
import sys

from plugins.VEUNDMINT.logging import Logging

class Option(object):
    """
    Tex2x lässt sich vielfältig konfigurieren. Da eine Konfiguration über Kommandozeilen-Parameter den Rahmen
    bei Weitem sprengen würde, ist die Options-Klasse angelegt worden, um die Optionen vor dem Start bequem in
    einem Texteditor nach den eigenen Bedürfnissen anpassbar zu machen. Grob schlüsseln sich die verfügbaren Optionen
    wie folgt auf
    
    * Debug Ausgabe ein-/ausschalten
    
    * Quellordner angeben
    
    * Inhaltsstruktur der Quelle festlegen
    
    Diese Angaben beziehen sich auf die Structure-Klasse. Da eingebundene Plug-ins unter anderen Lizenzen als der GPL veröffentlicht werden können, darf hier kein Austausch stattfinden.
    """
    
    def __init__(self, currentDir):
        
        #Debugging
        self.DEBUG = True
        
        self.currentDir = os.path.abspath(currentDir) # typically one level above location of tex2x.py
        self.converterDir = os.path.join(self.currentDir, "src")
        self.logFilename = "conversion.log"
        
        # VE&MINT conversion flags, using values 0 and 1 (integers)
        self.testonly = 0
        self.scormlogin = 0
        self.nosols =  0          # =0: Alle Loesungsumgebungen uebersetzen, =1: Loesungsumgebungen nicht uebersetzen wenn SolutionSelect-Pragma aktiviert ist
        self.doscorm = 0          # =0: Kein SCORM, =1 -> SCORM-Manifest und Definitionsdateien miterzeugen, html-Baum kann dann als SCORM-Lernmodul Version 4 verwendet werden, dann muss auch entsprechendes Flag in conv.pl gesetzt werden
        self.qautoexport = 0      # =1 Alle MExercise-Umgebungen werden auch als Export verpackt
        self.diaok = 0            # =1 dia/convert-Kette durchfueren, wenn im Programmablauf auf 0 gesetzt wird dia/convert fuer alle files nicht mehr ausgefuehrt
        self.cleanup = 1          # =1 -> trunk-Verzeichnis wird nach Erstellung entfernt (fuer Releases unbedingt aktivieren)
        self.localjax = 0         # =1 -> lokales MathJax-Verzeichnis wird eingerichtet (andernfalls ist netservice-Flag in conv.pl erforderlich)
        self.borkify = 0          # =1 html und js-Dateien werden borkifiziert
        self.dorelease = 0        # In Release-Versionen werden Flag-Kombinationen erzwungen und Logmeldungen unterdrueckt
        self.doverbose = 0        # Schaltet alle Debugmeldungen auf der Browserkonsole an, =0 -> gehen nur in log-Datei
        self.docollections = 0    # Schaltet Export der collection-Exercises ein (schließt qautoexport und nosols aus)
        self.dopdf = 0            # =1 -> PDF wird erstellt und Downloadbuttons erzeugt
        self.dotikz = 0           # =1 -> TikZ wird aufgerufen um Grafiken zu exportieren, diese werden sofort in den Kurs eingebunden
        self.dozip = 0            # =1 -> html-Baum wird als zip-Datei geliefert (Name muss in output stehen)
        self.consolecolors = 1    # =1 -> Ausgabe der Meldungen auf der Konsole wird eingefaerbt
        
        # VE&MINT source/target parameters
        self.macrofilename = "mintmod"
        self.macrofile = self.macrofilename + ".tex"
        self.stdencoding = "iso-8859-1"                      # Presumed encoding of tex and html files
        self.output = "tu9onlinekurstest"                    # Zielverzeichnis, platziert in Ebene ueber tex2x.py, wird neu erzeugt
        self.source = "module_veundmint"                     # Quellverzeichnis, platziert in Ebene ueber tex2x.py
        self.module = "tree_tu9onlinekurs.tex"               # tex-Hauptdatei des Kurses (relativ zum Quellverzeichnis!) fuer HTML-Erzeugung
        self.outtmp = "_tmp"                                 # Temporaeres Verzeichnis im cleanup-Teil des Ausgabeverzeichnisses fuer Erstellungsprozesse fuer mconvert.pl und conv.pl
        self.description = "Onlinebrückenkurs Mathematik"    # Bezeichnung des erstellen Kurses
        self.author = "Projekt VE&MINT"                      # Offizieller Autor des Kurses           
        self.contentlicense = "CC BY-SA 3.0"                 # Lizenz des Kursinhalts
        self.moduleprefix = "Onlinebrückenkurs Mathematik"   # Wird vor Browser-Bookmarks gesetzt
        self.variant = "std"                                 # zu erzeugende Varianten der HTML-files, "std" ist die Hauptvariante, waehlt Makropakete fuer Mathematikumsetzung aus, Alternative ist "unotation"

        self.generate_pdf = { "tree1_tu9onlinekurs": "GesamtPDF Onlinekurs" } # dict der Form tex-name: Bezeichnung

        # Settings for HTML design and typical phrases        
        self.strings = {
            "module_starttext": "Modul starten",
            "module_solutionlink": "L&#246;sung ansehen",
            "module_solution": "L&#246;sung",
            "module_solutionback": "Zur&#252;ck zur Aufgabe"
        }

        self.fonts = {
            # BASICFONTFAMILY  => "Open Sans Condensed"
            "BASICFONTFAMILY": "open-sans"
            # BASICFONTFAMILY =>    "\"HelveticaNeue-Light\", \"Helvetica Neue Light\", \"Helvetica Neue\", Helvetica, Arial, \"Lucida Grande\", Verdana, Arial, Helvetica , sans-serif"
        }
        
        menuwidth = 160
        mybasicfontsize = 16
        self.sizes = {
            "CONTENTMINWIDTH": 800,                # Breite unter die der content nicht geschrumpft werden kann ohne Scrollbalken zu aktivieren
            "MENUWIDTH": menuwidth,                # Breite der Menueleiste am linken Rand
            "TOCWIDTH": menuwidth - 21,
            "STARTFONTSIZE": mybasicfontsize,      # Grundlage zur dynamischen Veraenderung der anderen fontsizes
            "BASICFONTSIZE": mybasicfontsize,
            "SMALLFONTSIZE": mybasicfontsize - 2,
            "BIGFONTSIZE": mybasicfontsize + 2
        }

        # Farbpalette wird aus JSON-Datei eingelesen
        with open(os.path.join(self.converterDir, "plugins", "VEUNDMINT", "colorset_blue.json")) as colorfile:
            self.colors = json.load(colorfile)

        # VE&MINT stylesheets und JS-files, die in jeder HTML-Datei eingebunden werden, Dateiangaben relativ zum files-Ordner
        self.stylesheets  = [
            "qtip2/jquery.qtip.min.css",
            "datatables/min.css"
        ]
        self.scriptheaders = [
            "es5-sham.min.js",
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
            "servicescripts.js"
        ]

        # VE&MINT course parameters, defining values used by the online course
        server = "https://mintlx3.scc.kit.edu/dbtest"
        self.signature_main = "OBM_VEUNDMINT"         # Identifizierung des Kurses, die drei signature-Teile machen den Kurs eindeutig
        self.signature_version = "10000"              # Versionsnummer, nicht relevant fuer localstorage-userget!
        self.signature_localization = "DE_MINT"       # Lokalversion des Kurses, hier die bundesweite MINT-Variante
        self.do_feedback = "0"                        # Feedbackfunktionen aktivieren? DOPPLUNG MIT FLAGS
        self.do_export = "0"                          # Aufgabenexport aktivieren? DOPPLUNG MIT FLAGS
        self.reply_mail = "admin@ve-und-mint.de"      # Wird in mailto vom Admin-Button eingesetzt
        self.data_server = server                  
        self.exercise_server = server
        self.feedback_service = server + "/feedback.php" # Absolute Angabe
        self.data_server_description = "Server 3 (KIT)"        
        self.data_server_user = server + "/userdata.php"  # Absolute Angabe
        self.footer_middle = self.description
        self.footer_right = "Lizenz: " + self.contentlicense
        self.mainlogo = "veundmint_netlogo.png" # Im Pfad files/images
        self.stdmathfont = "0" # Erzwingt Standard-Arial-Font in Text in Formeln

        # variables used by the OSS converter, should not be changed directly as they take input from the above definitions
        self.parserName = "lxml"
        self.converterCommonFiles = os.path.join(self.converterDir, "files") # Bedeutung von sourceCommonFiles vom OSS-Konverter ist anders
        self.texCommonFiles = os.path.join(self.converterDir, "tex") 
        self.sourcepath_original = os.path.join(self.currentDir, self.source) # Pfad zu den Quellen (werden readonly behandelt)
        self.sourcepath = os.path.join(self.currentDir, self.outtmp) # Pfad in dem gearbeitet wird
        self.sourceTEX = os.path.join(self.sourcepath, "tex") # Teilpfad in dem die LaTeX-Quellenkopien liegen
        self.sourceTEXStartFile = os.path.join(self.sourceTEX, self.module)
        self.targetpath = os.path.join(self.currentDir, self.output) # Pfad in den der generierte Kurs kommt
        
        # ttm-file
        self.ttmPath = os.path.join(self.converterDir, "ttm-original")
        self.ttmExecute = True
        self.ttmFile = os.path.join(self.targetpath, "vorkursxml.xml")
        
        # ContentStructure
        self.ContentStructure=[]
        self.ContentStructure.append("h1")
        self.ContentStructure.append("h2")
        self.ContentStructure.append("h3")
        #self.ContentStructure.append("div")#Container werden nun über Attribute identifiziert
        
        # ModuleStructure
        self.ModuleStructure=[]

        
        # ModuleStructure
        self.ModuleStructureClass= "xcontent"#nach dieser klasse wird gesucht, um Modulbereiche zu identifizieren. (Dann jeweils mit einer Nummer dahinter)

        
        #use these Plugins (plugin path must be listed below within the plugin settings!)
        self.usePlugins = [ "HTML5" ]
        self.pluginPath = { "HTML5": os.path.join(self.converterDir, "plugins", "VEUNDMINT", "VEUNDMINT_html5.py") }
        
