import re
from tex2x.preprocessors.AbstractPreprocessor import AbstractPreprocessor
from tex2x.Settings import ve_settings as settings

class FixI18nForPdfLatex(AbstractPreprocessor):
	
	def __init__(self, data):
		pass
	
	
	def preprocess( self ):
		# Remove the i18n localization \input commands from LaTeX, as the converter inserts them into the source code, 
		# and the presence of both confuses pdflatex
		pattern = re.compile(r"\\\input{.*}")
		fileList = self.getFileList()
		
		for texfile in fileList:
			#if re.match(".*" + settings.macrofilename  + "\\.tex", texfile[0]): continue
			#if re.match(".*/veundmint_de.tex", texfile[0]): continue
			#if re.match(".*/veundmint_en.tex", texfile[0]): continue
			if re.match(".*/vbkm.*", texfile[0]):
				file_handle = open(texfile[0], 'r')
				file_string = file_handle.read()
				file_handle.close()
				
				# Use RE package to allow for replacement (also allowing for (multiline) REGEX)
				file_string = (re.sub(pattern, "", file_string))
				
				# Write contents to file.
				# Using mode 'w' truncates the file.
				file_handle = open(texfile[0], 'w')
				file_handle.write(file_string)
				file_handle.close()
