## @package tex2x.dispatcher.Dispatcher
#  The pipeline dynamically loads the classes required by the dispatcher by reading the settings.pipeline parameter from the global settings file or from the plugin Option file.
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
from tex2x.Settings import settings


class Pipeline(object):
	"""
	Load the classes required by the Dispatcher (preprocessors, translator, parser, generator, outputPlugins).
	These classes are specified in settings.pipeline and loaded dynamically.
	The pipeline dynamically loads the classes required by the dispatcher by reading the settings.pipeline parameter
	from the global settings file or from the plugin Option file.

	@see settings.py
	@see plugins/.../Option.py
	@see imp library https://docs.python.org/2/library/imp.html (loading classs dynamically at runtime)
	"""

	def __init__( self ):
		"""
		Constructor. Instantiate in Dispatcher.
		"""

		## @var preprocessors
		#  List of preprocessor objects
		self.preprocessors = []
		for name in settings.pipeline[ 'preprocessors' ]:
			self.preprocessors.append( self.dynamicImport( name ) )

		## @var translator
		#  Class that can translate LaTeX source files to an XML file, including parsing MathML.
		self.translator = self.dynamicImport( settings.pipeline[ 'translator' ] )

		## @var translatorDecorators
		#  List of decorators for the translator
		self.translatorDecorators = []
		for name in settings.pipeline[ 'translatorDecorators' ]:
			self.translatorDecorators.append( self.dynamicImport( name ) )

		## @var parser
		#  Parsers take a string or text file and return the result of the parsing process.
		self.parser = self.dynamicImport( settings.pipeline[ 'parser' ] )

		## @var parserDecorators
		#  List of decorators for the parser
		self.parserDecorators = []
		for name in settings.pipeline[ 'parserDecorators' ]:
			self.parserDecorators.append( self.dynamicImport( name ) )

		## @var generator
		#  Generators create the table of contents (TOC) and the content tree.
		self.generator = self.dynamicImport( settings.pipeline[ 'generator' ] )

		## @var generatorDecorators
		#  List of generatorDecorators for the parser
		self.generatorDecorators = []
		for name in settings.pipeline[ 'generatorDecorators' ]:
			self.generatorDecorators.append( self.dynamicImport( name ) )

		## @var plugins
		#  List of plugin objects
		self.plugins = []
		for name in settings.pipeline[ 'plugins' ]:
			self.plugins.append( self.dynamicImport( name ) )


	def dynamicImport(self, name):
		"""
		Dynamically instantiate objects from class names given in the names array (at runtime).

		@param name qualified class name, including the module and the package
		@return object created instantiated from class name
		"""

		# Put the complete class path here, so for example:
		# if you have a plugin called VEUNDMINT and a file called preprocessor_mintmodtex.py which holds a class called Preprocessor,
		# then the path is plugins.VEUNDMINT.preprocessor_mintmodtex.Preprocessor.

		substr = name.split('.') # example: VEUNDMINT.preprocessors.PrepareData.PrepareData
		if len( substr ) < 3: raise Exception( "Incomplete path %s" % name )

		# get the name of the Python class
		className = substr.pop() # example: PrepareData

		# get the name of the module, i.e. the file name (without the .py extension)
		moduleName = substr.pop() # PrepareData

		# get the package name, i.e. the path to the file,
		# relative to the src or to the plugins directory
		packageName = substr # example: VEUNDMINT.preprocessors

		#  Array of paths to directories that should be searched for modules to load.
		#  This array should contain the plugins and the src directory (the converterDir).
		#  Append the packageName path to the default search paths (using the splat operator "*", as this is a list).


		pluginPath = [ os.path.join( settings.converterDir, *packageName ) ] # example: ['/store/cosmetix/datastore/ortiz/VEUNDMINT_DEV/src/plugins/VEUNDMINT']


		print('PLUGIN_____PATH', pluginPath)

		# search for the file containing the module
		f, filename, description = imp.find_module( moduleName, pluginPath )

		try:
			# load the module
			module = imp.load_module( moduleName, f, filename, description)

			# get the module class and instantiate it.
			# By convention, the module file should contain a class of the same name.
			class_ = getattr( module, className )

		finally:
			f.close()

		return class_
