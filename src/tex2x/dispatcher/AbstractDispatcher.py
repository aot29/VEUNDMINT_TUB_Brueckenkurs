## @package tex2x.dispatcher.AbstractDispatcher
#  Base classes for the dispatcher functionality. The dispatcher is the first class to be called by tex2x and sets the processing pipeline together.
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

import time

class AbstractDispatcher(object):
	"""
	Base classes for the dispatcher functionality. The dispatcher is the first class to be called by tex2x and sets the processing pipeline together.	
	The dispatcher uses the template method pattern: 	
	"Define the skeleton of an algorithm in an operation, deferring some steps to subclasses. 
	Lets subclasses redefine certain steps of an algorithm without changing the algorithm's structure." 
	- Gamma, Helm, Johnson, Vlissides (1995) 'Design Patterns: Elements of Reusable Object-Oriented Software'
	"""
	def __init(self):
		"""
		This class is abstract, so cannot be instantiated.
		"""
		raise NotImplementedError
	
	def dispatch(self):
		"""
		The dispatch method is called by classes implementing the AbstractDispatcher class.
		"""
		raise NotImplementedError


class VerboseDispatcher( AbstractDispatcher ):
	'''
	In verbose mode, logs duration information while running each conversion step.
	Used here as a decorator for classes extending AbstractDispatcher
	
	@example
	# create your Dispatcher
	disp = MyDispatcher()
	# Decorate it with VerboseDispatcher
	verboseDisp = VerboseDispatcher( disp )
	# use as you would the normal, undecorated dispatcher
	disp.dispatch()
	'''
	def __init__(self, dispatcher, msg):
		"""
		The Constructor takes the original, non-verbose dispatcher as first parameter.
		
		@param dispatcher - Dispatcher (object extending AbstractDispatcher)
		@param msg - Message to print before executing the dispatcher
		"""
		
		## @var dispatcher
		#  the original, non-verbose dispatcher
		self.dispatcher = dispatcher
		
		## @var msg
		#  Message to print before executing the dispatcher
		self.msg = msg
		
	
	def dispatch(self):
		"""
		Adds timing and other verbose information to the output of a dispatcher class.
		"""
		time_start = time.time()

		# call the decorated class' runner
		response = self.dispatcher.dispatch()
		
		time_end = time.time()
		time_diff = time_end - time_start
		print("%s - %s s\n" % (self.msg, time_diff) )
		
		return response


class PreprocessorDispatcher( AbstractDispatcher ):
	"""
	Run pre-processors of the "plugin". Pre-processors can be configured in Option.py, using the field usePreprocessorPlugins and following fields.
	Can be decorated with VerboseDecorator for performance logs.
	"""
	def __init__(self, data, plugins ):
		"""
		Constructor
		
		@param data - an undocumented data structure (Daniel Haase)
		@param plugins - list of "Preprocessor modules" (Daniel Haase)
		"""
		## @var plugins
		#  list of "Preprocessor modules" (Daniel Haase)
		self.plugins = plugins
		
		## @var data
		#  an undocumented data structure (Daniel Haase)
		self.data = data
		
	
	def dispatch(self):
		"""
		Runs the preprocessor objects in the order they were added.
		Preprocessors do all kinds of undocumented things and should be refactored.
		Check them in plugins/VEUNDMINT/preprocessor_mintmodtex.py
		"""
		for pp in self.plugins:
			pp( self.data ).preprocess()


class PluginDispatcher( AbstractDispatcher ):
	"""
	Run plugins.
	Can be decorated with VerboseDecorator to enable performance logging.
	"""
	def __init__(self, data, content, tocxml, requiredImages=None, plugins=None):
		"""
		Constructor
		
		@param data - an undocumented data structure (Daniel Haase)
		@param content - a list of [toc_node, content_node] items
		@param tocxml - etree containing the table of contents 
		@param requiredImages - deprecated, images are now handled by the build scripts.
		@param plugins - a list of "plugins" (this is a misnomer for designating the actual application) 
		"""
		## @var data
		#  an undocumented data structure (Daniel Haase)
		self.data = data
		
		## @var content
		#  a list of [toc_node, content_node] items
		self.content = content
		
		## @var tocxml
		#  etree containing the table of contents (of the whole course)
		self.tocxml = tocxml
		
		## @var requiredImages
		#  deprecated
		self.requiredImages = requiredImages
		
		## @var plugins
		#  a list of "plugins" (this is a misnomer for designating the actual application)
		self.plugins = plugins		


	def dispatch(self):
		"""
		Loads all plugins and runs them in the order they were added.
		Plugins is a misnomer for designating the actual application. They do all kinds of undocumented things and should be refactored.
		Check them in plugins/VEUNDMINT/html5_mintmodtex.py
		"""

		self.data['content'] = self.content
		self.data['tocxml'] = self.tocxml

		#reset data
		self.content = None
		self.tocxml = None

		#activate pre-processing from plugins
		for op in self.plugins:
			op( self.data ).create_output()


	