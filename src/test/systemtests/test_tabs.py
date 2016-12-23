'''
Created on Jun 15, 2016

cd src
python3 -m unittest test.systemtests.test_tabs.TabsTest

@author: alvaro
'''
import unittest
from test.systemtests.SeleniumTest import SeleniumTest
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.by import By

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

		# there should be no previous chapter link on the first chapter
		elements = self.driver.find_elements(By.ID, 'prev-chapter')
		self.assertTrue(len(elements) == 0)

		next = self.getElement('next-chapter')
		next.click()
		self.assertTrue( "1.1.2" in self.getElement('pageTitle').text )

		# previous
		prev = self.getElement('prev-chapter')
		elements = self.driver.find_elements(By.ID, 'prev-chapter')
		prev.click()
		self.assertTrue( "1.1.1" in self.getElement('pageTitle').text )
