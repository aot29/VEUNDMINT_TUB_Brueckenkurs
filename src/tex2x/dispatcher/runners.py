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

class AbstractRunner(object):
	'''
	Template method pattern: 	
	"Define the skeleton of an algorithm in an operation, deferring some steps to subclasses. 
	Lets subclasses redefine certain steps of an algorithm without changing the algorithm's structure." 
	- Gamma, Helm, Johnson, Vlissides (1995) 'Design Patterns: Elements of Reusable Object-Oriented Software'
	'''
	def run(self):
		raise NotImplementedError


class VerboseDecorator( AbstractRunner ):
	'''
	In verbose mode, logs duration information 
	while running each conversion step.
	Used here as a decorator for AbstractRunner classes
	'''
	def __init__(self, runner, msg):
		'''
		@param runner - Runner (object extending AbstractRunner)
		@param msg - Message to print before executing the runner
		'''
		self.runner = runner
		self.msg = msg
		
	
	def run(self):
		print( self.msg )
		time_start = time.time()

		# call the decorated class' runner
		response = self.runner.run()
		
		time_end = time.time()
		time_diff = time_end - time_start
		print("Duration: %s\n" % time_diff )
		
		return response


class PreprocessorRunner( AbstractRunner ):
	'''
	Run pre-processing plugins.
	Can be decorated with VerboseDecorator for performance logs.
	'''
	def __init__(self, plugins):
		'''
		@param plugins - list of "Preprocessor modules" (Daniel Haase)
		'''
		self.plugins = plugins
	
	def run(self):
		for pp in self.plugins:
			pp.preprocess()

	