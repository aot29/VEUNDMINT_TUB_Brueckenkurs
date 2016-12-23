'''
Created on Nov 16, 2016

Activate Python venv if necessary, then run with:
> cd src
> python3 -m unittest test.unittests.test_Dispatcher.test_Dispatcher

@author: Alvaro Ortiz
'''
import os
import sys
import unittest
from tex2x.dispatcher.Dispatcher import *
from tex2x.dispatcher.AbstractDispatcher import VerboseDispatcher
from _operator import length_hint


class test_Dispatcher(unittest.TestCase):
	
	def testCreate(self):
		'''
		Check if a Dispatcher can be created at all
		'''
		dispatcher = Dispatcher(True, "VEUNDMINT", "" )
		self.assertTrue(True)


	def testDispatch(self):
		'''
		Check if a Dispatcher can dispatch at all
		'''
		dispatcher = Dispatcher(True, "VEUNDMINT", "" )
		dispatcher = VerboseDispatcher( dispatcher, "Total duration of conversion" )
		dispatcher.dispatch()
		self.assertTrue(True)
	
	
	def testReadPipeline(self):
		"""
		Check that the pipeline can be read from settings
		"""		
		pipeline = Pipeline()
		
		# there's currently two preprocessors in the default settings
		self.assertEqual( 3, len( pipeline.preprocessors ) )
		# the class name expected for VEUNDMINT
		self.assertEqual( "PrepareData", pipeline.preprocessors[0].__name__ )
		
		# the class name expected for the translator
		self.assertEqual( "TTMTranslator", pipeline.translator.__name__ )
		
		# there's currently only one translator decorator in the default settings
		self.assertEqual( 1, len( pipeline.translatorDecorators ) )
		# the class name expected for the translator decorator
		self.assertEqual( "MathMLDecorator", pipeline.translatorDecorators[0].__name__ )
		
		# the class name expected for the parser
		self.assertEqual( "HTMLParser", pipeline.parser.__name__ )
		# there's currently no parser decorator in the default settings
		self.assertEqual( 0, len( pipeline.parserDecorators ) )
	
		# the class name expected for the generator
		self.assertEqual( "ContentGenerator", pipeline.generator.__name__ )
		
		# there are currently two generator decorators in the default settings
		self.assertEqual( 2, len( pipeline.generatorDecorators ) )
		# the class names expected for the generator decorator
		self.assertEqual( "LinkDecorator", pipeline.generatorDecorators[0].__name__ )
		self.assertEqual( "WikipediaDecorator", pipeline.generatorDecorators[1].__name__ )
		
		# there's currently only one plug-in in the default settings
		self.assertEqual( 1, len( pipeline.plugins ) )
		# the class name expected for VEUNDMINT
		self.assertEqual( "Plugin", pipeline.plugins[0].__name__ )

	
if __name__ == '__main__':
	unittest.main()
	