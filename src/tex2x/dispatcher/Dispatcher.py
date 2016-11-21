"""
	tex2x converter - Processes tex-files in order to create various output formats via plugins
	Copyright (C) 2014  VEMINT-Konsortium - http://www.vemint.de

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	forked from tex2xStruct.structure written by Daniel Haase	
	@author Alvaro Ortiz for TU Berlin
"""

import imp
import os
import time
import json
from tex2x.Settings import ve_settings as settings

from tex2x.dispatcher.AbstractRunner import VerboseRunner, PreprocessorRunner, PluginRunner

from tex2x.parsers.AbstractParser import VerboseParser
from tex2x.parsers.TTMParser import TTMParser
from tex2x.parsers.HTMLParser import HTMLParser
from tex2x.parsers.MathMLParser import MathMLParser
from tex2x.parsers.TOCParser import TOCParser
from tex2x.parsers.ImageParser import ImageParser
from tex2x.parsers.LinkParser import LinkParser

from . import System as TSystem


class Dispatcher(object):
	OPTIONSFILE = "Option.py"
	SYSTEMFILE = "system.py"
	CURRDIR = ".."
	
	def __init__( self, verbose, pluginName, override ):
		self.verbose = verbose
		self.pluginName = pluginName
		self.override = override
		self.initModules()


	def dispatch(self):
		'''
		The dispatcher calls each step of the conversion pipeline.
		The pipeline is defined in the configfile (default configuration.json)
		In order:
		1. Run pre-processing plugins
		2. Run TTM (convert Tex to XML), load XML file created by TTM
		3. Parse XML files into a HTML tree
		4. Create the table of contents (TOC)
		5. Compile a list of required images
		6. Correct links
		7. Output to static HTML files
		'''
		if hasattr(self.options, "overrides"):
			for ov in self.options.overrides:
				print( "tex2x called with override option: " + ov[0] + " -> " + ov[1])

		time_start = time.time()

		# Run pre-processing plugins
		preprocessor = PreprocessorRunner( self.interface['preprocessor_plugins'] )
		if self.verbose: preprocessor = VerboseRunner( preprocessor, "Step 1: Preprocessing\n" )
		preprocessor.run()

		# Run TTM parser, load XML
		ttm = TTMParser( self.options, self.sys )
		ttm = MathMLParser( ttm, self.options ) # Add MathML corrections
		if self.verbose: ttm = VerboseParser( ttm, "Step 2: Converting Tex to XML (TTM)" )
		self.data['rawxml'] = ttm.parse( settings.sourceTEXStartFile, settings.sourceTEX, settings.ttmFile ) # run TTM parser with default options
		
		# Parse HTML
		html = HTMLParser( self.options )
		if self.verbose: html = VerboseParser( html, "Step 3: Parsing to HTML" )
		self.xmltree_raw = html.parse( self.data['rawxml'] )
		
		# Create TOC
		toc = TOCParser( self.options, self.sys )
		if self.verbose: toc = VerboseParser( toc, "Step 4: Creating the table of contents (TOC)" )
		self.toc, self.content = toc.parse( self.xmltree_raw )

		# Compile a list of required images
		imageParser = ImageParser( self.options )
		if self.verbose: imageParser = VerboseParser( imageParser, "Step 5: Compiling a list of required images" )
		self.requiredImages = imageParser.parse( self.content )

		# Correct links
		linker = LinkParser( self.options, self.sys )
		if self.verbose: linker = VerboseParser( linker, "Step 6: Correcting links" )
		linker.parse( self.content )
				
		# Start output plugin
		plugin = PluginRunner( self.data, self.content, self.toc, self.requiredImages, self.interface['output_plugins'] )
		if self.verbose: plugin = VerboseRunner( plugin, "Step 7: Output to static HTML files" )
		plugin.run()
		
		# Clean up temporary files
		if self.options.cleanup == 1: self.clean_up();

		duration = time.time() - time_start
		print("Total duration of conversion: %s" % duration )
		
		# stop program execution and return proper error level as return value
		#self.sys.finish_program()
		# no way the application runs without errors


	# --------------------- BEGIN DEFINITION OF THE MODULE INTERFACE ------------------------------------------------------

	def initModules(self):
		"""
		INITIALIZE INTERFACE DATA MEMBER, WHICH SERVES AS THE SOLE COMMUNICATION INTERFACE TO LINKED MODULES
		AS DESCRIBED IN THE tex2x LICENSE. LINKED MODULES (PLUGINS) MAY ONLY USE THE FOLLOWING DATA MEMBERS
		FOR COMMUNICATION AND FUNCTION CALLS:
		"""
		
		if not self.pluginName: raise Exception( "No plugin name given" )
		
		self.interface = dict()

		# data member: linked modules may READ/WRITE/CHANGE/DELETE elements of the data member,
		# added elements must not contain functions or code of any kind.
		self.interface['data'] = dict()
		# simplify access
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

		# simplify access
		self.options = self.interface['options']


	def initSystemModule(self):
		'''
		system member: A module exposing a class "System", linked modules may provide the class definition and may CALL functions exposed by this object reference
		class System must be under GPL license
		'''
		self.interface['system'] = TSystem
		path = os.path.join( "plugins", self.pluginName, Dispatcher.SYSTEMFILE )
		if not os.path.isfile( path ):  raise Exception( "System file not found at %s" % path )
		
		module = imp.load_source(self.pluginName, path)
		self.interface['system'] = module.System(self.interface['options'])			
		# simplify access
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

