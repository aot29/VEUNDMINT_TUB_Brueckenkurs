'''
Created on Nov 16, 2016

Activate Python venv if necessary, then run with:
> cd src
> python3 -m unittest test.unittests.test_Dispatcher.test_Dispatcher

@author: ortiz
'''
import os
import sys
import unittest
from tex2x.dispatcher.Dispatcher import Dispatcher
from tex2x.dispatcher.AbstractDispatcher import VerboseDispatcher
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
	
	
	
if __name__ == '__main__':
	unittest.main()
	