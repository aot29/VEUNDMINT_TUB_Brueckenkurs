'''
Created on Nov 9, 2016

Run with:
> cd src
> python3 -m unittest test.unittests.test_OptionTest.test_OptionTest

@author: ortiz
'''
import unittest
from plugins.VEUNDMINT_TUB.Option import Option

class test_OptionTest(unittest.TestCase):
	
	def setUp(self):
		self.currentDir = "."
		'''Path to the "src" dir'''


	def testDescription(self):
		# Defaults
		option = Option( self.currentDir, "" )
		self.assertEqual("Onlinebrückenkurs Mathematik", option.description, "Unexpected default description")
		
		# Override
		option = Option( self.currentDir, ["description=Onlinebrückenkurs Physik","moduleprefix=Onlinebrückenkurs Physik"] )
		self.assertEqual('Onlinebrückenkurs Physik', option.description, "Unexpected description override")
		

	def testLocalization(self):
		# Defaults
		option = Option( self.currentDir, "" )
		self.assertEqual("de", option.lang, "Unexpected default language")
		self.assertTrue(option.locale == "de_DE.UTF-8" or option.locale == "de_DE.utf8", "Unexpected default locale")
		
		# Override
		option = Option( self.currentDir, ["lang=en"] )
		self.assertEqual("en", option.lang, "Unexpected language override")
		self.assertTrue(option.locale == "en_GB.UTF-8" or option.locale == "en_GB.utf8", "Unexpected locale override")


	def testConversionFlags(self):
		# Defaults
		option = Option( self.currentDir, "" )
		self.assertFalse(option.testonly, "Unexpected default for flag 'testonly'")
		
		# Override
		option = Option( self.currentDir, ["testonly=1"] )
		self.assertTrue(option.testonly, "Unexpected override for flag 'testonly'")


	def testTexTree(self):
		# Defaults
		option = Option( self.currentDir, "" )
		self.assertEqual("tree_de.tex", option.module, "Unexpected default tree")
		
		option = Option( self.currentDir, ["lang=en"] )
		self.assertEqual("tree_en.tex", option.module, "Unexpected override for tree")


	def testTest(self):
		# Override
		option = Option( self.currentDir, ["testonly=1"] )
		self.assertEqual("tree_test.tex", option.module, "Unexpected override for tree")

		
	def testSourceOutputDirs(self):
		# Defaults
		option = Option( self.currentDir, "" )
		self.assertEqual("content_submodule/content", option.source, "Unexpected default for 'source'")
		self.assertEqual("build", option.output, "Unexpected default for 'output'")
		
		# Override
		option = Option( self.currentDir, ["output=testoutput"] )
		self.assertEqual("testoutput", option.output, "Unexpected override for 'output'")


	def testSignature(self):
		# Defaults
		option = Option( self.currentDir, "" )
		self.assertEqual("10000", option.signature_version, "Unexpected default for 'signature_version'")
		# Override
		option = Option( self.currentDir, ["signature_version=2000"] )
		self.assertEqual("2000", option.signature_version, "Unexpected override for 'signature_version'")


	def testServer(self):
		# Defaults
		option = Option( self.currentDir, "" )
		server = "https://guest6.mulf.tu-berlin.de/server/dbtest"
		self.assertEqual(server, option.data_server, "Unexpected default for 'data_server'")
		self.assertEqual(server, option.exercise_server, "Unexpected default for 'exercise_server'")
		
		# Override
		option = Option( self.currentDir, ["data_server=test_data_server", "exercise_server=test_exercise_server"] )
		self.assertEqual("test_data_server", option.data_server, "Unexpected default for override 'data_server'")
		self.assertEqual("test_exercise_server", option.exercise_server, "Unexpected default for override 'exercise_server'")


	def testPluginOptions(self):
		# Defaults
		option = Option( self.currentDir, "" )
		self.assertTrue("HTML5_MINTMODTEX" in option.pluginPath, "Missing entry 'HTML5_MINTMODTEX' in pluginPath")
		self.assertTrue("html5_mintmodtex.py" in option.pluginPath["HTML5_MINTMODTEX"], "Unexpected default for 'HTML5_MINTMODTEX' in pluginPath")


if __name__ == '__main__':
	unittest.main()
