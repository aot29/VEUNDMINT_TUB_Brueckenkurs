## @package tex2x.dispatcher.Dispatcher
#  The pipeline dynamically loads the classes required by the dispatcher.
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

import imp
import os
from tex2x.Settings import ve_settings as settings


class Pipeline(object):
	"""
	Load the classes required by the Dispatcher (preprocessors, translator, parser, generator, outputPlugins). 
	These classes are specified in settings.pipeline and loaded dynamically.
	
	@see imp library https://docs.python.org/2/library/imp.html
	"""
	
	def __init__( self, pluginName, interface ):
		"""
		Constructor. Instantiate in Dispatcher.
		
		@param pluginName Name of the application to execute
		@param interface dict undocumented (Daniel Haase)
		"""

		# refactor this out
		self.interface = interface
		
		## @var pluginName
		#  Name of the application to execute		
		self.pluginName = pluginName

		## @ar pluginPath
		#  Array of paths to directories that should be searched for modules to load. 
		#  This array should contain the plugin directory as well as the tex2x subdirectories.
		self.pluginPath = [ 
							os.path.join( settings.converterDir, "plugins", self.pluginName ),
							os.path.join( settings.converterDir, "tex2x", "generators" ),
							os.path.join( settings.converterDir, "tex2x", "parsers" ),
							os.path.join( settings.converterDir, "tex2x", "renderers" ),
							os.path.join( settings.converterDir, "tex2x", "translators" )
						]
	
		## @var preprocessors
		#  List of preprocessor objects
		self.preprocessors = []
		for name in settings.pipeline[ 'preprocessors' ]:
			class_ = self.dynamicImport( name )
			self.preprocessors.append( class_( self.interface ) )
		
		## @var translator
		#  Class that can translate LaTeX source files to an XML file, including parsing MathML.
		class_ = self.dynamicImport( settings.pipeline[ 'translator' ] )
		self.translator = class_()

		## @var parser
		#  Parsers take a string or text file and return the result of the parsing process.
		class_ = self.dynamicImport( settings.pipeline[ 'parser' ] )
		self.parser = class_()
		
		## @var generator
		#  Generators create the table of contents (TOC) and the content tree.
		class_ = self.dynamicImport( settings.pipeline[ 'generator' ] )
		self.generator = class_()
		
		## @var plugins
		#  List of plugin objects
		self.plugins = []
		for name in settings.pipeline[ 'plugins' ]:
			class_ = self.dynamicImport( name )
			self.plugins.append( class_( self.interface ) )


	def dynamicImport(self, name):
		"""
		Dynamically instantiate objects from class names given in the names array (at runtime).
		
		@param names class name
		@return object created instantiated from class name
		"""
		# search for the file containing the module 
		f, filename, description = imp.find_module( name, self.pluginPath )
		
		try:
			# load the module
			module = imp.load_module( name, f, filename, description)

			# get the module class and instantiate it.
			# By convention, the module file should contain a class of the same name.
			class_ = getattr( module, name )
			
		finally:
			f.close()
			
		return class_
	