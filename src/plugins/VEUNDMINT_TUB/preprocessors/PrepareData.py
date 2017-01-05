import re
import os.path
import subprocess
import fileinput
import sys
from tex2x.AbstractPreprocessor import AbstractPreprocessor
from tex2x.Settings import ve_settings as settings
from tex2x.System import ve_system as sys

class PrepareData(AbstractPreprocessor):
	
	def __init__(self, data):
		
		# copy interface member references
		self.data = data


	# main function to be called from tex2x
	def preprocess(self):
		"""
		Start preprocessor.
		Called from dispatcher.
		"""		
		self.prepareData()
		self.appendSignatures()
		
		
	def prepareData(self):
		# checks if needed data members are present or empty
		if 'DirectRoulettes' in self.data:
			sys.message(sys.CLIENTWARN, "Another Preprocessor is using DirectRoulettes")
		else:
			self.data['DirectRoulettes'] = {}

		if 'macrotex' in self.data:
			sys.message(sys.CLIENTWARN, "Using macrotex from an another preprocessor, hope it works out")
		else:
			self.data['macrotex'] = self.prepareMacrotex()
			
		if 'modmacrotex' in self.data:
			sys.message(sys.CLIENTWARN, "Using MODIFIED macrotex from an another preprocessor, hope it works out")
		else:
			# use the original code for now
			self.data['modmacrotex'] = self.data['macrotex']

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


	def prepareMacrotex(self):
		# read original code of the macro package
		macrotex = sys.readTextFile( os.path.join(settings.converterDir, "tex", settings.macrofile), settings.stdencoding )

		# read requested i18n file and concatenate macro files if present
		if settings.i18nfile:
			i18ntex = sys.readTextFile( os.path.join(settings.converterDir, "tex", settings.i18nfile), settings.stdencoding )
			macrotex = i18ntex + macrotex
		
		if re.search(r"\\MPragma{mintmodversion;" + self.version + r"}", macrotex, re.S):
			sys.message(sys.VERBOSEINFO, "Macro package " + settings.macrofile + " checked, seems to be ok")
		else:				
			sys.message(sys.CLIENTERROR, "Macro package " + settings.macrofile + " does not provide macroset of preprocessor version")
		
		return macrotex
	

	def appendSignatures(self):
		# append signature values as LaTeX macros
		self._addTeXMacro("MSignatureMain", settings.signature_main)
		self._addTeXMacro("MSignatureVersion", settings.signature_version)
		self._addTeXMacro("MSignatureLocalization", settings.signature_localization)
		self._addTeXMacro("MSignatureVariant", settings.variant)
		self._addTeXMacro("MSignatureDate", settings.signature_date)
		
		
	def _addTeXMacro(self, macro, tex):
		self.data['modmacrotex'] += "\\newcommand{\\" + macro + "}{" + tex + "}\n"

		