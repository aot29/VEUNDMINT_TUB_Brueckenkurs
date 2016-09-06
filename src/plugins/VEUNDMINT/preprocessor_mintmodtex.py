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
	def __init__(self, interface):
		
		# copy interface member references
		self.sys = interface['system']
		self.data = interface['data']
		self.options = interface['options']
		self.name = "MINTMODTEX"
		self.version ="P0.1.0"
		self.sys.message(self.sys.VERBOSEINFO, "Preprocessor " + self.name + " of version " + self.version + " constructed")

	def _prepareData(self):
		# checks if needed data members are present or empty
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


		# append signature values as LaTeX macros
		self._addTeXMacro("MSignatureMain", self.options.signature_main)
		self._addTeXMacro("MSignatureVersion", self.options.signature_version)
		self._addTeXMacro("MSignatureLocalization", self.options.signature_localization)
		self._addTeXMacro("MSignatureVariant", self.options.variant)
		self._addTeXMacro("MSignatureDate", self.options.signature_date)

		if 'DirectHTML' in self.data:
			sys.message(sys.CLIENTWARN, "Another plugin has been using DirectHTML, appending existing values")
		else:
			self.data['DirectHTML'] = []
			
		if 'directexercises' in self.data:
			sys.message(sys.CLIENTWARN, "Another plugin has been using directexercises, appending existing values")
		else:
			self.data['directexercises'] = ""

		if 'autolabels' in self.data:
			sys.message(sys.CLIENTWARN, "Another plugin has been using autolabels, appending existing values")
		else:
			self.data['autolabels'] = []

		if 'copyrightcollection' in self.data:
			sys.message(sys.CLIENTWARN, "Another plugin has been using copyrightcollection, appending existing values")
		else:
			self.data['copyrightcollection'] = ""

		if 'htmltikz' in self.data:
			sys.message(sys.CLIENTWARN, "Another plugin has been using htmltikz, appending existing values")
		else:
			self.data['htmltikz'] = dict() # entries are created by tikz preprocessing and associate a filename (without extension) to CSS-stylescale
		

	def _autolabel(self):
		# generate a label string which is unique in the entire module tree
		j = len(self.data['autolabels'])
		s = "L_SOURCEAUTOLABEL_" + str(j)
		self.data['autolabels'].append(s)
		return s


	# main function to be called from tex2x
	def preprocess(self):
		self.sys.timestamp("Starting preprocessor " + self.name)

		self._prepareData()

		# collect copyrightstatements and exerciseexports from this processing event and add them later to the global collection
		self.copyrightcollection = ""
		self.directexercises = ""

		# Prepare working folder
		self.sys.emptyTree(self.options.sourcepath)
		self.sys.copyFiletree(self.options.texCommonFiles, self.options.sourceTEX, ".")
		self.sys.copyFiletree(self.options.sourcepath_original, self.options.sourceTEX, ".")
		self.sys.timestamp("Source and common tex files copied")
		if os.path.isfile(self.options.sourceTEXStartFile):
			self.sys.message(self.sys.VERBOSEINFO, "Found main tex file " + self.options.sourceTEXStartFile)
		else:
			self.sys.message(self.sys.FATALERROR, "Main tex file " + self.options.sourceTEXStartFile + " not present in original source folder " + self.options.sourcepath_original)

		# initialize course variant data
		self.variant = self.options.variant
		self.sys.message(self.sys.CLIENTINFO, "Preprocessor uses course variant " + self.variant)
		# modify macro package to variant (as a variable, not a file yet)
		(self.data['modmacrotex'], k) = re.subn(r"\\variantstdtrue", "\\\\variant" + self.variant + "true % this string was added by tex2x VEUNDMINT preprocessor\n", self.data['modmacrotex'], 0, re.S)
		if (k == 1):
			self.sys.message(self.sys.VERBOSEINFO, "Preparing $macrofile for variant " + self.variant)
		else:
			self.sys.message(self.sys.CLIENTERROR, "Variant selection statement \\variantstdtrue found " + str(k) + " times in macro file")
  
		# Preprocessing of each tex file in the folder and subfolders
		pathLen = len(self.options.sourceTEX) + 1
		fileArray = []
		for root,dirs,files in os.walk(self.options.sourceTEX):				
			root = root[pathLen:]
			for name in files:
				if (name[-4:] == ".tex"):
					# store path to source copy and original source file
					fileArray.append([os.path.join(self.options.sourceTEX, root, name), os.path.join(self.options.sourcepath_original, root, name)])
			for name in dirs:
				continue

		self.sys.message(self.sys.VERBOSEINFO, "Preprocessor working on " + str(len(fileArray)) + " texfiles")

		nonpass = 0
		for texfile in fileArray:
			if re.match(".*" + self.options.macrofilename  + "\\.tex", texfile[0]):
				self.sys.message(self.sys.VERBOSEINFO, "Preprocessing and release check ignores macro file " + texfile[0])
			else:
				tex = self.sys.readTextFile(texfile[0], self.options.stdencoding)
				if not self.checkRelease(tex, texfile[1]):
					nonpass += 1
					self.sys.message(self.sys.VERBOSEINFO, "Original tex-file " + texfile[1] + " did not pass release check");
					if (self.options.dorelease == 1):
						self.sys.message(self.sys.FATALERROR, "Refusing to continue with dorelease=1 after checkRelease failed, see logfile for details")

			
				tex = self.preprocess_texfile(texfile[0], tex)
				self.sys.writeTextFile(texfile[0], tex, self.options.stdencoding)
		
		self.sys.message(self.sys.CLIENTINFO, "Preparsing of " + str(len(fileArray)) + " texfiles finished")
		self.sys.message(self.sys.CLIENTINFO, str(nonpass) + " files did not pass the release test, see logfile for details")
		self.sys.message(self.sys.CLIENTINFO, "A total of " + str(len(self.data['DirectHTML'])) + " DirectHTML blocks created")
		

		# Create copyright text file and exercise export
		self.data['copyrightcollection'] = self.data['copyrightcollection'] + "\\begin{tabular}{llll}%\n" + self.copyrightcollection + "\\end{tabular}\n"
		self.sys.writeTextFile(self.options.copyrightFile, "% autogenerated by the tex2x VEUNDMINT plugin\n% do not modify\n" + self.data['copyrightcollection'], self.options.stdencoding)
		self.data['directexercises'] = self.data['directexercises'] + self.directexercises
		self.sys.writeTextFile(self.options.directexercisesFile, "% autogenerated by the tex2x VEUNDMINT plugin\n% do not modify\n" + self.data['directexercises'], self.options.stdencoding)

		# create macro and style files used for pdflatex and ttm processing
		self.sys.pushdir()
		os.chdir(self.options.sourceTEX)
		self._installPackages()
		self.sys.popdir()
		
		# Create main file for HTML build, oh great line separator for python is the backslash
		# \author and \title MUST NOT appear in the tex source, they generate h1 and h3 tags through ttm which confuse xml dissection
		maintex = "% this file was autogenerated by tex2x VEUNDMINT preprocessor, do not modify!\n" \
				 + "\\documentclass{book}\n" \
				 + "\\input{" + self.options.macrofile + "} % variant " + self.variant + "\n" \
				 + "\\newcounter{MChaptersGiven}\\setcounter{MChaptersGiven}{1}\n" \
				 + "\\begin{document}\n" \
				 + "\\begin{html}<!-- variant;\\end{html}\\MVariant\\begin{html} //-->\\end{html}\n" \
				 + self.sys.readTextFile(self.options.sourceTEXStartFile, self.options.stdencoding) + "\n" \
				 + "\\end{document}\n"
		self.sys.writeTextFile(self.options.sourceTEXStartFile, maintex, self.options.stdencoding)
		self.sys.message(self.sys.VERBOSEINFO, "Generated main tex file for HTML conversion: " + self.options.sourceTEXStartFile)
		
		self.sys.timestamp("Finished preprocessor " + self.name)
				

	# Checks if given tex code from file fname (original source!) is valid for a release version
	# Return value: boolean True if release check passed
	def checkRelease(self, tex, orgname):
		reply = True
		
		# check desired tex file properties
		p = subprocess.Popen(["file", orgname], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
		(output, err) = p.communicate()

		fm = re.match(re.escape(orgname) + ": (LaTeX|TeX) document,(.*)", output, re.S)
		if fm:
			if "with very long lines" in fm.group(2):
				self.sys.message(self.sys.VERBOSEINFO, "tex file has very long lines, but ok for now")
			if "with CRLF line terminators" in fm.group(2):
				self.sys.message(self.sys.VERBOSEINFO, "tex file has windows-like CRLF line terminators, but ok for now")
		else:
			# does not prevent release, but should be mentioned, happens for example if texfile consists of input commands only
			self.sys.message(self.sys.VERBOSEINFO, "File " + orgname + " is not recognized as a TeX file by file command")
	
		# no Mtikzexternalize in a comment
		if re.search(r"\%([ \t]*)\\Mtikzexternalize", tex, re.S):
				self.sys.message(self.sys.CLIENTWARN, "Mtikzexternalize found in a comment")
				reply = False
	
		# no experimental environments
		if (re.search(r"\\begin\{MExperimental\}", tex, re.S)):
			self.sys.message(self.sys.VERBOSEINFO, "MExperimental found in tex file");
			reply = False
		if (re.search(r"\% TODO", tex, re.S)):
			self.sys.message(self.sys.VERBOSEINFO, "TODO comment found in tex file");
			reply = False
			
		# MSContent is no longer valid
		def scontent(m):
			nonlocal reply
			reply = False
			self.sys.message(self.sys.VERBOSEINFO, "MSContent found but no longer supported: " + m.group(1))
		re.sub(r"\\begin\{MSContent\}\{([^\}]*)\}\{([^\}]*)\}\{([^\}]*)\}(.*?)\\end\{MSContent\}", scontent, tex, 0, re.S)

		# each MXContent must have a unique content id
		def xcontent(m):
			nonlocal reply
			xm = re.search(r"\\MDeclareSiteUXID\{([^\}]*)\}", m.group(4), re.S)
			if not xm:
				reply = False
				self.sys.message(self.sys.VERBOSEINFO, "MXContent found without unique id declaration: " + m.group(1))
		re.sub(r"\\begin\{MXContent\}\{([^\}]*)\}\{([^\}]*)\}\{([^\}]*)\}(.*?)\\end\{MXContent\}", xcontent, tex, 0, re.S)
		
		return reply


	# Preprocess a tex file (given name and content as unicode strings)
	# Return value: processed tex (may be unchanged)
	def preprocess_texfile(self, name, tex):
		# variables used only for one specific tex file
		self.local = dict()
		self.local['htmltikzscale'] = self.options.htmltikzscale # may be overwritten by pragmas
		self.local['tex'] = tex
		# Exclude special files from preprocessing
		if re.match(".*" + self.options.module, name): #  . from file expansion is read as any letter due to regex rules, but it's ok
			self.sys.message(self.sys.VERBOSEINFO, "Preprocessing ignores module main file " + name)
			return tex
		for p in self.options.generate_pdf:
			if re.match(".*" + p + "\\.tex", name):
				self.sys.message(self.sys.VERBOSEINFO, "Preprocessing ignores pdf main file " + name)
				return tex
		if re.search(r"\\IncludeModule\{.+\}", self.local['tex'], re.S):
			self.sys.message(self.sys.VERBOSEINFO, "Preprocessing ignores module-including file " + name)
			return tex
			
		self.sys.message(self.sys.VERBOSEINFO, "Preprocessing tex file " + name)
		m = re.search(r"\\MSection\{(.+?)\}", self.local['tex'], re.S)
		if m:
			self.local['modulename'] = m.group(1)
			self.sys.message(self.sys.VERBOSEINFO, "It is a course module: " + self.local['modulename'])
		else:
			self.local['modulename'] = ""
			self.sys.message(self.sys.VERBOSEINFO, "Unspecific tex file content: " + name)
			
		m = re.match(r"(.*)/(.*?.tex)", name)
		if m:
			self.local['pdirname'] = m.group(1)
			self.local['pfilename'] = m.group(2)
			pm = re.search(re.escape(self.options.sourceTEX) + r"/(.+)/" + re.escape(self.local['pdirname']), name)
			if pm:
				self.local['moddirprefix'] = m.group(1)
				self.sys.message(self.sys.VERBOSEINFO, "Preprocessing file " + self.local['pfilename'] + " in prefix directory " + self.local['moddirprefix'])
			else:
				self.local['moddirprefix'] = "."
				self.sys.message(self.sys.VERBOSEINFO, "Preprocessing file " + self.local['pfilename'] + " in absolute directory " + self.local['pdirname'])
				
		else:
			self.local['pdirname'] = ""
			self.local['pfilename'] = name
			self.sys.message(self.sys.CLIENTWARN, "texfile " + name + " does not have a directory")
	  
			
		# application of preliminary changes to the tex code
		self.preprocess_roulette()
		self.preprocess_comments()
		self.preprocess_directhtml()
		self.preprocess_copyrights()
		self.preprocess_pragmas()
		if self.local['modulename'] != "":
			self.preprocess_includify()
			
		# tex changes to compensate ttm problems
		self.preprocess_ttmcompability()
		
		# course wide label management
		self.preprocess_labels()

		# tikz preparation has to come last, as TikZ formulas contain arbitrary tex code which should be preprocessed and may depend on executed pragmas
		self.preprocess_tikz()
			
		return self.local['tex']

	
	# preprocessing of roulette include statements
	def preprocess_roulette(self):			 
		# First, include roulette exercise files in the code
		self.sys.timestamp("Starting roulette preprocessing")
		rx = re.compile(r"\\MDirectRouletteExercises\{(.+?)\}\{(.+?)\}", re.S)
		roul = rx.findall(self.local['tex'])
		if (len(roul) > 0):
			self.sys.message(self.sys.VERBOSEINFO, "Found " + str(len(roul)) + " MDirectRoueletteExercises")

		for m in roul:
			rfilename = m[0]
			self.sys.message(self.sys.VERBOSEINFO, "Roulette exercises taken from " + rfilename)
			rid = m[1]
			rfile = os.path.join(self.local['pdirname'], rfilename)
			
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

			rtext = r"\ifttm\special{html:<!-- directroulette-start;" + rid + r"; //-->}" + htex + r"\special{html:<!-- directroulette-stop;" + rid + r"; //-->}\else\texttt{" + self.options.strings['roulette_text'] + r"}\fi" + "\n"
			
			self.local['tex'] = self.local['tex'].replace(r"\MDirectRouletteExercises{" + rfilename + r"}{" +rid + r"}", rtext, 1) 
			
			if rid in self.data['DirectRoulettes']:
				self.sys.message(self.sys.CLIENTERROR, "Roulette id " + rid + " is not unique")
			else:
				self.data['DirectRoulettes'][rid] = idd
				
			self.sys.message(self.sys.VERBOSEINFO, "Roulette " + rid + " contains " + str(idd) + " exercises") 


		self.sys.timestamp("Finished roulette preprocessing")
		return


	# preprocessing of LaTeX comments (and verb constructs which may contain % in self.local['tex']t or as a delimiter)
	def preprocess_comments(self):
		# find single characters used with \verb
		rx = re.compile(r"\\verb(.)", re.S)
		verbac = rx.findall(self.local['tex'])
		
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
				self.local['tex'] = re.sub(r"\\verb\%([^\%]*?)\%", r"\\verb\\PERCTAG\1\\PERCTAG", self.local['tex'], count = 0, flags = re.S)
			else:
				# escape % as a comment truncator insinde the verb string, now it's sure the delimiter is not %
				# but we have to escape c because it may be a regex symbol or a backlash
				found = True
				n = 0
				while found:
					(self.local['tex'], k) = re.subn(r"\\verb" + re.escape(c) + r"([^" + re.escape(c) + r"]*?)%([^" + re.escape(c) + r"]*?)" + re.escape(c),
													 r"\\verb" + c + r"\1\\PERCTAG\2" + c,
													 self.local['tex'], count = 0, flags = re.S)
					if k == 0:
						found = False
				
				
		# remove CONTENT(!) of comment lines, take care not to remove \%, replace \PERCTAG by % afterwards
		self.local['tex'] = re.sub(r"(?<!\\)\%([^\n]+?)\n", "%\n", self.local['tex'], count = 0, flags = re.S)
		self.local['tex'] = self.local['tex'].replace(r"\PERCTAG", r"%") # re-escape %

		return
				

	def preprocess_directhtml(self):
	  # prepare exercises for export if requested
	  if (self.options.qautoexport == 1):
		  self.local['tex'] = re.sub(r"\\begin\{MExercise\}(.+?)\\end\{MExercise\}", r"\\begin{MExportExercise}\1\end{MExportExercise}", self.local['tex'], 0, re.S)

	  m = re.search(r"\\MSection{(.+?)}", self.local['tex'], re.S)
	  if m:
		  self.directexercises = self.directexercises + "\\MSubsubsectionx{" + m.group(1) + "}\n"


	  # exercise environments marked for export (either by qautoexport or by the module author) are translated to DirectHTML before any preprocessing happens
	  qex = 0
	  def fexport(part):
		  nonlocal qex
		  self.directexercises = self.directexercises + "\\ \\\\\n\\begin{MExercise}\n" + part.group(1) + "\n\\end{MExercise}\n"
		  s = "\\begin{MExercise}" + part.group(1) + "\\end{MExercise}\n\\begin{MDirectHTML}\n<!-- qexportstart;" + str(qex) + "; //-->" + part.group(1) + "<!-- qexportend;" + str(qex) + "; //-->\n\\end{MDirectHTML}"
		  qex = qex + 1
		  return s
	  self.local['tex'] = re.sub(r"\\begin\{MExportExercise\}(.+?)\\end\{MExportExercise\}", fexport, self.local['tex'], 0, re.S) 

	  # MDirectMath processing (as DirectHTML)
	  def dmath(part):
		  self.data['DirectHTML'].append("\\[" + part.group(1) + "\\]")
		  self.sys.message(self.sys.CLIENTWARN, "DirectMath does not behave well with MathJax 2.6 rendering, TeXCode will be displayed in raw HTML")
		  return "\\ifttm\\special{html:<!-- directhtml;;" + str(len(self.data['DirectHTML']) - 1) + "; //-->}\\fi"
	  self.local['tex'] = re.sub(r"\\begin\{MDirectMath\}(.+?)\\end\{MDirectMath}", dmath, self.local['tex'], 0, re.S)
	  
	  
	  # MDirectHTML processing
	  def dhtml(part):
		  self.data['DirectHTML'].append(part.group(1))
		  return "\\ifttm\\special{html:<!-- directhtml;;" + str(len(self.data['DirectHTML']) - 1) + "; //-->}\\fi"
	  self.local['tex'] = re.sub(r"\\begin\{MDirectHTML\}(.+?)\\end\{MDirectHTML}", dhtml, self.local['tex'], 0, re.S)

	  return


	def preprocess_copyrights(self):
	# copyright processing, exports, tikz-generation and DirectHTML processing must happen before this one

		# attach standard MINT authorship and CC license to each auto tikz image
		if self.options.autotikzcopyright == 1:
			def ctikz(part):
				label = self._autolabel()
				return "\MCopyrightLabel{" + label + "}\\MCopyrightNotice{\\MCCLicense}{TIKZ}{MINT}{TikZ-Quelltext in der Datei " + self.local['pfilename'] + "}{" + label + "}\\MTikzAuto{"
				
			(self.local['tex'], n) = re.subn(r"\\MTikzAuto\{", ctikz, self.local['tex'], 0, re.S)
			if (n > 0):
				self.sys.message(self.sys.VERBOSEINFO, "Forcibly attached CC licenses to " + str(n) + " tikz pictures in this files")
		if self.options.displaycopyrightlinks != 1:
			# force silent copyright links
			self.local['tex'] = self.local['tex'].replace("\\MCopyrightLabel{", "\\MSilentCopyrightLabel{")
	
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
				self.copyrightcollection = self.copyrightcollection + "\\MCRef{" + part.group(5) + "} & " + part.group(1) + " & " + authortext +" & Ersterstellung & " + part.group(4) + " \\\\ \\ \\\\\n"
			
			elif "_eng.tex" not in part.group(4):
			#Do this only for German texts, otherwise they image licenses are listed twice.
				if part.group(2) == "TIKZ":
					self.copyrightcollection = self.copyrightcollection + "\\MCRef{" + part.group(5) + "} & " + part.group(1) + " & " + authortext + " & Grafikdatei erzeugt aus tikz-Code & " + part.group(4) + " \\\\ \\ \\\\\n"
				else:
					if part.group(2) == "FSZ":
						self.copyrightcollection = self.copyrightcollection + "\\MCRef{" + part.group(5) + "} & " + part.group(1) + " & " + authortext + " & Aufgenommen im \\MExtLink{http://www.fsz.kit.edu}{Fernstudienzentrum} des \\MExtLink{http://www.kit.edu}{KIT} & " + part.group(4) + " \\\\ \\ \\\\\n"
					else:
						self.copyrightcollection = self.copyrightcollection + "\\MCRef{" + part.group(5) + "} & " + part.group(1) + " & " + authortext + " & \\MExtLink{" + part.group(2) + "}{Originaldatei} & " + part.group(4) + " \\\\ \\ \\\\\n"

			
			return "\\MCopyrightNoticePOST{" + part.group(1) + "}{" + part.group(2) + "}{" + part.group(3) + "}{" + part.group(4) + "}{" + part.group(5) + "}"
	
		self.local['tex'] = re.sub(r"\\MCopyrightNotice\{(.+?)\}\{(.+?)\}\{(.+?)\}\{(.+?)\}\{(.+?)\}", cright, self.local['tex'], 0, re.S)

		return
	
	
	def preprocess_tikz(self):
		# check if tikz-externalization is actually requested and if the self.local['tex'] supports it
		dotikzfile = False
		if re.search(r"\\tikzexternalize", self.local['tex'], re.S):
			self.sys.message(self.sys.CLIENTWARN, "texfile contains \\tikzexternalize, which should be changed to \\Mtikzexternalize")
		if re.search(r"\\tikzsetexternalprefix", self.local['tex'], re.S):
			self.sys.message(self.sys.CLIENTWARN, "texfile contains \\tikzsetexternalprefix which interferes with tikz automatization")
		(self.local['tex'], n) = re.subn(r"\\Mtikzexternalize", r"", self.local['tex'], 0, re.S)
		if n > 0:
			if (self.options.dotikz == 0):
				self.sys.message(self.sys.VERBOSEINFO, "Mtikzexternalize ignored, present externalized files will be used")
			else:
				self.sys.message(self.sys.VERBOSEINFO, "Mtikzexternalize activated, externalized files will be generated")
				dotikzfile = True
		else:
			if re.search(r"\\MTikzAuto", self.local['tex'], re.S):
				self.sys.message(self.sys.CLIENTWARN, "texfile contains MTikzAuto environments, but not \\Mtikzexternalize (perhaps in comments?)")

				

		# switch to local self.local['tex'] directory, externalize if requested, and convert image formats			
		self.sys.pushdir()
		os.chdir(self.local['pdirname'])

		# call pdflatex to externalize tikz pictures if requested, but some preparations are needed
		if dotikzfile:
			self.sys.timestamp("Calling pdflatx in directory " + self.local['pdirname'] + " to create externalized images")
			self._installPackages()
				
			p = subprocess.Popen(["pdflatex", "-halt-on-error", "-interaction=errorstopmode", "-shell-escape", self.local['pfilename']], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
			(output, err) = p.communicate()
			
			if p.returncode < 0:
				self.sys.message(self.sys.FATALERROR, "Call to pdflatex for file " + self.local['pfilename'] + " during tikz externatlization was terminated by a signal (POSIX return code " + p.returncode + ")")
			else:
				if p.returncode > 0:
					self.sys.message(self.sys.CLIENTERROR, "pdflatex could not process file " + self.local['pfilename'] + ", pdflatex error lines have been written to logfile")
					s = output[-256:]
					s = s.replace("\n",", ")
					self.sys.message(self.sys.VERBOSEINFO, "Last pdflatex lines: " + s)
				else:
					self.sys.timestamp("pdflatex finished successfully")
			
			self._removePackages()

		# assume pngs have been provided in the original source directory if dotikz was false
		m = re.search(r"\\MSetSectionID{(.+?)}", self.local['tex'], re.S)
		if m:
			# Files tid?.png, tid?.svg anf tid.4x.png should be present (matching generator definition in mintmod.tex)
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
						sizex = int(sizex * self.local['htmltikzscale'])
						sizey = int(sizey * self.local['htmltikzscale'])
						self.sys.message(self.sys.VERBOSEINFO, "  rescaled to " + str(sizex) + "x" + str(sizey))
						if tname in self.data['htmltikz']: 
							self.sys.message(self.sys.CLIENTERROR, "  externalized file name " + tname + " not unique, refusing to save sizes")
						else:
							self.data['htmltikz'][tname] = "width:" + str(sizex) + "px;height:" + str(sizey) + "px"
					else:
						self.sys.message(self.sys.CLIENTERROR, "  externalized png found: " + tname + ".png, but could not determine its size")

				j = j + 1
				
		else:
			self.sys.message(self.sys.VERBOSEINFO, "No section id found")


		self.sys.popdir()
		return
	
	
	def preprocess_pragmas(self):
		# Pragma HTMLTikZScale sets scaling of pngs in the HTML version, higher values mean larger images
		m = re.search(r"\\MPragma\{HTMLTikZScale;(.+?)\}", self.local['tex'], re.S)
		if m:
			f = float(m.group(1))
			self.local['htmltikzscale'] = f
			self.sys.message(self.sys.CLIENTINFO, "Pragma HTMLTikZScale: HTMLTikZ scaling factor set from " + str(self.options.htmltikzscale) + " to " + str(f) + " for this tex file only")

		m = re.search(r"\\MPragma\{SolutionSelect\}", self.local['tex'], re.S)
		if m:
			if self.options.nosols == 0:
				self.sys.message(self.sys.CLIENTINFO, "Pragma SolutionSelect: Ignored because option nosols is not activated");
			else:
				self.sys.message(self.sys.CLIENTINFO, "Pragma SolutionSelect: solution and solution-hint environments will be removed")
				(self.local['tex'], n) = re.subn(r"\\begin\{MSolution\}.+?\\end\{MSolution\}", r"\\relax", self.local['tex'], 0, re.S)
				if n > 0: self.sys.message(self.sys.CLIENTINFO, "Pragma SolutionSelect: " + str(n) + " solution environments removed")
				for mhint in [ "Lösung", "L\"osung", "L\\\"osung" ]:
					(self.local['tex'], n) = re.subn(r"\\begin\{MHint\}{" + mhint + r"}.+?\\end\{MHint\}", r"\\relax", self.local['tex'], 0, re.S)
					if n > 0: self.sys.message(self.sys.CLIENTINFO, "Pragma SolutionSelect: " + str(n) + " MHints (" + mhint + ") removed")
				
		m = re.search(r"\\MPragma\{MathSkip\}", self.local['tex'], re.S)
		if m:
			self.sys.message(self.sys.VERBOSEINFO, "Pragma MathSkip: Skips starting math-environments inserted")
			self.local['tex'] = re.sub(r"(?<!\\)\\\[", "\\MSkip\\\[", self.local['tex'], 0)
			self.local['tex'] = re.sub(r"(?<!\\)\$\$", "\\MSkip$$", self.local['tex'], 0)
			for menv in ["eqnarray", "equation", "align"]:
				self.local['tex'] = re.sub(r"(?<!\\)\\begin\{" + menv, r"\\MSkip\\begin{" + menv, self.local['tex'], 0)
		else:
			self.sys.message(self.sys.VERBOSEINFO, "Pragma MathSkip not active in this file")

		# Pragma Substitution: first collect substitution rules then perform them
		sublist = []
		def sbst(part):
			self.sys.message(self.sys.CLIENTINFO, "Pragma Substitution activated: " + part.group(1) + " --> " + part.group(2))
			sublist.append([ part.group(1), part.group(2) ])
			return "\\MPragma{Nothing}"
		self.local['tex'] = re.sub(r"\\MPragma\{Substitution;(.+?);(.+?)\}", sbst, self.local['tex'], 0)
		for k in sublist:
			self.local['tex'] = re.sub(re.escape(k[0]), k[1], self.local['tex'], 0, re.S)
			
		(self.local['tex'], n) = re.subn(r"\\MPreambleInclude\{(.*)\}", "\\MPragma{Nothing}", self.local['tex'], 0, re.S)
		if n > 0: self.sys.message(self.sys.CLIENTERROR, "Inclusion of local preamble is no longer supported, please add them to " + self.options.macrofile + " manually")

		return
 
 
	def preprocess_includify(self):
		# transform document from local compilable module to include of main file
		for tag in [ "\\begin{document}", "\\end{document}", "\\input{" + self.options.macrofile + "}", "\\input{" + self.options.macrofilename + "}", "\\printindex", "\\MPrintIndex"]:
			self.local['tex'] = self.local['tex'].replace(tag, "")
		
		# rewrite input statements to match local directory (master document is on a higher level)
		(self.local['tex'], n) = re.subn(r"\\input\{(.+?)\}", "\\input{" + self.local['moddirprefix'] + "/\1}", self.local['tex'], 0, re.S)
		if n > 0: self.sys.message(self.sys.CLIENTWARN, "Module " + self.local['modulename'] + " uses local input files")

		return
	
	
	def preprocess_ttmcompability(self):
		# modify tex constructs that are not translated correctly by the original ttm converter,
		# but preserve the original version of pdf version

		# turn 1d-pmatrix expressions into arrays in HTML version
		(self.local['tex'], n) = re.subn(r"\\begin\{pmatrix\}([^&]*?)\\end\{pmatrix\}",
										 "\\ifttm\\left({\\begin{array}{c}\1\\end{array}}\\right)\\else\\begin{pmatrix}\1\\end{pmatrix}\\fi",
										 self.local['tex'], 0, re.S)
		if n > 0: self.sys.message(self.sys.VERBOSEINFO, str(n) + " pmatrix-environments of dimension 1 substituted")

		# ignore flushleft in HTML version
		(self.local['tex'], n) = re.subn(r"\\begin\{flushleft\}(.*?)\\end\{flushleft\}",
								   "\\ifttm{\1}\\else\\begin{flushleft}\1\\end{flushleft}\\fi",
								   self.local['tex'], 0, re.S)
		if n > 0: self.sys.message(self.sys.VERBOSEINFO, str(n) + " flushleft-environments removed (no counterpart in html available right now)")
	
		# replace hdots, vdots and relax by macro versions as ttm does not understand them
		(self.local['tex'], n) = re.subn(r"\\hdots", "\\MHDots", self.local['tex'], 0, re.S)
		if n > 0: self.sys.message(self.sys.VERBOSEINFO, str(n) + " \\hdots modified")
		(self.local['tex'], n) = re.subn(r"\\vdots", "\\MVDots", self.local['tex'], 0, re.S)
		if n > 0: self.sys.message(self.sys.VERBOSEINFO, str(n) + " \\vdots modified")
		(self.local['tex'], n) = re.subn(r"\\relax", "\\MRelax", self.local['tex'], 0, re.S)
		if n > 0: self.sys.message(self.sys.VERBOSEINFO, str(n) + " \\relax modified")
		
		if re.search(r"\\begin\{pmatrix\}", self.local['tex'], re.S):
			self.sys.message(self.sys.CLIENTWARN, "Multidimensional pmatrix-environments found, cannot be processed by original ttm")
	
	
		# exclude newpage and related statements entirely from html version
		for exc in ["newpage", "pagebreak", "clearpage", "allowbreak"]:
			(self.local['tex'], n) = re.subn(r"\\" + exc, "\\\\ifttm\\else\\\\" + exc + "\\\\fi", self.local['tex'], 0, re.S)
			if n > 0: self.sys.message(self.sys.VERBOSEINFO, str(n) + " \\" + exc + " removed from HTML version")
			# For some unknown reason it has to be \\\\fi in this target regex, while in other ones in this module \\fi suffices ?
			
		# remove ligature commands from html version
		(self.local['tex'], n) = re.subn(r"\\/", "\\ifttm\\else\\/\\fi\%\n", self.local['tex'], 0, re.S)
		if n > 0: self.sys.message(self.sys.VERBOSEINFO, str(n) + " ligatures excluded")

		# remove umlauts from MHint button texts as ttm does not process them correctly
		def hbutton(part):
			return "\\begin{MHint}{" + self.sys.umlauts_tex(part.group(1)) + "}"
		(self.local['tex'], n) = re.subn(r"\\begin\{MHint\}\{(.+?)\}", hbutton, self.local['tex'], 0, re.S)
		if n > 0: self.sys.message(self.sys.VERBOSEINFO, str(n) + " MHint button umlauts substituted")
		
		# ttm does not translate $\displaystyle ...$ correctly, on the other hand pdflatex does not want \special in math environment
		(self.local['tex'], n) = re.subn(r"\\displaystyle", "\\displaystyle\\ifttm\\special{html:<mstyle displaystyle=\"true\">}\\\\fi", self.local['tex'], 0, re.S)
		# For some unknown reason it has to be \\\\fi in this target regex, while in other ones in this module \\fi suffices ?
		if n > 0: self.sys.message(self.sys.VERBOSEINFO, str(n) + " displaystyles prepared for ttm")

		# proof-environments need a parameter in ttm which must be placed in {...}
		self.local['tex'] = re.sub(r"\\begin\{proof\}(?!\[)", "\\begin{proof}[Beweis]", self.local['tex'], 0, re.S)
		self.local['tex'] = re.sub(r"\\begin\{proof\}\[(.+?)\]", "\\begin{MProof}{\1}", self.local['tex'], 0, re.S)
		self.local['tex'] = re.sub(r"\\end\{proof\}", "\\end{MProof}", self.local['tex'], 0, re.S)


		# change \text-statements so that spaces around it are processed correctly by ttm

		# implement makeshift brace parser using prefix prf since they cannot be parsed by regular expressions
		prf = self.sys.generate_autotag(self.local['tex'])
		tcl = prf + "L"
		tcr = prf + "R"
		a = self.local['tex'].find("\\text{") # somehow python does not support do loops :/
		while(a != -1):
			a = a + 5
			b = a
			c = 1
			while (c > 0):
				b = b + 1
				if (self.local['tex'][b] == "}"): c = c - 1
				if (self.local['tex'][b] == "{"): c = c + 1
			self.local['tex'] = self.local['tex'][0:b] + tcr +  self.local['tex'][b+1:]
			self.local['tex'] = self.local['tex'][0:a] + tcl +  self.local['tex'][a+1:]
			a = self.local['tex'].find("\\text{")
		
		# remove spaces generated by \_space_ first
		self.local['tex'] = re.sub(r"\\text" + tcl + r"\\?\s", "\\;\\\\text{", self.local['tex'], 0, re.S)
		self.local['tex'] = re.sub(r"\\?\s" + tcr, "}\\;", self.local['tex'], 0, re.S)

		# restore substituted braces (from \text commands not having spaces around them)
		self.local['tex'] = self.local['tex'].replace(tcl, "{")
		self.local['tex'] = self.local['tex'].replace(tcr, "}")
		
		# check features not reproduced from old converter version yet
		for f in ["MSContent", "align", "align*", "alignat", "alignat*", "MEvalMathDisplay"]:
			if re.search(r"\\begin\{" + re.escape(f) + "\}", self.local['tex'], re.S):
				self.sys.message(self.sys.CLIENTWARN, "LaTeX environment " + f + " is not implemented in this converter version")
		for f in ["MTableOfContents", "tableofcontents"]:
			if re.search(r"\\" + re.escape(f), self.local['tex'], re.S):
				self.sys.message(self.sys.CLIENTWARN, "LaTeX command " + f + " is not implemented in this converter version")
		
		return


	def preprocess_labels(self):
		# check MLabel functionality and move labels to appropriate positions
		for tag in ['label', 'ref', 'eref']:
			if ("\\" + tag) in  self.local['tex']:
				self.sys.message(self.sys.CLIENTERROR, "Use of LaTeX command \\" + tag + " with the VEUNDMINT package will break label management, please use commands from the macro package " + self.options.macrofile + " instead")

		# check duplicate constructs
		m = re.search(r"\\MLabel\{([^\}]*)\}[\s%]*\\MLabel\{([^\}]*)\}", self.local['tex'], re.S)
		if m:
			self.sys.message(self.sys.CLIENTERROR, "Different labels " + m.group(1) + " and " + m.group(2) + " are attached to the same object, which breaks label management")

		# set label type after equation starts
		eqprefix = "\\setcounter{MLastType}{10}\\\\addtocounter{MLastTypeEq}{1}\\\\addtocounter{MEquationCounter}{1}\\setcounter{MLastIndex}{\\\\value{MEquationCounter}}\n"
		eqpostfix = "\\\\addtocounter{MLastTypeEq}{-1}\n"
		for env in ["eqnarray", "equation"]:
			self.local['tex'] = re.sub(r"\\begin\{" + env + "\}", eqprefix + "\\\\begin{" + env + "}", self.local['tex'], 0, re.S)
			self.local['tex'] = re.sub(r"\\end\{" + env + "\}", "\\end{" + env + "}\n" + eqpostfix, self.local['tex'], 0, re.S)
		
	
		# set label type after table starts
		tableprefix = "\\setcounter{MLastType}{9}\\\\addtocounter{MLastTypeEq}{2}\\\\addtocounter{MTableCounter}{1}\\setcounter{MLastIndex}{\\\\value{MTableCounter}}\n"
		tablepostfix = "\\addtocounter{MLastTypeEq}{-2}\n"
		self.local['tex'] = re.sub(r"\\begin\{table\}" , tableprefix + "\\\\begin{table}", self.local['tex'], 0, re.S)
		self.local['tex'] = re.sub(r"\\end\{table\}", "\\end{table}\n" + tablepostfix, self.local['tex'], 0, re.S)

		# MLabels in equation/eqnarray umsetzen, so dass sie vor dem Environment (in dem alles als Mathe geparset wird) stehen
		#	 while ($textex =~ s/\\begin{equation}(.*?)([\n ]*)\\MLabel{(.+?)}([\n ]*)(.*?)\\end{equation}/\\MLabel{$3}\n\\begin{equation}$1 $5\\end{equation}/s ) {;} 
		#	 while ($textex =~ s/\\begin{eqnarray}(.*?)([\n ]*)\\MLabel{(.+?)}([\n ]*)(.*?)\\end{eqnarray}/\\MLabel{$3}\n\\begin{eqnarray}$1 $5\\end{eqnarray}/s ) {;} 
		
			
		return

   
	def _installPackages(self):
		# installs modified local macro package and used style files in the current directory
		# don't use a direct copy, always check and modify the encoding if needed
		self.sys.writeTextFile(self.options.macrofile, self.data['modmacrotex'], self.options.stdencoding)
		for f in self.options.texstylefiles:
			self.sys.writeTextFile(f, self.sys.readTextFile(os.path.join(self.options.converterDir, "tex", f), self.options.stdencoding), self.options.stdencoding)
		return


	def _removePackages(self):
		# removeslocal macro package and style files in the current directory
		for f in self.options.texstylefiles:
			self.sys.removeFile(f)
		self.sys.removeFile(self.options.macrofile)

 
	def _addTeXMacro(self, macro, tex):
		self.data['modmacrotex'] += "\\newcommand{\\" + macro + "}{" + tex + "}\n"
		