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
from tex2x.System import ve_system as sys
from tex2x.Settings import ve_settings as settings


class AbstractPreprocessor(object):
	name = "MINTMODTEX"
	version ="P0.1.0"
	copyrightcollection = ""
	directexercises = ""
		
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
		# removeslocal macro package and style files in the current directory
		for f in settings.texstylefiles:
			sys.removeFile(f)
		sys.removeFile(settings.macrofile)
	
