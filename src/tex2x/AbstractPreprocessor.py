## @package tex2x.AbstractPlugin
#  Base classes for all preprocessors.
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
import os
import re
from tex2x.System import ve_system as sys
from tex2x.Settings import settings


class AbstractPreprocessor(object):
	name = "MINTMODTEX"
	version ="P0.1.0"
	copyrightcollection = ""
	directexercises = ""

	## Class variable fileArray contains a list of all .tex files except the macrofile
	fileArray = None

	def __init__(self):
		raise NotImplementedError

	def process(self):
		raise NotImplementedError

	def _installPackages(self):
		# installs modified local macro package and used style files in the current directory
		# don't use a direct copy, always check and modify the encoding if needed
		sys.writeTextFile(settings.macrofile, self.data['modmacrotex'], settings.stdencoding)
		for f in settings.texstylefiles:
			sys.writeTextFile(f, sys.readTextFile(os.path.join(settings.converterDir, "tex", f), settings.stdencoding), settings.stdencoding)
		return

	def _removePackages(self):
		# removes local macro package and style files in the current directory
		for f in settings.texstylefiles:
			sys.removeFile(f)
		sys.removeFile(settings.macrofile)

	def getFileList(self):
		"""
		Class variable fileArray contains a list of all .tex files except the macrofile
		"""

		if self.fileArray is not None: return self.fileArray

		# Preprocessing of each tex file in the folder and subfolders
		pathLen = len(settings.sourceTEX) + 1
		self.fileArray = []
		for root,dirs,files in os.walk(settings.sourceTEX):
			root = root[pathLen:]
			for name in files:
				if re.match(".*" + settings.macrofilename  + "\\.tex", name):
					sys.message(sys.VERBOSEINFO, "Preprocessing and release check ignores macro file " + name)
					continue

				if (name[-4:] == ".tex"):
					# store path to source copy and original source file
					self.fileArray.append([os.path.join(settings.sourceTEX, root, name), os.path.join(settings.sourcepath_original, root, name)])

			for name in dirs:
				continue

		return self.fileArray
