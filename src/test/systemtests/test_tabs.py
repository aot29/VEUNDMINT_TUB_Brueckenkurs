'''
Created on Jun 15, 2016

@author: alvaro
'''
import unittest
from test.systemtests.SeleniumTest import SeleniumTest

class TabsTest( SeleniumTest ):		
	'''
	Test chapter 1
	'''
	def setUp( self ):
		SeleniumTest.setUp(self)
		
	
	def testNavToNextAndPrevTab(self):
		'''
		Open first chapter introduction and navigate using tabs
		'''
		self._navToChapter("1", "1.1")
		self.assertTrue( "1.1.1" in self.getElement('pageTitle').text )
		
		# next
		next = self.getElement('navNext')
		next.click()
		self.assertTrue( "1.1.2" in self.getElement('pageTitle').text )
		
		# previous
		prev = self.getElement('navPrev')
		prev.click()
		self.assertTrue( "1.1.1" in self.getElement('pageTitle').text )

