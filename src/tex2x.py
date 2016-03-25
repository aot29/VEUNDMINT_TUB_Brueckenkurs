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
"""


"""
Ältere lxml Versionen könnten noch von folgendem Bug betroffen sein:
- https://github.com/lxml/lxml/commit/21eb9ec740589c9b265e5c83a76751a6015915b4
"""

#import html5lib
#from struct import Structure as st
from lxml import etree
import tex2xStruct as struct
import plugins
import os

import argparse


parser = argparse.ArgumentParser(description='tex2x converter')
parser.add_argument("plugin", help="specify the plugin you want to run")
parser.add_argument("-v", "--verbose", help="increases verbosity", action="store_true")
parser.add_argument("override", help = "override option values ", nargs = "*", type = str, metavar = "option=value")

args = parser.parse_args()
#print(args.plugin)
    
print("\ntex2x parser!\n\n")

#optionen = Option.Option()

#create object and start processing
struct.structure.Structure().startTex2x(args.verbose, args.plugin, args.override)





