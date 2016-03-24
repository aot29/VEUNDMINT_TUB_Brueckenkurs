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

import re

class Preprocessor(object):
    
    # Constructor parameters: log object reference and data storage for the plugin chain (dict), and options object reference
    def __init__(self, log, data, options):
        self.log = log
        self.data = data
        self.options = options


    # Checks if given tex code is valid for a release version
    # Return value: boolean True if release check passed
    def checkRelease(self, tex):
        reply = True
        # no experimental environments
        if (re.match(r".*\\begin{MExperimental}.*", tex, re.S)):
            self.log.message(self.log.VERBOSEINFO, "MExperimental found in tex file");
            reply = False
        if (re.match(r".*\% TODO.*", tex, re.S)):
            self.log.message(self.log.VERBOSEINFO, "TODO comment found in tex file");
            reply = False
            
        return reply

        

    # Preprocess a tex file (given name and content as unicode strings)
    # Return value: processed tex (may be unchanged)
    def preprocess_texfile(self, name, tex):

        # Exclude special files
        if re.match(".*" + self.options.macrofilename  + "\\.tex", name):
            self.log.message(self.log.VERBOSEINFO, "Preprocessing ignores macro file " + name)
            return tex
        if re.match(".*" + self.options.module, name): #  . from file expansion is read as any letter due to regex rules, but it's ok
            self.log.message(self.log.VERBOSEINFO, "Preprocessing ignores module main file " + name)
            return tex
        for pfilename in self.options.generate_pdf:
            if re.match(".*" + pfilename + "\\.tex", name):
                self.log.message(self.log.VERBOSEINFO, "Preprocessing ignores pdf main file " + name)
                return tex
        if re.match(".*\\\\IncludeModule{.+}.*", tex, re.S):
            self.log.message(self.log.VERBOSEINFO, "Preprocessing ignores module-including file " + name)
            return tex
            
        self.log.message(self.log.VERBOSEINFO, "Preprocessing tex file " + name)
        m = re.match(r".*\\MSection{(.+?)}.*", tex, re.S)
        if m:
            self.log.message(self.log.VERBOSEINFO, "It is a course module: " + m.group(1))
        else:
            self.log.message(self.log.CLIENTWARN, "Unknown tex file type: " + name)


        if (self.options.dorelease == 1):
            if (not self.checkRelease(tex)):
                self.log.message(self.log.CLIENTERROR, "tex-file " + name + " did not pass release check");
             
            
            
            
        return tex
    
    
             
      
      
