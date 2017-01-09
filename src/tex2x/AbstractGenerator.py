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
	
	@author Alvaro Ortiz for TU Berlin
"""
import time

class AbstractGenerator(object):
	"""
	Base class for all generators.
	Parsers take an etree and return a toc and content trees for the whole course.
	"""
	def __init__(self):
		"""
		This class is abstract, so cannot be instantiated.
		"""
		raise NotImplementedError
	
	def generate(self, *args, **kwargs ):
		"""
		@return - tree TOC, treecontent - for the whole course
		"""
		raise NotImplementedError


class VerboseGenerator( AbstractGenerator ):
	'''
	In verbose mode, logs duration information while running each conversion step.
	Used here as a decorator for classes extending AbstractGenerator.
	'''
	def __init__(self, generator, msg):
		'''
		@param generator - Generator (class extending AbstractGenerator)
		@param msg - Message to print before executing the generator
		'''
		self.generator = generator
		self.msg = msg
		
	
	def generate(self, *args, **kwargs):
		time_start = time.time()

		# call the decorated class' runner
		response = self.generator.generate(*args, **kwargs)
		
		time_end = time.time()
		time_diff = time_end - time_start
		print("%s - %s s\n" % ( self.msg, time_diff ) )
		
		return response

		
	
