"""
Activate Python venv if necessary, then run with:
> cd src
> python3 -m unittest test.conversiontests.test_ttmparser.TTMParserTest
"""
import unittest
import os
import subprocess
from tex2x.parsers.TTMParser import TTMParser
from tex2x.Settings import settings
from tex2x.dispatcher.Dispatcher import Dispatcher
from plugins.VEUNDMINT.Option import Option
from plugins.VEUNDMINT.system import System
import mmap
from unittest.case import skip

class TTMParserTest(unittest.TestCase):

	def setUp(self):
		#print("setting up")
		#self.s = System(Option('',['lang=de']))
		dispatcher = Dispatcher(True, "VEUNDMINT", "" )
		self.options = dispatcher.options
		self.sys = dispatcher.sys
		self.parser = TTMParser( self.options, self.sys )
		self.tex_test_file = os.path.join(settings.BASE_DIR, 'src/test/files/test_ttm_input.tex')
		print('tex_test_file %s', self.tex_test_file)
		self.tex_test_output = os.path.join(settings.BASE_DIR, 'src/test/files/test_ttm_output.html')

	def testTitle(self):
		"""
		Test if the LaTeX \\title command is converted correctly to <title> in html
		"""
		self.isCorrectConversionTest(r'''\title{I am a pretty good tester}''', '<title> I am a pretty good tester </title>')

	def testCenterText(self):
		"""
		Test correct conversion from \\begin{center} to <div style="text-align:center">...
		TODO: the closing div tag </div> should not appear on a newline
		"""
		res = self.isCorrectConversionTest(r'''\begin{center}
Ich stehe in der mitte
\end{center}''', '<div style="text-align:center">Ich stehe in der mitte')

	def testTTMError(self):
		"""
		Test if an error is raised if calling the TTM Process failed (for what reason ever)
		"""
		self.tex_test_file = 'no_existing.file'
		with self.assertRaises(BaseException):
			self.testCenterText()

	def testTTMProcess(self):
		"""
		Test some special cases with the ttm binary
		"""
		ttm_process = self.parser.getParserProcess()
		self.assertIsNone(ttm_process)

		# kick off parser to get a ttm_process
		self.testTitle()
		ttm_process = self.parser.getParserProcess()
		self.assertIsNotNone(ttm_process)

		# parse unknown latex command and make parser exit with code 3
		TTMParser( self.options, self.sys )
		with self.assertRaises(SystemExit) as cm:
			self.isCorrectConversionTest(r'''\unknownlatexcommand''','', dorelease=1)

		self.assertEqual(cm.exception.code, 3)

		# make parser process exit with return code 3
		new_ttm = TTMParser(self.options, self.sys)
		self.testTitle()
		#new_ttm.parse(tex_start=self.tex_test_file, ttm_outfile=self.tex_test_output, sys=self.s)
		#subprocess.run(settings.ttmBin)
		fake_ttm_process = subprocess.Popen("ls", stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, universal_newlines = True)
		fake_ttm_process.wait()
		#out = fake_ttm_process.communicate()
		fake_ttm_process.returncode = 3

		new_ttm._logResults(subprocess=fake_ttm_process, ttmBin=settings.ttmBin, sourceTEXStartFile='test.tex')

	def isCorrectConversionTest(self, latex_string, html_string, dorelease = 0 ):
		"""Checks for correct tex to html conversion

		Writes latex_string to a .tex file, then runs the parser, which will parse it to html, finally
		check if html_string is found in the generated .html file

		Args:
			latex_string: The raw latex string to be converted
			html_string: The html string that should be generated

		Returns:
			bool: True if the conversion was successful, False otherwise
		"""
		# generate a tex file from the latex_string
		with open(self.tex_test_file, "w") as tex_file:
			print(latex_string, file=tex_file)

		# kick off the parser
		self.parser.parse(sourceTEXStartFile=self.tex_test_file, ttmFile=self.tex_test_output, dorelease=dorelease )

		# check for occurence of the html_string in the generated file
		with open(self.tex_test_output, 'rb', 0) as file:
			data = file.read()
			#we have to look for byte strings as mmap will produce byte arrays
			self.assertIn(html_string.encode(), data)
