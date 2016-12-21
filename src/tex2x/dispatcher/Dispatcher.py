## @package tex2x.dispatcher.Dispatcher
#  The dispatcher is the first class to be called by tex2x and sets the processing pipeline together.
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

import imp
import os
import time
import json
from lxml import etree

from tex2x.Settings import ve_settings as settings
from tex2x.dispatcher.AbstractDispatcher import AbstractDispatcher, VerboseDispatcher, PreprocessorDispatcher, PluginDispatcher

from tex2x.translators.AbstractTranslator import VerboseTranslator
from tex2x.translators.TTMTranslator import TTMTranslator
from tex2x.translators.MathMLDecorator import MathMLDecorator

from tex2x.parsers.AbstractParser import VerboseParser
from tex2x.parsers.HTMLParser import HTMLParser

from tex2x.generators.AbstractGenerator import VerboseGenerator
from tex2x.generators.ContentGenerator import ContentGenerator
from tex2x.generators.LinkDecorator import LinkDecorator
from tex2x.generators.WikipediaDecorator import WikipediaDecorator


class Dispatcher(AbstractDispatcher):
	"""
	The dispatcher is the first class to be called by tex2x and sets the processing pipeline together.	
	The dispatcher uses the template method pattern: 	
	"Define the skeleton of an algorithm in an operation, deferring some steps to subclasses. 
	Lets subclasses redefine certain steps of an algorithm without changing the algorithm's structure." 
	- Gamma, Helm, Johnson, Vlissides (1995) 'Design Patterns: Elements of Reusable Object-Oriented Software'
	
	so instead of packing everything into methods, each functionality is implemented in a separate class.
	Each class implements a specific interface. Together, these interfaces specify a sequence of steps which are executed by the Dispatcher.dispatch() method.
	The advantage are
	* the class size is manageable.
	* different implementations of each step in the dispatch sequence are possible, while keeping the same dispatcher.
	* the classes could be composed at runtime by configuration.
	
	The initModules() and subsequent method need refactoring.
	"""
	
	## OPTIONSFILE
	# Path to the "Option" file. This is a class with options used while running the converter.
	OPTIONSFILE = "Option.py"
	
	## SYSTEMFILE
	# Path to the "System" file. This is a class which contains all manner of methods for handling files in Python.
	SYSTEMFILE = "tex2x/System.py"
	
	## CURRDIR
	#  Passed to Option
	CURRDIR = ".."
	
	def __init__( self, verbose, pluginName, override ):
		"""
		Constructor
		Instantiated by tex2x.py
		
		@param verbose Boolean
		@param pluginName - Name of the application to execute (default VEUNDMINT)
		@param override - Override options in the plugin's Option.py file
		"""
		## @var requiredImages
		#  deprecated
		self.requiredImages = []
				
		## @var verbose
		#  Print debugging information
		self.verbose = verbose
				
		## @var pluginName
		#  Name of the application to execute
		self.pluginName = pluginName
		
		## @var override
		#  Override options in the plugin's Option.py file, e.g. 'description=My Course' to change the course title
		self.override = override
		
		## @var options
		#  simplify access to the interface options member (Daniel Haase) - refactor
		#  NOTE: self.options is set in initOptionsModule
		self.options = None

		## @var sys
		#  Simplify access to the interface options member (Daniel Haase) - refactor
		#  NOTE: self.sys is set in initOptionsModule
		self.sys = None

		# start processing some stuff that is required later (refactor)
		self.initModules()


	def dispatch(self):
		"""
		The dispatcher calls each step of the conversion pipeline.
		1. Run pre-processing plugins
		2. Run TTM (convert Tex to XML), load XML file created by TTM, 
		3. Parse XML files into a HTML tree
		4. Create the table of contents (TOC) and content tree, correct links
		5. Output to static HTML files
		"""
				
		if hasattr(self.options, "overrides"):
			for ov in self.options.overrides: print( "tex2x called with override option: " + ov[0] + " -> " + ov[1])

		# 1. Run pre-processing plugins
		preprocessorDispatcher = PreprocessorDispatcher( self.preprocessors )
		if self.verbose: preprocessorDispatcher = VerboseDispatcher( preprocessorDispatcher, "Step 1: Preprocessing" )
		preprocessorDispatcher.dispatch()

		# 2. Run TTM translator, load XML
		self.translator = TTMTranslator( self.options, self.sys )
		self.translator = MathMLDecorator( self.translator, self.options ) # Add MathML corrections
		if self.verbose: self.translator = VerboseTranslator( self.translator, "Step 2: Converting Tex to XML (TTM)" )
		self.data['rawxml'] = self.translator.translate( settings.sourceTEXStartFile, settings.sourceTEX ) # run TTM parser with default options
		
		# 3. Parse HTML
		html = HTMLParser( self.options )
		if self.verbose: html = VerboseParser( html, "Step 3: Parsing to HTML" )
		xmltree_raw = html.parse( self.data['rawxml'] )
		
		# 4. Create TOC and content tree
		self.generator = ContentGenerator( self.options, self.sys )
		self.generator = LinkDecorator( self.generator )
		self.generator = WikipediaDecorator( self.generator, self.options.lang)
		if self.verbose: self.generator = VerboseGenerator( self.generator, "Step 4: Creating the table of contents (TOC) and content tree" )
		self.toc, content = self.generator.generate( xmltree_raw )
		
		#print( etree.tostring( xmltree_raw ) )
		#print(self.content[2][2])
		
		# 5. Start output plugin
		plugin = PluginDispatcher( self.data, content, self.toc, self.requiredImages, self.interface['output_plugins'] )
		if self.verbose: plugin = VerboseDispatcher( plugin, "Step 5: Output to static HTML files" )
		plugin.dispatch()
		
		# Clean up temporary files
		if self.options.cleanup == 1: self.clean_up();

		# stop program execution and return proper error level as return value
		# self.sys.finish_program()
		# no way the application runs without errors


	# --------------------- BEGIN DEFINITION OF THE MODULE INTERFACE ------------------------------------------------------

	def initModules(self):
		"""
		INITIALIZE INTERFACE DATA MEMBER, WHICH SERVES AS THE SOLE COMMUNICATION INTERFACE TO LINKED MODULES
		AS DESCRIBED IN THE tex2x LICENSE. LINKED MODULES (PLUGINS) MAY ONLY USE THE FOLLOWING DATA MEMBERS
		FOR COMMUNICATION AND FUNCTION CALLS:

		As all the code is now GPL, these workarounds to allow only "linking" to certain stuff while obfuscating other are no more necessary.
		"""
		
		if not self.pluginName: raise Exception( "No plugin name given" )
		
		## @var interface
		# undocumented data structure (Daniel Haase)
		self.interface = dict()

		# data member: linked modules may READ/WRITE/CHANGE/DELETE elements of the data member,
		# added elements must not contain functions or code of any kind.
		self.interface['data'] = dict()
		
		## @var data
		# simplify access to the interface data member (Daniel Haase)
		self.data = self.interface['data']

		# initializes "interface data members"
		# Exceptions bubble-up to the main caller class
		self.initOptionsModule()
		self.initSystemModule()
		self.initPreprocessors()
		self.initOutputPlugins()
		
		
	def initOptionsModule(self):
		'''
		options member: A module exposing a class "Option", linked modules must provide the class definition and may READ but not modify data exposed by this object reference
		class Options must be under LGPL or GPL license
		'''
		self.interface['options'] = None
		path = os.path.join( "plugins", self.pluginName, Dispatcher.OPTIONSFILE )
		if not os.path.isfile( path ):  raise Exception( "Option file not found at %s" % path )
			
		module = imp.load_source( self.pluginName, path )
		self.interface['options'] = module.Option(Dispatcher.CURRDIR, self.override)
		self.options = self.interface['options']


	def initSystemModule(self):
		'''
		system member: A module exposing a class "System", linked modules may provide the class definition and may CALL functions exposed by this object reference
		class System must be under GPL license
		'''
		if not os.path.isfile( Dispatcher.SYSTEMFILE ):  raise Exception( "System file not found at %s" % Dispatcher.SYSTEMFILE )
		
		module = imp.load_source(self.pluginName, Dispatcher.SYSTEMFILE)
		self.interface['system'] = module.System(self.interface['options'])			
		self.sys = self.interface['system']


	def initPreprocessors(self):
		'''
		preprocessor_plugins member: A list of modules exposing a class "Preprocessor" which has a function "preprocess"
		'''
		self.interface['preprocessor_plugins'] = []
		for p in self.interface['options'].usePreprocessorPlugins:
			path = self.interface['options'].pluginPath[p]
			if not os.path.isfile( path ):  raise Exception( "Preprocessor file %s not found at %s" % (p, path) )
			
			module = imp.load_source(self.pluginName + "_preprocessor_" + p, path )
			self.interface['preprocessor_plugins'].append(module.Preprocessor(self.interface))
			
		self.preprocessors = self.interface['preprocessor_plugins']


	def initOutputPlugins(self):
		'''
		output_plugins member: A list of modules exposing a class "Plugin" which has a function "create_output"
		'''
		self.interface['output_plugins'] = []
		for p in self.interface['options'].useOutputPlugins:
			module = imp.load_source( self.pluginName + "_output_" + p, self.interface['options'].pluginPath[p] )
			path = self.interface['options'].pluginPath[p]
			if not os.path.isfile( path ):  raise Exception( "Output plugin file %s not found at %s" % (p, path) )
			
			self.interface['output_plugins'].append(module.Plugin(self.interface))

	# --------------------- END DEFINITION OF THE MODULE INTERFACE ------------------------------------------------------		
	
	def clean_up(self):
		print("Cleaning up: " + os.path.abspath(self.options.sourcepath))
		self.sys.removeTree(self.options.sourcepath)

