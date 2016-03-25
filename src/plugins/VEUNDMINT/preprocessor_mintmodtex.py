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


class Preprocessor(object):
    
    # Constructor parameters: log object reference and data storage for the plugin chain (dict), and options object reference
    def __init__(self, sys, data, options):
        
        self.sys = sys
        self.data = data
        self.options = options
        self.name = "MINTMODTEX"

        if 'DirectRoulettes' in self.data:
            sys.message(sys.CLIENTWARN, "Another Preprocessor is using DirectRoulettes")
        else:
            self.data['DirectRoulettes'] = {}


    # main function to be called from tex2x
    def preprocess(self):
        self.sys.timestamp("Starting preprocessor " + self.name)

        # Prepare working folder
        self.sys.emptyTree(self.options.sourcepath)
        self.sys.copyFiletree(self.options.texCommonFiles, self.options.sourceTEX, ".")
        self.sys.copyFiletree(self.options.sourcepath_original, self.options.sourceTEX, ".")
        self.sys.timestamp("Source and common tex files copied")
        if os.path.isfile(self.options.sourceTEXStartFile):
            self.sys.message(self.sys.VERBOSEINFO, "Found main tex file " + self.options.sourceTEXStartFile)
        else:
            self.sys.message(self.sys.FATALERROR, "Main tex file " + self.options.sourceTEXStartFile + " not present in original source folder " + self.options.sourcepath_original)

        # Prepare target folder
        self.sys.emptyTree(self.options.targetpath)
        self.sys.copyFiletree(self.options.converterCommonFiles, self.options.targetpath, ".")
        self.sys.timestamp("Common HTML tree files copied")

        # Preprocessing of each tex file in the folder and subfolders
        pathLen = len(self.options.sourceTEX) + 1
        fileArray = []
        for root,dirs,files in os.walk(self.options.sourceTEX):                
            root = root[pathLen:]
            for name in files:
                if (name[-4:] == ".tex"):
                    fileArray.append(os.path.join(self.options.sourceTEX, root, name))
            for name in dirs:
                continue

        self.sys.message(self.sys.VERBOSEINFO, "Preprocessor working on " + str(len(fileArray)) + " texfiles")

        for texfile in fileArray:
            tex = self.sys.readTextFile(texfile, self.options.stdencoding)
            tex = self.preprocess_texfile(texfile, tex)
            self.sys.writeTextFile(texfile, tex, self.options.stdencoding)
    
        self.sys.message(self.sys.FATALERROR, "PREMATURE END")
        
        self.sys.timestamp("Finished preprocessor " + self.name)

    # Checks if given tex code is valid for a release version
    # Return value: boolean True if release check passed
    def checkRelease(self, tex):
        reply = True
        # no experimental environments
        if (re.match(r".*\\begin{MExperimental}.*", tex, re.S)):
            self.sys.message(self.sys.VERBOSEINFO, "MExperimental found in tex file");
            reply = False
        if (re.match(r".*\% TODO.*", tex, re.S)):
            self.sys.message(self.sys.VERBOSEINFO, "TODO comment found in tex file");
            reply = False
            
        return reply

        

    # Preprocess a tex file (given name and content as unicode strings)
    # Return value: processed tex (may be unchanged)
    def preprocess_texfile(self, name, tex):

        # Exclude special files
        if re.match(".*" + self.options.macrofilename  + "\\.tex", name):
            self.sys.message(self.sys.VERBOSEINFO, "Preprocessing ignores macro file " + name)
            return tex
        if re.match(".*" + self.options.module, name): #  . from file expansion is read as any letter due to regex rules, but it's ok
            self.sys.message(self.sys.VERBOSEINFO, "Preprocessing ignores module main file " + name)
            return tex
        for pfilename in self.options.generate_pdf:
            if re.match(".*" + pfilename + "\\.tex", name):
                self.sys.message(self.sys.VERBOSEINFO, "Preprocessing ignores pdf main file " + name)
                return tex
        if re.match(".*\\\\IncludeModule\{.+\}.*", tex, re.S):
            self.sys.message(self.sys.VERBOSEINFO, "Preprocessing ignores module-including file " + name)
            return tex
            
        self.sys.message(self.sys.VERBOSEINFO, "Preprocessing tex file " + name)
        m = re.match(r".*\\MSection\{(.+?)\}.*", tex, re.S)
        if m:
            self.sys.message(self.sys.VERBOSEINFO, "It is a course module: " + m.group(1))
        else:
            self.sys.message(self.sys.CLIENTWARN, "Unknown tex file type: " + name)


        if (self.options.dorelease == 1):
            if (not self.checkRelease(tex)):
                self.sys.message(self.sys.CLIENTERROR, "tex-file " + name + " did not pass release check");
             
            
        m = re.match(r"(.*)/(.*?).tex", name)
        if m:
            pdirname = m.group(1)
            self.sys.message(self.sys.VERBOSEINFO, "Preprocessing in directory " + pdirname)
        else:
            pdirname = ""
            self.sys.message(self.sys.CLIENTWARN, "texfile " + name + " does not have a directory")
      
            
        tex = self.preprocess_roulette(tex, pdirname)
            
            
        return tex
    
    
    def preprocess_roulette(self, tex, pdirname):             
          
        
        # First, include roulette exercise files in the code
        self.sys.timestamp("Starting roulette preprocessing")
        rx = re.compile(r"\\MDirectRouletteExercises\{(.+?)\}\{(.+?)\}", re.S)
        roul = rx.findall(tex)
        if (len(roul) > 0):
            self.sys.message(self.sys.VERBOSEINFO, "Found " + str(len(roul)) + " MDirectRoueletteExercises")

        for m in roul:
            rfilename = m[0]
            self.sys.message(self.sys.VERBOSEINFO, "Roulette exercises taken from " + rfilename)
            rid = m[1]
            rfile = os.path.join(pdirname, rfilename)
            
            if rfilename[-4:] == ".tex":
                self.sys.message(self.sys.CLIENTWARN, "Roulette input file " + rfile + " is a pure tex file, please change the file name to non-tex to avoid double preparsing")
            else:
                self.sys.message(self.sys.VERBOSEINFO, "MDirectRouletteExercises on include file " + rfile + " with id " + rid)
            rtext = self.sys.readTextFile(rfile, self.options.stdencoding)
          
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
                self.sys.message(self.sys.CLIENTERROR, "Roulette exercises not exhausted by exercise loop")

            rtext = r"\ifttm\special{html:<!-- directroulette-start;" + rid + r"; //-->}" + htex + r"\special{html:<!-- directroulette-stop;" + rid + r"; //-->}\else\texttt{Im HTML erscheinen hier Aufgaben aus einer Aufgabenliste...}\fi" + "\n"
            
            tex = tex.replace(r"\MDirectRouletteExercises{" + rfilename + r"}{" +rid + r"}", rtext, 1) 
            
            if rid in self.data['DirectRoulettes']:
                self.sys.message(self.sys.CLIENTERROR, "Roulette id " + rid + " is not unique")
            else:
                self.data['DirectRoulettes'][rid] = idd
                
            self.sys.message(self.sys.VERBOSEINFO, "Roulette " + rid + " contains " + str(idd) + " exercises") 


        self.sys.timestamp("Finished roulette preprocessing")
        return tex
  