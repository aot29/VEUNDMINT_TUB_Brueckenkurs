## @package tex2x.dispatcher.Dispatcher
#	This is the Option object associated to the mintmod macro package,
#	Version P0.1.0, needs to be consistent with mintmod.tex
#	Options for the math online course
#
#  \copyright tex2x converter - Processes tex-files in order to create various output formats via plugins
#  Copyright (C) 2014  VEMINT-Konsortium - http://www.vemint.de
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#  \author Daniel Haase for KIT
#  \author Alvaro Ortiz for TU Berlin

import os
import json
import re
import locale
from git import Repo
import sys
import platform

class Option(object):
	"""
	Tex2x lässt sich vielfältig konfigurieren. Da eine Konfiguration über Kommandozeilen-Parameter den Rahmen
	bei Weitem sprengen würde, ist die Options-Klasse angelegt worden, um die Optionen vor dem Start bequem in
	einem Texteditor nach den eigenen Bedürfnissen anpassbar zu machen. Grob schlüsseln sich die verfügbaren Optionen
	wie folgt auf:
	* Debug Ausgabe ein-/ausschalten
	* Quellordner angeben
	* Inhaltsstruktur der Quelle festlegen

	Diese Angaben beziehen sich auf die Structure-Klasse. Da eingebundene Plug-ins unter anderen Lizenzen als der GPL veröffentlicht werden können, darf hier kein Austausch stattfinden.
	"""

	def __init__(self, currentDir="", override=None):
		"""
		Constructor
		Instantiated in tex2x.dispatcher.Dispatcher

		@param currentDir - string path to the dir where tex2x is executed (is set in the Dispatcher), one level above location of tex2x.py.
		@param override - string key value pairs override options
		"""

		import settings as new_settings

		#Debugging
		self.DEBUG = False

		#
		# common vars on which the other vars depend. Set constructor.
		#

		## @var currentDir
		#  string path to the dir where tex2x is executed (is set in the Dispatcher), one level above location of tex2x.py.
		self.currentDir = new_settings.BASE_DIR
		self.converterDir = os.path.join(self.currentDir, "src")
		self.converterCommonFiles = os.path.join(self.converterDir, "files")
		self.pluginName = "VEUNDMINT_TUB"
		self.pluginDir = os.path.join(self.converterDir, "plugins", self.pluginName)

		## @var output
		#  Zielverzeichnis, platziert in Ebene ueber tex2x.py, wird neu erzeugt, WIRD BEI AUTOPUBLISH UEBERSCHRIEBEN
		self.output = "build"

		## @var source
		#  Quellverzeichnis, platziert in Ebene ueber tex2x.py
		self.source = os.path.join("content_submodule", "content")

		## @var outtmp
		# Temporaeres Verzeichnis im cleanup-Teil des Ausgabeverzeichnisses fuer Erstellungsprozesse fuer mconvert.pl und conv.pl
		self.outtmp = "_tmp"
		self.logFilename = "conversion.log"
		self.override = override
		self.server = "https://guest6.mulf.tu-berlin.de/server/dbtest"

		# always call setLocale first
		self.setLocale()

		## @var module
		#  Tree depends on language requested
		self.module = ( lambda locale: "tree_en.tex" if locale == 'en_GB.utf8' or locale == 'en_GB.UTF-8' else "tree_de.tex" ) (self.locale)

		self.overrideValues() # need to call overrideValues before AND after, as some values are put together, e.g. in setConverterVars
		self.setDispatcherPipeline()
		self.setConversionFlags()
		self.setTest()
		self.setSourceOutputDirs()
		self.setSignature()
		self.setGitSignature()
		self.setServerValues()
		self.setConverterVars()
		self.setTemplates()
		self.setTTM()
		self.setTags()
		self.setPluginOptions()
		self.setConverterVars()
		self.overrideValues() # need to call overrideValues before AND after, as some values are put together, e.g. in setConverterVars

		self.checkConsistency() # call checkConsistency LAST


	def setDispatcherPipeline(self):
		"""
		Dispatcher settings
		
		  Pipeline lists the steps in the dispatcher.
		  1. Preprocessors: Run pre-processing plugins
		  2. Translator: Run TTM (convert Tex to XML), load XML file created by TTM, 
		  3. Parser: Parse XML files into a HTML tree
		  4. Generator: Create the table of contents (TOC) and content tree, correct links
		  5. Plugins: Output to static HTML files
		
		  Steps 1 and 5 may have multiple classes.
		  Steps 2,3,4 may be decorated.
		
		 Put the complete class path here, so for example:
		 if you have a plug-in called VEUNDMINT and a file called preprocessor_mintmodtex.py which holds a class called Preprocessor,
		 then the path is plugins.VEUNDMINT.preprocessor_mintmodtex.Preprocessor.
		"""
		self.pipeline = {
				"preprocessors": [ 'plugins.VEUNDMINT_TUB.preprocessors.PrepareData.PrepareData', 
								   'plugins.VEUNDMINT_TUB.preprocessors.PrepareWorkingFolder.PrepareWorkingFolder',
								   'plugins.VEUNDMINT_TUB.preprocessors.FixI18nForPdfLatex.FixI18nForPdfLatex',
								   'plugins.VEUNDMINT_TUB.preprocessors.preprocessor_mintmodtex.Preprocessor',
		   						   'plugins.VEUNDMINT_TUB.preprocessors.ReleaseCheck.ReleaseCheck' ],
				
				"translator": "plugins.VEUNDMINT_TUB.translators.TTMTranslator.TTMTranslator",
		
				"translatorDecorators": [ "plugins.VEUNDMINT_TUB.translators.MathMLDecorator.MathMLDecorator" ],
				
				"parser": "plugins.VEUNDMINT_TUB.parsers.HTMLParser.HTMLParser",
		
				"parserDecorators": [],
				
				"generator": "plugins.VEUNDMINT_TUB.generators.ContentGenerator.ContentGenerator",
		
				"generatorDecorators": [ "plugins.VEUNDMINT_TUB.generators.LinkDecorator.LinkDecorator", 
										 "plugins.VEUNDMINT_TUB.generators.WikipediaDecorator.WikipediaDecorator" ],
				
				"plugins": [ 'plugins.VEUNDMINT_TUB.html5_mintmodtex.Plugin' ]
			}


	def setLocale(self):
		"""
		Localization, language and encoding settings

		Default language is 'de', but may be self.overriden by the build script
		to build different language versions.
		"""
		# Language should be parametrizable, so values depend on the lang parameter
		self.lang = ( lambda override: 'en' if 'lang=en' in override else 'de' ) ( self.override )

		# define Pythons locale (impact for example on sorting umlauts),
		# should be set to locale of course language, string definition depends on used system!
		# To do: add windows locales
		if (platform.system() == "Darwin"):
			# this is for OSX
			self.locale = ( lambda lang: "de_DE.UTF-8" if lang == 'de' else 'en_GB.UTF-8' ) ( self.lang )
		else:
			self.locale = ( lambda lang: "de_DE.utf8" if lang == 'de' else 'en_GB.utf8' ) ( self.lang )
		locale.setlocale(locale.LC_ALL, self.locale)

		## @var i18nfile
		#  localization file to use in LATEX
		self.i18nfile = ( lambda locale: "english.tex" if locale == 'en_GB.utf8' or locale == 'en_GB.UTF-8' else "deutsch.tex" ) ( self.locale)

		## @var i18nFiles
		# localization file to use in JS
		self.i18nFiles = os.path.join( self.converterCommonFiles, "i18n") # localization / internationalization files

		# load localization files into an Option parameter
		i18nPath = os.path.join( self.i18nFiles, self.lang + ".json" )
		f = open( i18nPath )

		## @var strings
		#  load localization files into an Option parameter
		self.strings = json.load( f )

		f.close()


	def setConverterVars(self):
		"""
		Variables used by the OSS converter
		Call these first, override with caution
		"""
		self.parserName = "lxml"
		self.texCommonFiles = os.path.join(self.converterDir, "tex")

		## @var sourcepath_original
		# directory to original source (strictly read only, except if amendsource is active)
		self.sourcepath_original = os.path.join(self.currentDir, self.source)

		## @var sourcepath
		#  Pfad in dem gearbeitet wird
		self.sourcepath = os.path.join(self.currentDir, self.outtmp)

		## @var sourceTEX
		# Teilpfad in dem die LaTeX-Quellenkopien liegen
		self.sourceTEX = os.path.join(self.sourcepath, "tex")
		self.sourceTEXStartFile = os.path.join(self.sourceTEX, self.module)

		## @var targetpath
		# Pfad in den der generierte Kurs kommt
		self.targetpath = os.path.join(self.currentDir, self.output)
		self.copyrightFile = os.path.join(self.sourceTEX, "copyrightcollection.tex")
		self.directexercisesFile = os.path.join(self.sourcepath, "directexercises.tex")
		self.convinfofile = "convinfo.js"


	def setConversionFlags(self):
		"""
		VE&MINT conversion flags, using values 0 and 1 (integers)
		"""

		self.testonly = ( lambda override: 1 if 'testonly=1' in override else 0 ) ( self.override )

		## @var disableLogin
		# =1 login buttons will be disabled
		self.disableLogin = 1

		## @var scormlogin
		# =1: No implicit user management, user-loginname is constructed from a SCORM string and immediately pulled from database
		self.scormlogin = 0

		## @var nosols
		# =0: Alle Loesungsumgebungen uebersetzen, =1: Loesungsumgebungen nicht uebersetzen wenn SolutionSelect-Pragma aktiviert ist
		self.nosols =  0

		## @var doscorm
		# =0: Kein SCORM, =1 -> SCORM-Manifest und Definitionsdateien miterzeugen, html-Baum kann dann als SCORM-Lernmodul Version 4 verwendet werden
		self.doscorm = 0

		## @var doscorm12
		# =0: Kein SCORM, =1- > SCORM-Manifest und Definitionsdateien miterzeugen, html-Baum kann dann als SCORM-Lernmodul Version 1.2 verwendet werden
		self.doscorm12 = 0

		## @var qautoexport
		# =1 Alle MExercise-Umgebungen werden auch als Export verpackt
		self.qautoexport = 0

		## @var diaok
		# =1 dia/convert-Kette durchfueren, wenn im Programmablauf auf 0 gesetzt wird dia/convert fuer alle files nicht mehr ausgefuehrt
		self.diaok = 0

		## @var cleanup
		# =1 -> trunk-Verzeichnis wird nach Erstellung entfernt (fuer Releases unbedingt aktivieren)
		self.cleanup = 0

		## @var localjax
		# =1 -> lokales MathJax-Verzeichnis wird eingerichtet (andernfalls ist netservice-Flag in conv.pl erforderlich)
		# Achtung, MathJax hat 33988 Dateien. Wenn die Option lokales MathJax gesetzt ist, kann das zu Problemen mit der Inodes-Quote fuehren!
		self.localjax = 0

		## @var borkify
		# =1 html und js-Dateien werden borkifiziert
		self.borkify = 0

		## @var dorelease
		# In Release-Versionen werden Flag-Kombinationen erzwungen und Logmeldungen unterdrueckt
		self.dorelease = 0

		## @var doverbose
		# Schaltet alle Debugmeldungen auf der Browserkonsole an, =0 -> gehen nur in log-Datei
		self.doverbose = 0

		## @var docollections
		# Schaltet Export der collection-Exercises ein (schließt qautoexport und nosols aus)
		self.docollections = 0

		## @var dopdf
		# =1 -> PDF wird erstellt und Downloadbuttons erzeugt
		self.dopdf =  0

		## @var dotikz
		# =1 -> TikZ wird aufgerufen um Grafiken zu exportieren, diese werden sofort in den Kurs eingebunden
		self.dotikz = 0

		## @var dozip
		# =1 -> html-Baum wird als zip-Datei geliefert (Name muss in output stehen)
		self.dozip = 0

		## @var consolecolors
		# =1 -> Ausgabe der Meldungen auf der Konsole wird eingefaerbt
		self.consolecolors = 1

		## @var consoleascii
		# =1 -> Only us-ascii strings are printed to the console (or pipes), does not affect written files
		self.consoleascii = 0

		## @var forceyes
		# =1 -> Questions asked interactively (like if a directory should be overwritten) will be assumed to be answered with "yes"
		self.forceyes = 1

		## @var symbolexplain
		# =1 -> Short list explaining symbols is added to table of contents
		self.symbolexplain = 1

		## @var forceoffline
		# =1 -> code acts as if no internet connection to anything is present (excluding direct links from content and MathJax loads)
		self.forceoffline = 0

		## @var quiet
		# =1 -> Absolutely no print messages, caller must deduce outcome by return value of sys.exit
		self.quiet = 0

		## @var bootstrap
		# Use Bootstrap for responsive layout
		self.bootstrap = 1

		## @var nolinkcorrection
		# optimization options
		self.nolinkcorrection = 1

		## @var keepequationtables
		# optimization options
		self.keepequationtables = 1

		## @var generate_pdf
		# dict der Form tex-name: Bezeichnung (ohne Endung)
		self.generate_pdf = { "veundmintkurs": "GesamtPDF Onlinekurs" }


	def setTest(self):
		"""
		Calling tex2x with testonly=1 will use the test tree instead of the real tree
		"""
		if self.testonly:
			# If testing, use test tree instead of tree defined above
			self.module = "tree_test.tex"


	def setSourceOutputDirs(self):
		"""
		VE&MINT source/target parameters
		"""
		self.macrofilename = "mintmod"
		self.macrofile = "mintmod.tex"

		## @var stdencoding
		# Presumed encoding of tex files and templates, utf8 well be accepted too but with a warning
		self.stdencoding = "utf-8"

		## @var outputencoding
		# encoding of generated html files
		self.outputencoding = "utf-8"

		## @var description
		# Bezeichnung des erstellen Kurses
		self.description = "Onlinebrückenkurs Mathematik"

		## @var author
		# Offizieller Autor des Kurses
		self.author = "Projekt VEUNDMINT"

		## @var contentlicense
		# Lizenz des Kursinhalts
		self.contentlicense = "CC BY-SA 3.0"

		## @var moduleprefix
		# Wird vor Browser-Bookmarks gesetzt
		self.moduleprefix = "Onlinebrückenkurs Mathematik"

		## @var variant
		# zu erzeugende Varianten der HTML-files, "std" ist die Hauptvariante, waehlt Makropakete fuer Mathematikumsetzung aus, Alternative ist "unotation"
		self.variant = "std"

		## @var accessflags
		# linux access flag preset for the entire output directory
		self.accessflags = "777"

		## @var mathjaxtgz
		# only used if localjax=1
		self.mathjaxtgz = "mathjax26complete.tgz"

		## @var scorm12tgz
		# only used if doscorm12=1
		self.scorm12tgz = "scorm12_xsd.tgz"

		## @var scorm4tgz
		# only used if doscorm=1
		self.scorm4tgz = ""

		## @var texstylefiles
		# style files needed in local directories for local pdflatex compilation
		self.texstylefiles = ["bibgerm.sty", "maxpage.sty"]

		## @var htmltikzscale
		# scaling factor used for tikz-png scaling, can be overridden by pragmas
		self.htmltikzscale = 1.3

		## @var autotikzcopyright
		# includes tikz externalized images in copyright list
		self.autotikzcopyright = 1

		## @var displaycopyrightlinks
		# add copyright links to images in the entire course
		self.displaycopyrightlinks = 0

		## @var maxsitejsonlength
		# the maximal number of string characters allowed for an internal json site object, will be stored in a different file if limit is exceeded
		self.maxsitejsonlength = 255


	def setSignature(self):
		"""
		Course signature, course part
		Don't use underscores in the course signature, as otherwise pdf2latex will convert this to math.
		"""

		## @var signature_main
		#Identifizierung des Kurses, die drei signature-Teile machen den Kurs eindeutig
		self.signature_main = "MFR-TUB"
		# self.signature_main = "OBMLGAMMA9" # "OBMLGAMMA5_SCORM12_UKS_m" # "OBMLGAMMA5" # OBM_LGAMMA_0 "OBM_PTEST8", "OBM_VEUNDMINT"		 # Identifizierung des Kurses, die drei signature-Teile machen den Kurs eindeutig

		## @var signature_version
		# Versionsnummer, nicht relevant fuer localstorage-userget!
		self.signature_version = "10000"

		## @var signature_localization
		# Lokalversion des Kurses, hier die bundesweite MINT-Variante
		self.signature_localization = "DE-MINT"
		self.signature_date = "09/2016"


	def setGitSignature(self):
		"""
		Course signature, repository part
		"""
		repo = Repo(self.currentDir)
		assert not repo.bare

		if repo.is_dirty():
			self.signature_git_dirty = 1
		else:
			self.signature_git_dirty = 0

		h = repo.head
		hc = h.commit
		self.signature_git_head = h.name

		# removed as it would cause an detached HEAD error at CI Testing
		# self.signature_git_branch = repo.active_branch.name

		self.signature_git_branch = 'develop software'

		self.signature_git_committer = hc.committer.name
		self.signature_git_message = hc.message.replace("\n", "")
		self.signature_git_commit = hc.hexsha


	def setServerValues(self):
		"""
		VE&MINT course parameters, defining values used by the online course
		"""

		## @var do_feedback
		# Feedbackfunktionen aktivieren? DOPPLUNG MIT FLAGS
		self.do_feedback = "0"

		## @var do_export
		# Aufgabenexport aktivieren? DOPPLUNG MIT FLAGS
		self.do_export = "0"

		## @var reply_mail
		# Wird in mailto vom Admin-Button eingesetzt
		self.reply_mail = "brueckenkurs@innocampus.tu-berlin.de"

		self.data_server = self.server
		self.exercise_server = self.server
		self.feedback_service = self.server + "/feedback.php" # Absolute Angabe
		self.data_server_description = "Server guest 6 (Standort TU Berlin)"
		self.data_server_user = self.server + "/userdata.php"  # Absolute Angabe


	def setTemplates(self):
		"""
		Set template XSLT directory, template for PHP preprocessing and SCORM-manifest template
		"""
		## @var converterTemplates
		# Only templates_bootstrap is supported to render HTML files
		self.converterTemplates = os.path.join( self.pluginDir, "templates" )
		self.template_redirect_basic = os.path.join(self.converterTemplates, "html5_redirect_basic.html")

		## @var template_scorm12manifest
		# SCORM templates
		self.template_scorm12manifest = os.path.join(self.converterTemplates, "scorm12_moodle_manifest.xml")

		## @var template_redirect_scorm
		# SCORM templates
		self.template_redirect_scorm = os.path.join(self.converterTemplates, "html5_redirect_scorm.html")
		#pass


	def setTTM(self):
		"""
		Path used to store XML files generated by TTM
		"""
		self.ttmExecute = True
		self.ttmPath = os.path.join(self.converterDir, "ttm")
		self.ttmFile = os.path.join(self.sourceTEX, "targetxml.xml")


	def setTags(self):
		"""
		Content Structure: which Header level to use for what (h1, h2, h3, ... )
		"""

		## @var contentlevel
		# level used by tcontent objects from subsubsections (MXContent)
		self.contentlevel = 4
		self.ContentStructure=[]
		self.ContentStructure.append("h1") # the whole course
		self.ContentStructure.append("h2") # a section in the course, a MSection according to MINTMOD
		self.ContentStructure.append("h3") # a subsection in the coursre, MSubsection according to MINTMOD
		self.ContentStructure.append("h4") # used for subsection introduction inside xcontents
		#self.ContentStructure.append("div")#Container werden nun über Attribute identifiziert

		# special site tags
		self.sitetaglist = ["chapter", "config", "data", "favorites", "location", "search", "test", "logout", "login"]

		# ModuleStructure
		self.ModuleStructure = []
		self.ModuleStructureClass= "xcontent" #nach dieser klasse wird gesucht, um Modulbereiche zu identifizieren. (Dann jeweils mit einer Nummer dahinter)


	def setPluginOptions(self):
		"""
		Use these Plugins (plugin path must be listed below within the plugin settings!)
		"""
		self.usePreprocessorPlugins = [ "PRE_MINTMODTEX" ]
		self.useOutputPlugins = [ "HTML5_MINTMODTEX" ] # name is also postfix of template files used by the plugin
		self.pluginPath = {
			"PRE_MINTMODTEX": os.path.join(self.converterDir, "plugins", "VEUNDMINT", "preprocessor_mintmodtex.py"),
			"HTML5_MINTMODTEX": os.path.join(self.converterDir, "plugins", "VEUNDMINT", "html5_mintmodtex.py")
		}


	def overrideValues(self):
		"""
		Check for self.overrides, options declared past this block will not be subject to self.override command line parameters
		"""
		self.overrides = list()
		for ov in self.override:
			m = re.match(r"(.+?)=(.+)", ov)
			if m:
				if m.group(1) == "options":
					print("Option selection: " + m.group(2))
					# options self.override was processed in struct object before Options were loaded
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
						print("Option " + m.group(1) + " does not exist, cannot self.override")

			else:
				print("Invalid self.override string: " + ov)


	def checkConsistency(self):
		"""
		Checks if given option values (including self.overrides) are consistent
		"""
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
				print("INFO:	git repository is not clean, please commit everything for a clean release")
			if (self.cleanup != 1) or (self.docollections == 1) or (self.doverbose == 1) or (self.dotikz == 0) or (self.borkify == 0) or (self.forceoffline == 1):
				print("FATAL ERROR: Option dorelease=1 cannot be used with cleanup=0, docollections=1, dotikz=0, borkify=0, forceoffline=1 or doverbose=1, aborting with error code 1")
				sys.exit(1)

		if self.scormlogin == 1:
			if self.doscorm == 0 and self.doscorm12 == 0:
				print("FATAL ERROR: Option scormlogin is detrimental if doscorm or doscorm12 is not active, aborting with error code 1")
				sys.exit(1)

		if self.bootstrap != 1:
				print("FATAL ERROR: Only bootstrap version is supported")
				sys.exit(1)
