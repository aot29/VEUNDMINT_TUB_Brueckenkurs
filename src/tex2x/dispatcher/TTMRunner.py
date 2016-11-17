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
import os
from tex2x.parsers.TTMParser import TTMParser
from tex2x.dispatcher.runners import AbstractRunner

class TTMRunner( AbstractRunner ):
	'''
	Run TTM parser.
	Can be decorated with VerboseDecorator to enable performance loging.
	'''
	def __init__(self, options, sys):
		'''
		@param options Object
		@param sys - "A module exposing a class System" (Daniel Haase) 
		'''
		self.options = options
		self.sys = sys
		

	def run(self):
		if self.options.ttmExecute:
			self.start_ttm()
		else:
			# try to get the XML-file if it exists, otherwise generate it
			if not self.prepare_xml_file(): self.start_ttm()


	def start_ttm(self):
		"""
		Executes the TTM command and creates a XML-file from Tex sources.
		WARNING: an external program is being called here, so this could theoretically be a security liability
		"""
		# Check that TTM is executable
		if not os.access(os.path.join(self.options.ttmPath, "ttm"), os.X_OK):
			self.sys.message(self.sys.FATALERROR, "ttm program file is not marked as executable, aborting")

		# Check that output dir exists
		if not os.path.exists(self.options.targetpath):
			os.makedirs(self.options.targetpath)

		#start TTM
		ttm_parser = TTMParser(sys=self.sys)
		ttm_parser.parse()


	def prepare_xml_file(self):
		"""
		Verify that the XML-file exists, or return false
		"""
		if (os.path.exists(self.options.sourceTEXStartFile)):
			self.sys.copyFile(self.options.sourceTEXStartFile, self.options.ttmFile, "")
			return True
		else:
			return False