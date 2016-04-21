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


from plugins.basic import System
from plugins.basic import Option as opt
import os

#print("aaa")


options = opt.Option(os.path.join(".."));

#print(os.path.abspath(os.path.join("..", "..")))
print(os.path.abspath(os.path.join(options.sourcepath_original,"files")))
print(os.path.abspath(os.path.join(options.sourcepath, "files")))
#print(os.path.abspath(os.path.join(os.path.join( "..", "..", "tmp_input"))))


System.copyFiletree(options.sourcepath_original, options.sourcepath, "files")
System.copyFiletree(options.sourcepath_original, options.sourcepath, "tex")
System.copyFiletree(options.sourcepath_original, options.sourcepath, "basic-HTML")
System.copyFiletree(options.sourcepath_original, options.sourcepath, "basic-SCORM")

