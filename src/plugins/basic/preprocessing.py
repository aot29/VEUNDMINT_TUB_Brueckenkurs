"""    
    tex2x converter - Processes tex-files in order to create various output formats via plugins
    Copyright (C) 2015  VEMINT-Konsortium - http://www.vemint.de

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
"""


from tex2x.System import ve_system as sys
from tex2x.Settings import ve_settings as settings
import os
from tex2x.AbstractPreprocessor import AbstractPreprocessor

class BasicPreprocessor(AbstractPreprocessor):

	def __init__(self, data = None):
		#options = opt.Option(os.path.join(".."));
		
		#print(os.path.abspath(os.path.join("..", "..")))
		#print(os.path.abspath(os.path.join(options.sourcepath_original,"files")))
		#print(os.path.abspath(os.path.join(options.sourcepath, "files")))
		#print(os.path.abspath(os.path.join(os.path.join( "..", "..", "tmp_input"))))
		pass
	
	def preprocess(self):
		sys.copyFiletree(settings.converterDir, settings.sourcepath, "files")
		sys.copyFiletree(settings.converterDir, settings.sourcepath, "tex")
	#	sys.copyFiletree(settings.converterDir, settings.sourcepath, "basic-HTML")
	#	sys.copyFiletree(settings.converterDir, settings.sourcepath, "basic-SCORM")
	
