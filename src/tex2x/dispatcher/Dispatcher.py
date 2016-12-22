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
#  \author Alvaro Ortiz for TU Berlin


from tex2x.Settings import ve_settings as settings
from tex2x.System import ve_system as sys

from tex2x.dispatcher.Pipeline import Pipeline
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
	The dispatcher executes the steps of defined in a "pipeline" in sequence. The steps of the pipeline are read from settings.
	An example of another application of this pattern is Apache Cocoon (https://en.wikipedia.org/wiki/Apache_Cocoon).
	
	Each element in the pipeline can be seen as a template method, that is each method is wrapped in its own class:
	"Define the skeleton of an algorithm in an operation, deferring some steps to subclasses. 
	Lets subclasses redefine certain steps of an algorithm without changing the algorithm's structure." 
	- Gamma, Helm, Johnson, Vlissides (1995) 'Design Patterns: Elements of Reusable Object-Oriented Software'
	so instead of packing everything into methods, each functionality is implemented in a separate class.
	Each class implements a specific interface. Together, these interfaces specify a sequence of steps which are executed by the Dispatcher.dispatch() method.
	The advantage are
	* the class size is manageable.
	* different implementations of each step in the dispatch sequence are possible, while keeping the same dispatcher.
	* the classes could be composed at runtime by configuration.
	
	@see https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/wikis/Python%20API%20Documentation 
	"""
	
	## OPTIONSFILE
	# Path to the "Option" file. This is a class with options used while running the converter.
	OPTIONSFILE = "Option.py"
	
	## SYSTEMFILE
	# Path to the "System" file. This is a class which contains all manner of methods for handling files in Python.
	SYSTEMFILE = "tex2x/System.py"
		
	def __init__( self, verbose, pluginName, override ):
		"""
		Constructor
		Instantiated by tex2x.py
		Calls initModules to initialize preprocessors and output plugins
		
		@param verbose Boolean
		@param pluginName - Name of the application to execute (default VEUNDMINT)
		@param override - Override options in the plugin's Option.py file
		"""
		
		if not pluginName: raise Exception( "No plugin name given" )
		
		## @var requiredImages
		#  deprecated
		self.requiredImages = []
				
		## @var verbose
		#  Print debugging information
		self.verbose = verbose
				
		## @var pluginName
		#  Name of the application to execute. Set by the main entry script in tex2x.
		self.pluginName = pluginName
		
		## @var override
		#  Override options in the plugin's Option.py file, e.g. 'description=My Course' to change the course title
		self.override = override
		
		# start processing some stuff that is required later (refactor)
		self.initModules()

		# read the pipeline containing the dispatcher steps from settings		
		self.pipeline = Pipeline( self.pluginName, self.interface )


	def dispatch(self):
		"""
		The dispatcher calls each step of the conversion pipeline.
		1. Preprocessors: Run pre-processing plugins
		2. Translator: Run TTM (convert Tex to XML), load XML file created by TTM, 
		3. Parser: Parse XML files into a HTML tree
		4. Generator: Create the table of contents (TOC) and content tree, correct links
		5. Plugins: Output to static HTML files
		"""

		# 1. Run pre-processing plugins
		preprocessorDispatcher = PreprocessorDispatcher( self.pipeline.preprocessors )
		if self.verbose: preprocessorDispatcher = VerboseDispatcher( preprocessorDispatcher, "Step 1: Preprocessing" )
		preprocessorDispatcher.dispatch()

		# 2. Run TTM translator, load XML
		translator = self.pipeline.translator
		translator = MathMLDecorator( translator ) # Add MathML corrections
		if self.verbose: translator = VerboseTranslator( translator, "Step 2: Converting Tex to XML (TTM)" )
		self.data['rawxml'] = translator.translate() # run TTM parser with default options
		
		# 3. Parse HTML
		html = self.pipeline.parser
		if self.verbose: html = VerboseParser( html, "Step 3: Parsing to HTML" )
		xmltree_raw = html.parse( self.data['rawxml'] )
		
		# 4. Create TOC and content tree
		generator = self.pipeline.generator
		generator = LinkDecorator( generator )
		generator = WikipediaDecorator( generator, settings.lang )
		if self.verbose: generator = VerboseGenerator( generator, "Step 4: Creating the table of contents (TOC) and content tree" )
		self.toc, content = generator.generate( xmltree_raw )
		
		# 5. Start output plugin
		plugin = PluginDispatcher( self.data, content, self.toc, self.requiredImages, self.pipeline.plugins )
		if self.verbose: plugin = VerboseDispatcher( plugin, "Step 5: Output to static HTML files" )
		plugin.dispatch()
		
		# Clean up temporary files
		if settings.cleanup == 1: self.clean_up();

		# stop program execution and return proper error level as return value
		# sys.finish_program()
		# no way the application runs without errors


	# --------------------- BEGIN DEFINITION OF THE MODULE INTERFACE ------------------------------------------------------

	def initModules(self):
		"""
		INITIALIZE INTERFACE DATA MEMBER, WHICH SERVES AS THE SOLE COMMUNICATION INTERFACE TO LINKED MODULES
		AS DESCRIBED IN THE tex2x LICENSE. LINKED MODULES (PLUGINS) MAY ONLY USE THE FOLLOWING DATA MEMBERS
		FOR COMMUNICATION AND FUNCTION CALLS:

		As all the code is now GPL, these workarounds to allow only "linking" to certain stuff while obfuscating other are no more necessary.
		"""

		## @var interface
		# undocumented data structure (Daniel Haase)
		self.interface = dict()

		# data member: linked modules may READ/WRITE/CHANGE/DELETE elements of the data member,
		# added elements must not contain functions or code of any kind.
		self.interface['data'] = dict()
		
		## @var data
		# simplify access to the interface data member (Daniel Haase)
		self.data = self.interface['data']

	
	def clean_up(self):
		print("Cleaning up: " + os.path.abspath(settings.sourcepath))
		sys.removeTree(settings.sourcepath)

