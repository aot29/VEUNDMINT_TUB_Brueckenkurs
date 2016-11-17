'''
Created on Nov 16, 2016

Run with:
> cd src
> python3 -m unittest test.unittests.test_Dispatcher.test_Dispatcher

@author: ortiz
'''
import unittest
from tex2x.dispatcher.Dispatcher import Dispatcher

class test_Dispatcher(unittest.TestCase):
	
	def testCreate(self):
		'''
		Check if a Dispatcher can be created at all
		'''
		dispatcher = Dispatcher(True, "VEUNDMINT", "")
		self.assertTrue(True)


	def testDispatch(self):
		'''
		Check if a Dispatcher can dispatch at all
		'''
		dispatcher = Dispatcher(True, "VEUNDMINT", "")
		dispatcher.dispatch()
		self.assertTrue(True)

	
if __name__ == '__main__':
	unittest.main()
	