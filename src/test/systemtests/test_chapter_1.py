'''
Created on Jun 15, 2016

@author: alvaro
'''
import unittest
from test.systemtests.SeleniumTest import SeleniumTest

class Chapter1Test( SeleniumTest ):
		
	'''
	Test chapter 1
	'''
	def setUp( self ):
		#SeleniumTest.setUp(self)
		self._openStartPage(no_mathjax=True)


	def testChooseLanguageVersion(self):
		self._chooseLanguageVersion("de", no_mathjax=True)
		self.assertIn("/de/", self.driver.current_url)

		self._chooseLanguageVersion("en", no_mathjax=True)
		self.assertIn("/en/", self.driver.current_url)


	def testNavToChapter1(self):
		'''
		Navigate to Chapter 1
		'''
		self._navToChapter("1", no_mathjax=True)

		content = self.getElement( 'pageContents' )
		sections = content.find_elements_by_tag_name( "li" )
		self.assertEqual( 5, len( sections ), "Chapter 1 has the wrong number of sections" )

		#Does the chapter page contain a launch Button?
		self.assertTrue( self.getElement( 'launchButton' ), "No launch button found" )
		buttonText = self.getElement( 'launchButtonTextElement' ).text
		self.assertTrue(  self.locale["module_starttext"] in buttonText, "Wrong text in launch button" )


	def testStartPageContent(self):
		'''
		Does the overview page list the expected number of chapter sections?
		'''
		# count number of sections listed
		self._chooseLanguageVersion( "de", no_mathjax=True )

		content = self.getElement( 'pageContents' )
		sections = content.find_elements_by_tag_name( "li" )
		self.assertEqual( 10, len( sections ), "Chapter 1 has the wrong number of sections" )


	def testChapter1Section2(self):
		'''
		Is the page in the right locale?
		'''

		# Open the *second* subsection (as it's more interesting than the first one)
		self._navToChapter( "1", section="1.2", lang = "de", no_mathjax=True )

		# Check that keywords use the correct locale
		pageText = self.getElement( 'pageContents' ).text.lower()
		#self.assertTrue( self.locale["chapter"].lower() in pageText )
		self.assertTrue( self.locale["subsection_labelprefix"].lower() in pageText )
		self.assertTrue( self.locale["example_labelprefix"].lower() in pageText )
		self.assertTrue( self.locale["exercise_labelprefix"].lower() in pageText )


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
