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

"""
    This is the Option object associated to the mintmod macro package, 
    Version P0.1.0, needs to be consistent with mintmod.tex
    Options for the math online course
"""

import os.path
import json
import re
import locale
from git import Repo
import sys

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
    
    def __init__(self, currentDir, override):
        
        #Debugging
        self.DEBUG = True
        
        self.currentDir = os.path.abspath(currentDir) # one level above location of tex2x.py
        self.converterDir = os.path.join(self.currentDir, "src")
        self.logFilename = "conversion.log"
        self.locale = "de_DE" # define Pythons locale (impact for example on sorting umlauts), should be set to locale of course language, string definition depends on used system!
        locale.setlocale(locale.LC_ALL, self.locale)
        
        # VE&MINT conversion flags, using values 0 and 1 (integers)
        self.testonly = 0
        self.scormlogin = 0
        self.nosols =  0          # =0: Alle Loesungsumgebungen uebersetzen, =1: Loesungsumgebungen nicht uebersetzen wenn SolutionSelect-Pragma aktiviert ist
        self.doscorm = 0          # =0: Kein SCORM, =1 -> SCORM-Manifest und Definitionsdateien miterzeugen, html-Baum kann dann als SCORM-Lernmodul Version 4 verwendet werden, dann muss auch entsprechendes Flag in conv.pl gesetzt werden
        self.qautoexport = 0      # =1 Alle MExercise-Umgebungen werden auch als Export verpackt
        self.diaok = 0            # =1 dia/convert-Kette durchfueren, wenn im Programmablauf auf 0 gesetzt wird dia/convert fuer alle files nicht mehr ausgefuehrt
        self.cleanup = 1          # =1 -> trunk-Verzeichnis wird nach Erstellung entfernt (fuer Releases unbedingt aktivieren)
        self.localjax = 1         # =1 -> lokales MathJax-Verzeichnis wird eingerichtet (andernfalls ist netservice-Flag in conv.pl erforderlich)
        self.borkify = 0          # =1 html und js-Dateien werden borkifiziert
        self.dorelease = 0        # In Release-Versionen werden Flag-Kombinationen erzwungen und Logmeldungen unterdrueckt
        self.doverbose = 0        # Schaltet alle Debugmeldungen auf der Browserkonsole an, =0 -> gehen nur in log-Datei
        self.docollections = 0    # Schaltet Export der collection-Exercises ein (schließt qautoexport und nosols aus)
        self.dopdf = 0            # =1 -> PDF wird erstellt und Downloadbuttons erzeugt
        self.dotikz = 0           # =1 -> TikZ wird aufgerufen um Grafiken zu exportieren, diese werden sofort in den Kurs eingebunden
        self.dozip = 0            # =1 -> html-Baum wird als zip-Datei geliefert (Name muss in output stehen)
        self.consolecolors = 1    # =1 -> Ausgabe der Meldungen auf der Konsole wird eingefaerbt
        self.consoleascii = 0     # =1 -> Only us-ascii strings are printed to the console (or pipes), does not affect written files
        self.forceyes = 1         # =1 -> Questions asked interactively (like if a directory should be overwritten) will be assumed to be answered with "yes"
        self.symbolexplain = 1    # =1 -> Short list explaining symbols is added to table of contents
        self.forceoffline = 1     # =1 -> code acts as if no internet connection to anything is present (excluding direct links from content and MathJax loads)
        self.quiet = 0            # =1 -> Absolutely no print messages, caller must deduce outcome by return value of sys.exit
        
        # VE&MINT source/target parameters
        self.macrofilename = "mintmod"
        self.macrofile = self.macrofilename + ".tex"
        self.stdencoding = "iso-8859-1"                      # Presumed encoding of tex files and templates, utf8 well be accepted too but with a warning
        self.outputencoding = "utf-8"                        # encoding of generated html files
        self.output = "tu9onlinekurstest"                    # Zielverzeichnis, platziert in Ebene ueber tex2x.py, wird neu erzeugt, WIRD BEI AUTOPUBLISH UEBERSCHRIEBEN
        self.source = "module_veundmint"                     # Quellverzeichnis, platziert in Ebene ueber tex2x.py
        self.module = "tree_tu9onlinekurs.tex"               # tex-Hauptdatei des Kurses (relativ zum Quellverzeichnis!) fuer HTML-Erzeugung
        self.outtmp = "_tmp"                                 # Temporaeres Verzeichnis im cleanup-Teil des Ausgabeverzeichnisses fuer Erstellungsprozesse fuer mconvert.pl und conv.pl
        self.description = "Onlinebrückenkurs Mathematik"    # Bezeichnung des erstellen Kurses
        self.author = "Projekt VEUNDMINT"                    # Offizieller Autor des Kurses           
        self.contentlicense = "CC BY-SA 3.0"                 # Lizenz des Kursinhalts
        self.moduleprefix = "Onlinebrückenkurs Mathematik"   # Wird vor Browser-Bookmarks gesetzt
        self.variant = "std"                                 # zu erzeugende Varianten der HTML-files, "std" ist die Hauptvariante, waehlt Makropakete fuer Mathematikumsetzung aus, Alternative ist "unotation"
        self.accessflags = "777"                             # linux access flag preset for the entire output directory

        self.mathjaxtgz = "mathjax26complete.tgz"
        self.texstylefiles = ["bibgerm.sty", "maxpage.sty"]  # style files needed in local directories for local pdflatex compilation
        self.htmltikzscale = 1.3                             # scaling factor used for tikz-png scaling, can be overridden by pragmas
        self.autotikzcopyright = 1                           # includes tikz externalized images in copyright list
        self.displaycopyrightlinks = 0                       # add copyright links to images in the entire course

        self.generate_pdf = { "veundmintkurs": "GesamtPDF Onlinekurs" } # dict der Form tex-name: Bezeichnung (ohne Endung)

        # course signature, course part
        self.signature_main = "OBMLGAMMA5" # OBM_LGAMMA_0 "OBM_PTEST8", "OBM_VEUNDMINT"         # Identifizierung des Kurses, die drei signature-Teile machen den Kurs eindeutig
        self.signature_version = "10000"              # Versionsnummer, nicht relevant fuer localstorage-userget!
        self.signature_localization = "DE-MINT"       # Lokalversion des Kurses, hier die bundesweite MINT-Variante
        self.signature_date = "05/2015"

       # ---------------------- check for overrides, options declared past this block will not be subject to override command line parameters ------------------------ 
        self.overrides = list()
        for ov in override:
            m = re.match(r"(.+?)=(.+)", ov) 
            if m:
                if m.group(1) == "options":
                    print("Option selection: " + m.group(2))
                    # options override was processed in struct object before Options were loaded
                else:
                    self.overrides.append([m.group(1), m.group(2)])
                    if hasattr(self, m.group(1)):
                        vr = getattr(self, m.group(1))
                        if (type(vr).__name__ == "int"):
                            setattr(self, m.group(1), int(m.group(2)))
                        else:
                            if (type(vr).__name__ == "str"):
                                setattr(self, m.group(1), m.group(2))
                            else:
                                if (type(vr).__name__ == "float"):
                                    setattr(self, m.group(1), float(m.group(2)))
                                else:
                                    if (type(vr).__name__ == "bool"):
                                        if (m.group(2) == "0"):
                                            setattr(self, m.group(1), False)
                                        else:
                                            setattr(self, m.group(1), True)
                                    else:
                                        print("Option type " + type(vr).__name__ + " not acceptable")
                    else:
                        print("Option " + m.group(1) + " does not exist, cannot override")
                
            else:
                print("Invalid override string: " + ov)


         # Settings for HTML design and typical phrases        
        self.chaptersite = "chapters.html"
        self.strings = {
            "explanation_subsection": "Einführung in Thema",
            "explanation_xcontent": "Lernabschnitt",
            "explanation_exercises": "Übungsaufgaben",
            "explanation_test": "Abschlusstest",
            "chapter": "Kapitel",
            "subsection": "Abschnitt",
            "module_starttext": "Modul starten: ",
            "module_solutionlink": "Lösung ansehen",
            "module_solution": "Lösung",
            "module_solutionback": "Zurück zur Aufgabe",
            "module_content": "Kursinhalt",
            "module_moreinfo": "Mehr Informationen",
            "module_helpsitetitle": "Einstiegsseite",
            "module_labelprefix": "Modul",
            "subsection_labelprefix": "Abschnitt",
            "subsubsection_labelprefix": "Unterabschnitt",
            "exercise_labelprefix": "Aufgabe",
            "example_labelprefix": "Beispiel",
            "experiment_labelprefix": "Experiment",
            "image_labelprefix": "Abbildung",
            "table_labelprefix": "Tabelle",
            "equation_labelprefix": "Gleichung",
            "theorem_labelprefix": "Satz",
            "video_labelprefix": "Video",
            "brokenlabel": "(VERWEIS)",
            "feedback_sendit": "Meldung abschicken",
            "qexport_download_tex": "Quellcode dieser Aufgabe im LaTeX-Format",
            "qexport_download_doc": "Quellcode dieser Aufgabe im Word-Format",
            "message_done": "Alle Aufgaben gelöst",
            "message_progress": "Aufgaben teilweise gelöst",
            "message_problem": "Einige Aufgaben falsch beantwortet",
            "modstartbox_tocline": "Dieses Modul gliedert sich in folgende Abschnitte:",
            "roulette_text": "In der Onlineversion erscheinen hier Aufgaben aus einer Aufgabenliste"
        }
        
        self.knownmathcommands = [ "sin", "cos", "tan", "cot", "log", "ln", "exp" ] # these will be excluded from post-ttm modifications
        self.mathmltags = [ "math", "mo", "mi", "mrow", "mstyle", "msub", "mn", "mtable", "msup", "mtext", "mfrac", "msqrt", "mover" ]
        self.specialtags = [ "tocnavsymb"] + self.mathmltags # these will be excluded from libtidy error detection
        
        self.fonts = {
            # BASICFONTFAMILY  => "Open Sans Condensed"
            "BASICFONTFAMILY": "open-sans",
            # only used if stdmathfont is on:
            "STDMATHFONTFAMILY": "\'HelveticaNeue-Light\', \'Helvetica Neue Light\', \'Helvetica Neue\', Helvetica, Arial, \'Lucida Grande\', Verdana, Arial, Helvetica , sans-serif"
        }
        
        menuwidth = 160 + 15 # 160px for the table of contents, 15px to accomodate a vertical scrollbar should it appear inside toc
        mybasicfontsize = 16
        headheight = 30
        naviheight = 60
        self.sizes = {
            "CONTENTMINWIDTH": 800,                # Breite unter die der content nicht geschrumpft werden kann ohne Scrollbalken zu aktivieren
            "MENUWIDTH": menuwidth,                # Breite der Menueleiste am linken Rand
            "TOCWIDTH": menuwidth - 21,
            "HEADHEIGHT": headheight,
            "NAVIHEIGHT": naviheight,
            "TOCTOP": headheight + naviheight,
            "FOOTERHEIGHT": 20,
            "STARTFONTSIZE": mybasicfontsize,      # Grundlage zur dynamischen Veraenderung der anderen fontsizes
            "BASICFONTSIZE": mybasicfontsize,
            "TINYFONTSIZE": mybasicfontsize - 4,
            "SMALLFONTSIZE": mybasicfontsize - 2,
            "BIGFONTSIZE": mybasicfontsize + 2
        }

        # Read color settings from a json file
        with open(os.path.join(self.converterDir, "plugins", "VEUNDMINT", "colorset_blue.json")) as colorfile:
            self.colors = json.load(colorfile)

        # course signature, repository part
        repo = Repo(self.currentDir)
        assert not repo.bare
        
        if repo.is_dirty():
            self.signature_git_dirty = 1
        else:
            self.signature_git_dirty = 0
        
        h = repo.head
        hc = h.commit
        self.signature_git_head = h.name
        self.signature_git_branch = repo.active_branch.name
        self.signature_git_committer = hc.committer.name
        self.signature_git_message = hc.message.replace("\n", "")
        self.signature_git_commit = hc.hexsha
        
        
        # VE&MINT course parameters, defining values used by the online course
        server = "https://mintlx3.scc.kit.edu/dbtest"
        self.do_feedback = "0"                        # Feedbackfunktionen aktivieren? DOPPLUNG MIT FLAGS
        self.do_export = "0"                          # Aufgabenexport aktivieren? DOPPLUNG MIT FLAGS
        self.reply_mail = "admin@ve-und-mint.de"      # Wird in mailto vom Admin-Button eingesetzt
        self.data_server = server                  
        self.exercise_server = server
        self.feedback_service = server + "/feedback.php" # Absolute Angabe
        self.data_server_description = "Server 3 (KIT)"        
        self.data_server_user = server + "/userdata.php"  # Absolute Angabe
        self.footer_middle = self.description
        # don't use \" in strings as they are being passed to JavaScript variables (and \" becomes evaluated)
        self.footer_left = "<img src='images/ccbysa80x15.png' border='0' />"
        
        self.footer_right = "<a href='mailto:" + self.reply_mail + "' target='_new'><div style='display:inline-block' class='tocminbutton'>Mail an Admin</div></a>"
        self.mainlogo = "veundmint_netlogo.png" # Im Pfad files/images
        self.tocchapters = 0 # =1 -> display chapter links in table of contents
        self.stdmathfont = "0" # Erzwingt Standard-Arial-Font in Text in Formeln

        # variables used by the OSS converter, should not be changed directly as they take input from the above definitions
        self.parserName = "lxml"
        self.converterCommonFiles = os.path.join(self.converterDir, "files") # Bedeutung von sourceCommonFiles vom OSS-Konverter ist anders
        self.texCommonFiles = os.path.join(self.converterDir, "tex") 
        self.sourcepath_original = os.path.join(self.currentDir, self.source) # directory to original source (strictly read only, except if amendsource is active)
        self.sourcepath = os.path.join(self.currentDir, self.outtmp) # Pfad in dem gearbeitet wird
        self.sourceTEX = os.path.join(self.sourcepath, "tex") # Teilpfad in dem die LaTeX-Quellenkopien liegen
        self.sourceTEXStartFile = os.path.join(self.sourceTEX, self.module) 
        self.targetpath = os.path.join(self.currentDir, self.output) # Pfad in den der generierte Kurs kommt
        self.copyrightFile = os.path.join(self.sourceTEX, "copyrightcollection.tex")
        self.directexercisesFile = os.path.join(self.sourcepath, "directexercises.tex")
        self.convinfofile = "convinfo.js"

        # HTML/JS/CSS template options
        self.template_precss = "precss"
        self.converterTemplates = os.path.join(self.converterDir, "templates") # Vorlagen fuer HTML-Dateien
        self.template_html5 = os.path.join(self.converterTemplates, "html5_mintmodtex.html")
        self.template_javascriptheader = os.path.join(self.converterTemplates, "html5_javascriptheader.html")
        self.template_javascriptfooter = os.path.join(self.converterTemplates, "html5_javascriptfooter.html")
        self.template_mathjax_settings = os.path.join(self.converterTemplates, "mathjax_settings.html")
        self.template_mathjax_cdn = os.path.join(self.converterTemplates, "mathjax_cdn_2_6.html")
        self.template_mathjax_local = os.path.join(self.converterTemplates, "mathjax_local_2_6.html")
        self.template_redirect_scorm = os.path.join(self.converterTemplates, "html5_redirect_scorm.html")
        self.template_redirect_basic = os.path.join(self.converterTemplates, "html5_redirect_basic.html")
        self.template_settings = os.path.join(self.converterTemplates, "html5_settings.html")

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
            self.convinfofile,
            "mparser.js",
            "scormwrapper.js",
            "dlog.js",
            "userdata.js",
            "intersite.js",
            "exercises.js",
            "mintscripts.js",
            "servicescripts.js"
        ]

        # javascript files to be minimized if borkify is active, relative to converterDir
        self.jstominimize = [
            self.convinfofile,
            "userdata.js",
            "intersite.js",
            "exercises.js",
            "mintscripts.js",
            "servicescripts.js"
        ]

        # ttm-file
        self.ttmExecute = True
        self.ttmPath = os.path.join(self.converterDir, "ttm")
        self.ttmFile = os.path.join(self.sourceTEX, "targetxml.xml")
        
        # optimization options
        self.nolinkcorrection = 1
        self.keepequationtables = 1
        
        # ContentStructure
        self.contentlevel = 4 # level used by tcontent objects from subsubsections (MXContent)
        self.ContentStructure=[]
        self.ContentStructure.append("h1") # the whole course
        self.ContentStructure.append("h2") # a section in the course, a MSection according to MINTMOD
        self.ContentStructure.append("h3") # a subsection in the coursre, MSubsection according to MINTMOD
        self.ContentStructure.append("h4") # used for subsection introduction inside xcontents
        #self.ContentStructure.append("div")#Container werden nun über Attribute identifiziert
        
        # special site tags
        self.sitetaglist = ["chapter", "config", "data", "favorites", "location", "search", "test"]
        
        # ModuleStructure
        self.ModuleStructure = []
        self.ModuleStructureClass= "xcontent" #nach dieser klasse wird gesucht, um Modulbereiche zu identifizieren. (Dann jeweils mit einer Nummer dahinter)

        
        # use these Plugins (plugin path must be listed below within the plugin settings!)
        self.usePreprocessorPlugins = [ "PRE_MINTMODTEX" ]
        self.useOutputPlugins = [ "HTML5_MINTMODTEX" ] # name is also postfix of template files used by the plugin
        self.pluginPath = { 
            "PRE_MINTMODTEX": os.path.join(self.converterDir, "plugins", "VEUNDMINT", "preprocessor_mintmodtex.py"),
            "HTML5_MINTMODTEX": os.path.join(self.converterDir, "plugins", "VEUNDMINT", "html5_mintmodtex.py")
        }
        
        if self.dopdf == 1:
            self.footer_left += "<a href='veundmintkurs.pdf' target='_new'><img src='images/pdfmini.png' border='0' /></a>"

        if self.symbolexplain == 1:
            self.tocadd = "<ul class=\"legende\">" \
                        + "<li><strong>LEGENDE</strong></li>" \
                        + "<li><div class=\"xsymb\">1.1</div>" + self.strings['explanation_subsection'] + "<br/></li>" \
                        + "<li><div class=\"xsymb status1\"></div>" + self.strings['explanation_xcontent'] + "</li>" \
                        + "<li><div class=\"xsymb status2\"></div>" + self.strings['explanation_exercises'] + "</li>" \
                        + "<li><div class=\"xsymb status3\"></div>" + self.strings['explanation_test'] + "</li>" \
                        + "</ul>"
        else:
            self.tocadd = ""

                
        self.check_consistency()

   
    # checks if given option values (including overrides) are consistent
    def check_consistency(self):
        for p in [ self.converterCommonFiles, self.texCommonFiles, self.sourcepath_original ]:
            if not os.path.isdir(p):
                print("FATAL ERROR: Mandatory directory not found: " + p + ", aborting program with error code 1")
                sys.exit(1)
                
        if self.docollections == 1:
            if (self.nosols == 1) or (self.qautoexport == 1) or (self.cleanup == 1):
                print("FATAL ERROR: Option docollections=1 cannot be used with nosols, qautoexport or cleanup flags, aborting with error code 1")
                sys.exit(1)

        if self.dorelease == 1:
            if (self.signature_git_dirty == 1):
                print("INFO:    git repository is not clean, please commit everything for a clean release")
            if (self.cleanup != 1) or (self.docollections == 1) or (self.doverbose == 1) or (self.dotikz == 0) or (self.borkify == 0) or (self.forceoffline == 1):
                print("FATAL ERROR: Option dorelease=1 cannot be used with cleanup=0, docollections=1, dotikz=0, borkify=0, forceoffline=1 or doverbose=1, aborting with error code 1")
                sys.exit(1)

        if self.scormlogin == 1:
            if self.doscorm == 0:
                print("FATAL ERROR: Option scormlogin is detrimental if doscorm is not active, aborting with error code 1")
                sys.exit(1)
                
