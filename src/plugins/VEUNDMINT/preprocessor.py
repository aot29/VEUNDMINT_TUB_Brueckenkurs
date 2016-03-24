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
import os.path
from plugins.VEUNDMINT import System as vsys


class Preprocessor(object):
    
    # Constructor parameters: log object reference and data storage for the plugin chain (dict), and options object reference
    def __init__(self, log, data, options):
        
        self.log = log
        self.data = data
        self.options = options
        vsys.log = self.log # References to the same object

        self.data['DirectRoulettes'] = {}

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
        if re.match(".*\\\\IncludeModule\{.+\}.*", tex, re.S):
            self.log.message(self.log.VERBOSEINFO, "Preprocessing ignores module-including file " + name)
            return tex
            
        self.log.message(self.log.VERBOSEINFO, "Preprocessing tex file " + name)
        m = re.match(r".*\\MSection\{(.+?)\}.*", tex, re.S)
        if m:
            self.log.message(self.log.VERBOSEINFO, "It is a course module: " + m.group(1))
        else:
            self.log.message(self.log.CLIENTWARN, "Unknown tex file type: " + name)


        if (self.options.dorelease == 1):
            if (not self.checkRelease(tex)):
                self.log.message(self.log.CLIENTERROR, "tex-file " + name + " did not pass release check");
             
            
        m = re.match(r"(.*)/(.*?).tex", name)
        if m:
            pdirname = m.group(1)
            self.log.message(self.log.VERBOSEINFO, "Preprocessing in directory " + pdirname)
        else:
            pdirname = ""
            self.log.message(self.log.CLIENTWARN, "texfile " + name + " does not have a directory")
      
            
        tex = self.preprocess_roulette(tex, pdirname)
            
            
        return tex
    
    
    def preprocess_roulette(self, tex, pdirname):             
          
        
        # First, include roulette exercise files in the code
        self.log.timestamp("Starting roulette preprocessing")
        rx = re.compile(r"\\MDirectRouletteExercises\{(.+?)\}\{(.+?)\}", re.S)
        roul = rx.findall(tex)
        if (len(roul) > 0):
            self.log.message(self.log.VERBOSEINFO, "Found " + str(len(roul)) + " MDirectRoueletteExercises")

        for m in roul:
            rfilename = m[0]
            self.log.message(self.log.VERBOSEINFO, "Roulette exercises taken from " + rfilename)
            rid = m[1]
            rfile = os.path.join(pdirname, rfilename)
            
            if rfilename[-4:] == ".tex":
                self.log.message(self.log.CLIENTWARN, "Roulette input file " + rfile + " is a pure tex file, please change the file name to non-tex to avoid double preparsing")
            else:
                self.log.message(self.log.VERBOSEINFO, "MDirectRouletteExercises on include file " + rfile + " with id " + rid)
            rtext = vsys.readTextFile(rfile, self.options.stdencoding)
          
            # Each exercise given in the include file is written to a separate div, only one of them being visible, although all question objects will be generated from start
            idd = 0
            htex = ""
            
            rx = re.compile(r"\\begin\{MExercise\}(.+?)\\end\{MExercise\}", re.S)
            exs = rx.findall(rtext)
            for ex in exs:
                content = ex
                rtext = rtext.replace(r"\begin{MExercise}" + content + r"\end{MExercise}", "", 1)
                htex += r"\special{html:<!-- rouletteexc-start;" + rid + r";" + str(idd) + r"; //-->}\begin{MExercise}" + content + r"\end{MExercise}\special{html:<!-- rouletteexc-stop;" + rid + r";" + str(idd) + r"; //-->}" + "\n"
                idd = idd + 1
            
            if re.search(r"\\begin\{MExercise\}", rtext):
                self.log.message(self.log.CLIENTERROR, "Roulette exercises not exhausted by exercise loop")

            rtext = r"\ifttm\special{html:<!-- directroulette-start;" + rid + r"; //-->}" + htex + r"\special{html:<!-- directroulette-stop;" + rid + r"; //-->}\else\texttt{Im HTML erscheinen hier Aufgaben aus einer Aufgabenliste...}\fi" + "\n"
            
            tex = tex.replace(r"\MDirectRouletteExercises{" + rfilename + r"}{" +rid + r"}", rtext, 1) 
            
            if rid in self.data['DirectRoulettes']:
                self.log.message(self.log.CLIENTERROR, "Roulette id " + rid + " is not unique")
            else:
                self.data['DirectRoulettes'][rid] = idd
                
            self.log.message(self.log.VERBOSEINFO, "Roulette " + rid + " contains " + str(idd) + " exercises") 


        self.log.timestamp("Finished roulette preprocessing")
        return tex
  