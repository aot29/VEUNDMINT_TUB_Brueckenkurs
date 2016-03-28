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


"""
    This is the preprocessor object associated to the mintmod macro package, 
    Version P0.1.0, needs to be consistent with mintmod.tex
"""


import re
import os.path
import subprocess


class Preprocessor(object):
    
    # Constructor parameters: log object reference and data storage for the plugin chain (dict), and options object reference
    def __init__(self, sys, data, options):
        
        self.sys = sys
        self.data = data
        self.options = options
        self.name = "MINTMODTEX"
        self.version ="P0.1.0"

        if 'DirectRoulettes' in self.data:
            sys.message(sys.CLIENTWARN, "Another Preprocessor is using DirectRoulettes")
        else:
            self.data['DirectRoulettes'] = {}

        if 'macrotex' in self.data:
            sys.message(sys.CLIENTWARN, "Using macrotex from an another preprocessor, hope it works out")
        else:
            # read original code of the macro package
            self.data['macrotex'] = self.sys.readTextFile(os.path.join(self.options.converterDir, "tex", self.options.macrofile), self.options.stdencoding)
            if re.search(r"\\MPragma{mintmodversion;" + self.version + r"}", self.data['macrotex'], re.S):
                self.sys.message(self.sys.VERBOSEINFO, "Macro package " + self.options.macrofile + " checked, seems to be ok")
            else:                
                self.sys.message(self.sys.CLIENTERROR, "Macro package " + self.options.macrofile + " does not provide macroset of preprocessor version")
            
        if 'modmacrotex' in self.data:
            sys.message(sys.CLIENTWARN, "Using MODIFIED macrotex from an another preprocessor, hope it works out")
        else:
            # use the original code for now
            self.data['modmacrotex'] = self.data['macrotex']


        if 'DirectHTML' in self.data:
            sys.message(sys.CLIENTWARN, "Another plugin has been using DirectHTML, appending existing values")
        else:
            self.data['DirectHTML'] = []
            
        if 'autolabels' in self.data:
            sys.message(sys.CLIENTWARN, "Another plugin has been using autolabels, appending existing values")
        else:
            self.data['autolabels'] = []

        if 'copyrightcollection' in self.data:
            sys.message(sys.CLIENTWARN, "Another plugin has been using copyrightcollection, appending existing values")
        else:
            self.data['copyrightcollection'] = ""


        # set data content used by this preprocessor object which need to be shared with other plugins
        self.data['htmltikz'] = dict() # entries are created by tikz preprocessing and associate a filename (without extension) to CSS-stylescale
            
            
            
            
        # set some data default values which may be overwritten by preprocessing pragmas
        self.data['htmltikzscale'] = 1.3

        # set some variables used only by this object
        self.globalexstring = "" # will be filled with exercise texts to be exported independently of the conversion

            
        self.sys.message(self.sys.VERBOSEINFO, "Preprocessor " + self.name + " of version " + self.version + " constructed")



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

    
        self.sys.timestamp("Finished preprocessor " + self.name)
        self.sys.message(self.sys.FATALERROR, "PREMATURE END")
        
        
        

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

        # Exclude special files from preprocessing
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
             
            
        m = re.match(r"(.*)/(.*?.tex)", name)
        if m:
            pdirname = m.group(1)
            pfilename = m.group(2)
            self.sys.message(self.sys.VERBOSEINFO, "Preprocessing file " + pfilename + " in directory " + pdirname)
        else:
            pdirname = ""
            pfilename = name
            self.sys.message(self.sys.CLIENTWARN, "texfile " + name + " does not have a directory")
      
            
        # application of preliminary changes to the tex code
        tex = self.preprocess_roulette(tex, pdirname)
        tex = self.preprocess_comments(tex)
        tex = self.preprocess_directhtml(tex)
        tex = self.preprocess_copyrights(tex, pfilename)





        # tikz preparation has to come last, as TikZ formulas contain arbitrary tex code which should be preprocessed and may depend on executed pragmas
        tex = self.preprocess_tikz(tex, pdirname, pfilename)
            
            
        return tex

    
    # preprocessing of roulette include statements
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


    # preprocessing of LaTeX comments (and verb constructs which may contain % in text or as a delimiter)
    def preprocess_comments(self, tex):
        # find single characters used with \verb
        rx = re.compile(r"\\verb(.)", re.S)
        verbac = rx.findall(tex)
        
        # create list which contains no double verb-chars
        verbc = []
        for c in verbac:
            if not c in verbc:
                verbc.append(c)
            
        if (len(verbc) > 0):
            self.sys.message(self.sys.CLIENTWARN, str(len(verbc)) + " verb-delimiters found in tex-file, usage of \\verb will be handled by preprocessing, but probably not by ttm")


        # \PERCTAG is used to escape % used in verb-constructs (as verb-delimiter or inside the verb string)
        for c in verbc:
            if c == r"%":
                # escape % as a verb-delimiter, now it's sure no % appears inside the verb string
                tex = re.sub(r"\\verb\%([^\%]*?)\%", r"\\verb\\PERCTAG\1\\PERCTAG", tex, count = 0, flags = re.S)
            else:
                # escape % as a comment truncator insinde the verb string, now it's sure the delimiter is not %
                # but we have to escape c because it may be a regex symbol or a backlash
                found = True
                n = 0
                while found:
                    (tex, k) = re.subn(r"\\verb" + re.escape(c) + r"([^" + re.escape(c) + r"]*?)%([^" + re.escape(c) + r"]*?)" + re.escape(c),
                                       r"\\verb" + c + r"\1\\PERCTAG\2" + c,
                                       tex, count = 0, flags = re.S)
                    if k == 0:
                        found = False
                
                
        # remove CONTENT(!) of comment lines, take care not to remove \%, replace \PERCTAG by % afterwards
        tex = re.sub(r"(?<!\\)\%([^\n]+?)\n", "%\n", tex, count = 0, flags = re.S)
        tex = tex.replace(r"\PERCTAG", r"%") # re-escape %
        

        return tex
                

    def preprocess_directhtml(self, tex):
      # prepare exercises for export if requested
      if (self.options.qautoexport == 1):
          tex = re.sub(r"\\begin\{MExercise\}(.+?)\\end\{MExercise\}", r"\\begin{MExportExercise}\1\end{MExportExercise}", tex, 0, re.S)

      m = re.search(r"\\MSection{(.+?)}", tex, re.S)
      if m:
          self.globalexstring = self.globalexstring + "\\MSubsubsectionx{" + m.group(1) + "}\n"


      # exercise environments marked for export (either by qautoexport or by the module author) are translated to DirectHTML before any preprocessing happens
      qex = 0
      def fexport(part):
          nonlocal qex
          self.globalexstring = self.globalexstring + "\\ \\\\\n\\begin{MExercise}\n" + part.group(1) + "\n\\end{MExercise}\n"
          s = "\\begin{MExercise}" + part.group(1) + "\\end{MExercise}\n\\begin{MDirectHTML}\n<!-- qexportstart;" + str(qex) + "; //-->" + part.group(1) + "<!-- qexportend;" + str(qex) + "; //-->\n\\end{MDirectHTML}"
          qex = qex + 1
          return s
      tex = re.sub(r"\\begin\{MExportExercise\}(.+?)\\end\{MExportExercise\}", fexport, tex, 0, re.S) 

      # MDirectMath processing (as DirectHTML)
      def dmath(part):
          self.data['DirectHTML'].append("\\[" + part.group(1) + "\\]")
          return "\\ifttm\\special{html:<!-- directhtml;;" + str(len(self.data['DirectHTML']) - 1) + "; //-->}\\fi"
      tex = re.sub(r"\\begin\{MDirectMath\}(.+?)\\end\{MDirectMath}", dmath, tex, 0, re.S)
      
      
      # MDirectHTML processing
      def dhtml(part):
          self.data['DirectHTML'].append(part.group(1))
          return "\\ifttm\\special{html:<!-- directhtml;;" + str(len(self.data['DirectHTML']) - 1) + "; //-->}\\fi"
      tex = re.sub(r"\\begin\{MDirectHTML\}(.+?)\\end\{MDirectHTML}", dhtml, tex, 0, re.S)

      return tex


    def preprocess_copyrights(self, tex, pfilename):
    # copyright processing, exports, tikz-generation and DirectHTML processing must happen before this one

        # attach standard MINT authorship and CC license to each auto tikz image
        def ctikz(part):
            label = self._autolabel()
            return "\MCopyrightLabel{" + label + "}\\MCopyrightNotice{\\MCCLicense}{TIKZ}{MINT}{TikZ-Quelltext in der Datei " + pfilename + "}{" + label + "}\\MTikzAuto{"
            
        (tex, n) = re.subn(r"\\MTikzAuto\{", ctikz, tex, 0, re.S)
        if (n > 0):
            self.sys.message(self.sys.VERBOSEINFO, "Forcibly attached CC licenses to " + str(n) + " tikz pictures in this files")
    
    
        def cright(part):
            authortext = ""
            if part.group(3) == "MINT":
                authortext = "\\MExtLink{http://www.mint-kolleg.de}{MINT-Kolleg Baden-Württemberg}"
            else:
                if part.group(3) == "VEMINT":
                    authortext = "\\MExtLink{http://www.vemint.de}{VEMINT-Konsortium}"
                else:
                    if part.group(3) == "NONE":
                        authortext = "Unbekannter Autor"
                    else:
                        authortext = "\\MExtLink{" + part.group(3) + "}{Autor}"
      
            if part.group(2) == "NONE":
                self.data['copyrightcollection'] = self.data['copyrightcollection'] + "\\MCRef{" + part.group(5) + "} & " + part.group(1) + " & " + authortext +" & Ersterstellung & " + part.group(4) + " \\\\ \\ \\\\\n"
            else:
                if part.group(2) == "TIKZ":
                    self.data['copyrightcollection'] = self.data['copyrightcollection'] + "\\MCRef{" + part.group(5) + "} & " + part.group(1) + " & " + authortext + " & Grafikdatei erzeugt aus tikz-Code & " + part.group(4) + " \\\\ \\ \\\\\n"
                else:
                    if part.group(2) == "FSZ":
                        self.data['copyrightcollection'] = self.data['copyrightcollection'] + "\\MCRef{" + part.group(5) + "} & " + part.group(1) + " & " + authortext + " & Aufgenommen im \\MExtLink{http://www.fsz.kit.edu}{Fernstudienzentrum} des \\MExtLink{http://www.kit.edu}{KIT} & " + part.group(4) + " \\\\ \\ \\\\\n"
                    else:
                        self.data['copyrightcollection'] = self.data['copyrightcollection'] + "\\MCRef{" + part.group(5) + "} & " + part.group(1) + " & " + authortext + " & \\MExtLink{" + part.group(2) + "}{Originaldatei} & " + part.group(4) + " \\\\ \\ \\\\\n"

            
            return "\\MCopyrightNoticePOST{" + part.group(1) + "}{" + part.group(2) + "}{" + part.group(3) + "}{" + part.group(4) + "}{" + part.group(5) + "}"
    
        tex = re.sub(r"\\MCopyrightNotice\{(.+?)\}\{(.+?)\}\{(.+?)\}\{(.+?)\}\{(.+?)\}", cright, tex, 0, re.S)

        return tex
    
    
    def preprocess_tikz(self, tex, pdirname, pfilename):
        # check if tikz-externalization is actually requested and if the tex supports it
        dotikzfile = False
        if re.search(r"\\tikzexternalize", tex, re.S):
            self.sys.message(self.sys.CLIENTWARN, "texfile contains \\tikzexternalize, which should be changed to \\Mtikzexternalize")
        if re.search(r"\\tikzsetexternalprefix", tex, re.S):
            self.sys.message(self.sys.CLIENTWARN, "texfile contains \\tikzsetexternalprefix which interferes with tikz automatization")
        (tex, n) = re.subn(r"\\Mtikzexternalize", r"", tex, 0, re.S)
        if n > 0:
            if (self.options.dotikz == 0):
                self.sys.message(self.sys.VERBOSEINFO, "Mtikzexternalize ignored, present externalized files will be used")
            else:
                self.sys.message(self.sys.VERBOSEINFO, "Mtikzexternalize activated, externalized files will be generated")
                dotikzfile = True
        else:
            if re.search(r"\\MTikzAuto", tex, re.S):
                self.sys.message(self.sys.CLIENTWARN, "texfile contains MTikzAuto environments, but not \\Mtikzexternalize")
                

        # switch to local tex directory, externalize if requested, and convert image formats            
        self.sys.pushdir()
        os.chdir(pdirname)

        # call pdflatex to externalize tikz pictures if requested, but some preparations are needed
        if dotikzfile:
            self.sys.timestamp("Calling pdflatx in directory " + pdirname + " to create externalized images")

            # Carefull: modifications HAVE NOT BEEN WRITTEN at this point, should be corrected
            
            # Install modified local macro package and used style files, we're in the local directory,
            # don't use a direct copy, always check and modify the encoding if needed
            self.sys.writeTextFile(self.options.macrofile, self.data['modmacrotex'], self.options.stdencoding)
            for f in self.options.texstylefiles:
                self.sys.writeTextFile(f, self.sys.readTextFile(os.path.join(self.options.converterDir, "tex", f), self.options.stdencoding), self.options.stdencoding)
                
            p = subprocess.Popen(["pdflatex", "-halt-on-error", "-interaction=errorstopmode", "-shell-escape", pfilename], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
            (output, err) = p.communicate()
            
            if p.returncode < 0:
                self.sys.message(self.sys.FATALERROR, "Call to pdflatex for file " + pfilename + " during tikz externatlization was terminated by a signal (POSIX return code " + p.returncode + ")")
            else:
                if p.returncode > 0:
                    self.sys.message(self.sys.CLIENTERROR, "pdflatex could not process file " + pfilename + ", pdflatex error lines have been written to logfile")
                    s = output[-256:]
                    s = s.replace("\n",", ")
                    self.sys.message(self.sys.VERBOSEINFO, "Last pdflatex lines: " + s)
                else:
                    self.sys.timestamp("pdflatex finished successfully")
            
            # remove local style files and the macro package
            for f in self.options.texstylefiles:
                self.sys.removeFile(f)
            self.sys.removeFile(self.options.macrofile)

        # assume pngs have been provided in the original source directory if dotikz was false
        m = re.search(r"\\MSetSectionID{(.+?)}", tex, re.S)
        if m:
            # Files $tid?.png, $tid?.svg anf $tid.4x.png should be present (matching generator definition in mintmod.tex)
            tid = m.group(1) + r"mtikzauto_"
            self.sys.message(self.sys.VERBOSEINFO, "Module section id is "  + m.group(1) + ", TikZ id is " + tid)
            j = 1
            ok = True
           
            while (ok):
                ok = False
                tname = tid + str(j)
               
                if os.path.isfile(tname + ".svg"):
                    self.sys.message(self.sys.VERBOSEINFO, "  externalized svg found: " + tname + ".svg")
                    ok = True
                    
                if os.path.isfile(tname + ".4x.png"):
                    self.sys.message(self.sys.VERBOSEINFO, "  externalized hi-res png found: " + tname + ".4x.png")
                    ok = True

                if os.path.isfile(tname + ".png"):
                    ok = True
                    p = subprocess.Popen(["file", tname + ".png"], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
                    (output, err) = p.communicate()
                    fm = re.search(tname + r"\.png: PNG image data, ([0123456789]+?) x ([0123456789]+?),", output, re.S)
                    if fm:
                        sizex = int(fm.group(1))
                        sizey = int(fm.group(2))
                        self.sys.message(self.sys.VERBOSEINFO, "  externalized png found: " + tname + ".png, size is " + str(sizex) + "x" + str(sizey))
                        sizex = int(sizex * self.data['htmltikzscale'])
                        sizey = int(sizey * self.data['htmltikzscale'])
                        self.sys.message(self.sys.VERBOSEINFO, "  rescaled to " + str(sizex) + "x" + str(sizey))
                        if tname in self.data['htmltikz']: 
                            self.sys.message(self.sys.CLIENTERROR, "  externalized file name " + tname + " not unique, refusing to save sizes")
                        else:
                            self.data['htmltikz'][tname] = "width:" + str(sizex) + "px;height:" + str(sizey) + "px"
                    else:
                        self.sys.message(self.sys.CLIENTERROR, "  externalized png found: " + tname + ".png, but could not determine its size")

                j = j + 1
                
        else:
            self.sys.message(self.sys.VERBOSEINFO, "  No section id found")


        self.sys.popdir()
        return tex
        
    def _autolabel(self):
        # generate a label string which is unique in the entire module tree
        j = len(self.data['autolabels'])
        s = "L_SOURCEAUTOLABEL_" + str(j)
        self.data['autolabels'].append(s)
        return s
        