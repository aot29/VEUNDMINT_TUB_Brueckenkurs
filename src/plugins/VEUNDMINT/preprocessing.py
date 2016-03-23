"""    
    VEUNDMINT plugin package
    Copyright (C) 2016  VE&MINT-Projekt - http://www.ve-und-mint.de

    The VEUNDMINT plugin package is free software; you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation; either version 3 of the License, or (at your
    option) any later version.

    The VEUNDMINT plugin package is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
    License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with the VEUNDMINT plugin package. If not, see http://www.gnu.org/licenses/.
"""

from plugins.VEUNDMINT import System as vsys
from plugins.VEUNDMINT import Option as opt
from plugins.VEUNDMINT.logging import Logging
#from plugins.VEUNDMINT.preprocessor import Preprocessor

import os


options = opt.Option(os.path.join(".."));

# Add VEUNDMINT logging functionality to the structure object (both under GPL license)
self.log = Logging(os.path.join(options.currentDir, options.logFilename), options.doverbose, options.consolecolors)
self.log.timestamp("VEUNDMINT log initialized")
vsys.log = self.log # References to the same object

# Prepare working folder
vsys.emptyTree(options.sourcepath)
vsys.copyFiletree(options.sourcepath_original, options.sourceTEX, ".")
self.log.timestamp("Source tex files copied")
if os.path.isfile(options.sourceTEXStartFile):
  self.log.message(self.log.VERBOSEINFO, "Found main tex file " + options.sourceTEXStartFile)
else:
  self.log.message(self.log.FATALERROR, "Main tex file " + options.sourceTEXStartFile + " not present in original source folder " + options.sourcepath_original)

# Prepare target folder
vsys.emptyTree(options.targetpath)
vsys.copyFiletree(options.converterCommonFiles, options.targetpath, ".")
self.log.timestamp("Common HTML tree files copied")

# Preprocessing of each tex file in the folder and subfolders
pathLen = len(options.sourceTEX)+1
fileArray=[]
for root,dirs,files in os.walk(options.sourceTEX):                
    root=root[pathLen:]
    for name in files:
        if (name[-4:] == ".tex"):
            fileArray.append(os.path.join(options.sourceTEX, root, name))
    for name in dirs:
        continue

self.log.message(self.log.VERBOSEINFO, "Preprocessor starting on " + str(len(fileArray)) + " texfiles")

pp_data = dict()
#proc = Preprocessor(log, pp_data)

for texfile in fileArray:
    tex = vsys.readTextFile(texfile, options.stdencoding)
    #tex = proc.preprocess_texfile(texfile, tex)
    vsys.writeTextFile(texfile, tex, options.stdencoding)
    




self.log.message(self.log.FATALERROR, "PREMATURE END")


