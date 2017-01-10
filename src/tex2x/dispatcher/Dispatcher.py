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
from tex2x.AbstractTranslator import VerboseTranslator
from tex2x.AbstractParser import VerboseParser
from tex2x.AbstractGenerator import VerboseGenerator


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
		
		## @var verbose
		#  Print debugging information
		self.verbose = verbose
				
		## @var pluginName
		#  Name of the application to execute. Set by the main entry script in tex2x.
		self.pluginName = pluginName
		
		## @var override
		#  Override options in the plugin's Option.py file, e.g. 'description=My Course' to change the course title
		self.override = override
		
		## @var data
		#  data member, undocumented (Daniel Haase) 
		self.data = dict()

		## @var pipeline
		# read the pipeline containing the dispatcher steps from settings		
		self.pipeline = Pipeline()


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
		if self.pipeline.has( 'preprocessors' ):
			preprocessorDispatcher = PreprocessorDispatcher( self.data, self.pipeline.preprocessors )
			if self.verbose: preprocessorDispatcher = VerboseDispatcher( preprocessorDispatcher, "Step 1: Preprocessing" )
			preprocessorDispatcher.dispatch()

		# 2. Run TTM translator, load XML as string
		if self.pipeline.has( 'translator' ):
			translator = self.pipeline.translator()
			if self.pipeline.has( 'translatorDecorators' ):
				for decorator in self.pipeline.translatorDecorators: # decorate the translator with the decorators defined in settings.pipeline
					translator = decorator( translator )
			if self.verbose: translator = VerboseTranslator( translator, "Step 2: Converting Tex to XML (TTM)" ) # if verbose is on, decorate with verbose decorator
			self.data['rawxml'] = translator.translate() # run TTM parser with default options
		
		# 3. Parse HTML to etree
		if self.pipeline.has( 'parser' ):
			parser = self.pipeline.parser()
			if self.pipeline.has( 'parserDecorators' ):
				for decorator in self.pipeline.parserDecorators: # decorate the parser with the decorators defined in settings.pipeline
					parser = decorator( parser )
			if self.verbose: html = VerboseParser( parser, "Step 3: Parsing to HTML" ) # if verbose is on, decorate with verbose decorator
			xmltree_raw = parser.parse( self.data['rawxml'] ) # parse the xml data
		
		# 4. Create TOC and content tree
		if self.pipeline.has( 'generator' ):
			generator = self.pipeline.generator()
			if self.pipeline.has( 'generatorDecorators' ):
				for decorator in self.pipeline.generatorDecorators: # decorate the generator with the decorators defined in settings.pipeline
					generator = decorator( generator )
			if self.verbose: generator = VerboseGenerator( generator, "Step 4: Creating the table of contents (TOC) and content tree" )  # if verbose is on, decorate with verbose decorator
			toc, content = generator.generate( xmltree_raw ) # generate TOC and content from etree
		
		# 5. Start output plugin
		if self.pipeline.has( 'plugins' ):
			pluginDispatcher = PluginDispatcher( self.data, content, toc, self.pipeline.plugins )
			if self.verbose: pluginDispatcher = VerboseDispatcher( pluginDispatcher, "Step 5: Create output" )
			pluginDispatcher.dispatch()
		
		# stop program execution and return proper error level as return value
		# sys.finish_program()
		# no way the application runs without errors
