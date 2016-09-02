'''
Created on Jun 15, 2016

Test the TOC navigation area

@author: alvaro
'''
import unittest
from test.systemtests.SeleniumTest import SeleniumTest
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By


class TocTest( SeleniumTest ):
	pageUrl = "sectionx2.1.0.html"


	def setUp(self):
		SeleniumTest.setUp( self )
		# open a page to test it
		self._chooseLanguageVersion("de")
		self._navToChapter("1", no_mathjax=True)


	def testTitlePresent(self):
		'''
		Test the TOC title is present
		'''
		if self.isBootstrap():
			# Find the TOC title section of the page
			el = self.getElement( "tocTitle" )
			self.assertTrue( el, "TOC title is missing" )
			self.assertEqual( self.locale[ "course-title" ].lower(), el.text.lower(), "TOC title is wrong" )


	def testTocPresent(self):
		'''
		Test table of contents of the page
		'''
		# Find the toc section of the page
		toc = self.getElement( "toc" )
		self.assertTrue( toc, "Page toc is missing" )

		# Link to chapter 1-10 should be there
		for n in range(1, 10):
			element = WebDriverWait(self.driver, 30).until(EC.presence_of_element_located((By.PARTIAL_LINK_TEXT, "%s. " % n)))
			self.assertTrue( element, "No link to chapter %s found" % n)
				

	def testLegendPresent(self):
		'''
		Test the TOC legend is present
		'''
		if self.isBootstrap():
			# Find the TOC legend section of the page
			el = self.getElement( "legend" )
			self.assertTrue( el, "Legend is missing" )


if __name__ == "__main__":
	#import sys;sys.argv = ['', 'Test.testName']
	unittest.main()
