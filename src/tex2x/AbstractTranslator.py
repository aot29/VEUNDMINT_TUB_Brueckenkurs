## @package tex2x.translators.AbstractTranslator
# Translators take LaTeX files and convert them to XML strings
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

class AbstractTranslator(object):
	"""
	Translators take LaTeX files and convert them to XML strings
	"""
	def __init(self):
		"""
		This class is abstract, so cannot be instantiated.
		"""
		raise NotImplementedError
	
	def translate(self):
		"""
		The translate method is called by classes implementing the AbstractTranslator class.
		"""
		raise NotImplementedError

	
class VerboseTranslator( AbstractTranslator ):
	'''
	In verbose mode, logs duration information while running each conversion step.
	Used here as a decorator for classes extending AbstractTranslator.
	'''
	def __init__(self, translator, msg):
		'''
		@param translator - Translator (class extending AbstractTranslator)
		@param msg - Message to print before executing the generator
		'''
		self.translator = translator
		self.msg = msg
		
	
	def translate(self, *args, **kwargs):
		"""
		@param sourceTEXStartFile path to source Tex file
		@param sourceTEX path to search for Tex input files
		@param ttmFile path to output XML file
		@param dorelease - deprecated, use unit tests and continuous integration instead.
		@return: String - the XML as loaded from file as string
		"""
		time_start = time.time()

		# call the decorated class' runner
		response = self.translator.translate(*args, **kwargs)
		
		time_end = time.time()
		time_diff = time_end - time_start
		print("%s - %s s\n" % ( self.msg, time_diff ) )
		
		return response
