"""
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
	
	@author Daniel Haase for KIT 
	@author Niklas Plessing, Alvaro Ortiz for TU Berlin
"""
import os, subprocess, logging, re
import sys
from tex2x.Settings import settings
from tex2x.parsers.AbstractParser import AbstractParser

logger = logging.getLogger(__name__)

class TTMParser(AbstractParser):
	"""
	Class that can parse texfiles to xml. Relies on the 'ttm' binary.
	Can be decorated with VerboseParser to enable performance loging.
	"""

	def __init__(self, options, sys=None):
		"""
		@param options Object
		@param sys - "A module exposing a class System" (Daniel Haase) 
		@param ttmBin path to TTM binary		
		"""
		self.subprocess = None
		self.settings = settings
		self.options = options
		self.sys = sys
		self.ttmBin = settings.ttmBin


	def parse(self, sourceTEXStartFile=settings.sourceTEXStartFile, sourceTEX=settings.sourceTEX, ttmFile=settings.ttmFile, dorelease = settings.dorelease ):
		"""
		Executes the TTM command and creates a XML-file from Tex sources.
		Parses files from TeX to ?, uses the converterDir Option which is set to /src
		WARNING: an external program is being called here, so this could theoretically be a security liability
		
		@param sourceTEXStartFile path to source Tex file
		@param sourceTEX path to search for Tex input files
		@param ttmFile path to output XML file
		"""
		
		print ('TTMParser called with options sourceTEXStartFile: %s, sourceTEX: %s, ttmFile: %s' % (sourceTEXStartFile, sourceTEX, ttmFile))
		
		if hasattr(self.options, 'ttmExecute') and not self.options.ttmExecute:
			# try to get the XML-file if it exists, otherwise generate it
			if self.prepareXMLFile( sourceTEXStartFile, ttmFile ): return

		# Check that TTM is executable
		if not os.access( self.ttmBin, os.X_OK):
			print(self.ttmBin)
			raise Exception("ttm program file is not marked as executable, aborting")

		# Check that output dir exists
		if not os.path.exists( self.options.targetpath ):
			os.makedirs(self.options.targetpath)
			
		# TODO DH: Why exactly do we need this?
		self.sys.pushdir() # AO: when this is removed, then the output plugin starts in the wrong dir
		if not os.path.exists( sourceTEX ):
			os.makedirs( sourceTEX )

		os.chdir( sourceTEX )

		try:
			with open( ttmFile, "wb") as outfile, open( sourceTEXStartFile, "rb") as infile:
				self.subprocess = subprocess.Popen([ self.ttmBin, '-p', sourceTEX ], stdout = outfile, stdin = infile, stderr = subprocess.PIPE, shell = True, universal_newlines = True)

			self._logResults(self.subprocess, self.ttmBin, sourceTEXStartFile, dorelease )
		
			# if TTM worked, load the XML file
			xml = self.loadXML( ttmFile )

		# don't catch exception here, fatal exceptions should be handled at outer level
		finally:
			self.sys.popdir()
			pass

		return xml


	def getParserProcess(self):
		"""
		Return a reference to the ttmParser Process, might return None, when called
		before the parse function was called..
		"""
		return self.subprocess


	def getParserSys(self):
		return self.sys
	
	
	def prepareXMLFile(self, sourceTEXStartFile, ttmFile):
		"""
		If options.ttmExecute is False, verify that the XML-file exists, or return false
		
		@param sourceTEXStartFile path to source Tex file
		@param ttmFile path to output XML file
		"""
		if (os.path.exists( sourceTEXStartFile ) ):
			self.sys.copyFile( sourceTEXStartFile, ttmFile, "" )
			return True
		else:
			return False
		
		
	def loadXML(self, ttmFile):
		"""
		Load the XML file, do some replacement to fix MathML and entities problems
		@return: String - the XML as loaded from file
		"""
		xmlfile = open( ttmFile, "rb")
		try:
			xmltext = xmlfile.read().decode( 'utf8', 'ignore' ) # force utf8 here, otherwise it won't build
			
		finally:
			if xmlfile: xmlfile.close()
		
		return xmltext
		
		
	def _logResults( self, subprocess, ttmBin, sourceTEXStartFile, dorelease=0 ):
		"""
		Log the output from ttm_process in a human readable form. Is still using the system class. It
		might be good to use logging.Logger instead(?)
		@param subprocess - subprocess connecting to TTM input/output/error pipes and error codes
		@param ttmBin path to TTM binary
		@param sourceTEXStartFile - path to source Tex file
		@param dorelease - boolean, log a fatal error of unknown commands found
		"""
		if self.sys is not None and subprocess is not None:

			(output, err) = subprocess.communicate()

			if subprocess.returncode < 0:
				logger.log( logging.ERROR, "Call to " + self.ttmBin + " for file " + sourceTEXStartFile + " was terminated by a signal (POSIX return code " + ttm_process.returncode + ")")
			else:
				if subprocess.returncode > 0:
					logger.log( logging.ERROR, self.ttmBin + " reported an error in file " + sourceTEXStartFile + ", error lines have been written to logfile")
					s = output[-512:]
					s = s.replace("\n",", ")
					logger.log( logging.INFO, "Last lines: " + s)
				else:
					logger.log( logging.INFO, self.ttmBin + " finished successfully")

			# process output of ttm
			anl = 0 # abnormal newlines found by ttm
			cm = 0 # unknown latex commands
			ttmlines = err.split("\n")
			for i in range(len(ttmlines)):
				logger.debug("(ttm) %s" % ttmlines[i])
				logger.log( logging.INFO, "(ttm) " + ttmlines[i])
				m = re.search(r"\*\*\*\* Unknown command (.+?), ", ttmlines[i])
				if m:
					logger.log( logging.WARN, "ttm does not know LaTeX command " + m.group(1))
					cm += 1
				else:
					if "Abnormal NL, removespace" in ttmlines[i]:
						anl += 1
					else:
						if "Error: Fatal" in ttmlines[i]:
							logger.log( logging.ERROR, "ttm exit with fatal error: " + ttmlines[i] + ", aborting")


			if anl > 0:
				logger.log( logging.INFO, "ttm found " + str(anl) + " abnormal newlines")
				
			if (cm > 0) and (dorelease == 1):
				logger.log( logging.ERROR, "ttm found " + str(cm) + " unknown commands, refusing to continue on release version")
				sys.exit(3)
