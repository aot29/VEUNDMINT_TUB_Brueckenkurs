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

class AbstractParser(object):
	'''
	Base class for all parsers.
	Parsers take a string or text file and return the result of the parsing process.
	The returned object type may be of any type, e.g. etree
	'''
	def parse(self, *args, **kwargs ):
		"""
		@return - Object the result of the parsing process
		"""
		raise NotImplementedError


class VerboseParser( AbstractParser ):
	'''
	In verbose mode, logs duration information while running each conversion step.
	Used here as a decorator for AbstractParser classes
	'''
	def __init__(self, parser, msg):
		'''
		@param parser - Parser (object extending AbstractParser)
		@param msg - Message to print before executing the parser
		'''
		self.parser = parser
		self.msg = msg
		
	
	def parse(self, *args, **kwargs):
		time_start = time.time()

		# call the decorated class' runner
		response = self.parser.parse(*args, **kwargs)
		
		time_end = time.time()
		time_diff = time_end - time_start
		print("%s - %s s\n" % ( self.msg, time_diff ) )
		
		return response
