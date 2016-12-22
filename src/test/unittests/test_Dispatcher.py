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
		pipeline = Pipeline( "VEUNDMINT", {'data': None} )
		
		# there's currently only one preprocessor in the default settings
		self.assertEqual( 1, len( pipeline.preprocessors ) )
		# the class name expected for VEUNDMINT
		self.assertEqual( "preprocessor_mintmodtex", pipeline.preprocessors[0].__class__.__name__ )
		
		# the class name expected for the translator
		self.assertEqual( "TTMTranslator", pipeline.translator.__class__.__name__ )
		
		# the class name expected for the parser
		self.assertEqual( "HTMLParser", pipeline.parser.__class__.__name__ )
	
		# the class name expected for the generator
		self.assertEqual( "ContentGenerator", pipeline.generator.__class__.__name__ )
		
		# there's currently only one plug-in in the default settings
		self.assertEqual( 1, len( pipeline.plugins ) )
		# the class name expected for VEUNDMINT
		self.assertEqual( "html5_mintmodtex", pipeline.plugins[0].__class__.__name__ )

	
if __name__ == '__main__':
	unittest.main()
	