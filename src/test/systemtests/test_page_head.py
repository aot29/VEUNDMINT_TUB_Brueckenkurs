'''
Created on Jun 14, 2016

Unittest: are navigational elements present?
1. open the "module overview" page,
2. check that expected nav elements are present, links and texts are correct

@author: alvaro
'''
import unittest
from selenium.webdriver.common.action_chains import ActionChains
from test.systemtests.SeleniumTest import SeleniumTest

class PageHeadTest( SeleniumTest ):

	def setUp(self):
		SeleniumTest.setUp( self )
		# open a page to test it
		self._chooseLanguageVersion("de")

	#@unittest.skip("needs more attention")
	def testHeadButtonsComplete(self):
		'''
		Test head of the page and buttons
		'''
		# Find the head section of the page
		head = self.getElement( "navbarTop" )
		self.assertTrue( head, "Page head is missing" )

		# Test nav buttons

		self.assertTrue( self.getElement( "loginButtonNavBar" ) )
		self.assertTrue( self.getElement( "listebutton" ) )
		self.assertTrue( self.getElement( "homebutton" ) )
		self.assertTrue( self.getElement( "databutton" ) )
		





if __name__ == "__main__":
	#import sys;sys.argv = ['', 'Test.testName']
	unittest.main()
