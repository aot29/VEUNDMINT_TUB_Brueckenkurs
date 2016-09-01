import unittest
import os
from settings import BASE_URL, BASE_DIR
from test.systemtests.SeleniumTest import SeleniumTest
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By

class MySeleniumTest(SeleniumTest):

	def testOpenGoogle(self):
		"""
		Check if anything is working at all
		"""
		#print("configPath %s" % self.configPath)
		self.driver.get( "http://www.google.com" )
		#print( self.driver.page_source  )
		title = self.driver.find_element_by_xpath('//title')
		#print(title.get_attribute('text') )
		self.assertEquals( 'Google', title.get_attribute('text') )


	def testOpenBaseUrl(self):
		"""
		base_URL can be opened
		"""
		self.driver.get( os.getenv('BASE_URL', BASE_URL) )
		#self.driver.get( 'http://localhost:3000/' )
		title = self.driver.find_element_by_xpath('//title')
		self.assertTrue( 'Mathematik' in title.get_attribute('text') )
		

	def testChooseLanguageVersion(self):
		self._chooseLanguageVersion("de")
		self.assertIn("/de/", self.driver.current_url)

		self._chooseLanguageVersion("en")
		self.assertIn("/en/", self.driver.current_url)

	def testNavToChapterOne(self):
		'''
		Navigate to Chapter 1
		'''
		self._navToChapter("1")

		content = self.getElement( "pageContents" )
		sections = content.find_elements_by_tag_name( "li" )
		self.assertEqual( 5, len( sections ), "Chapter 1 has the wrong number of sections" )

		#Does the "launch module" Button on the chapter 1 page contains the right locale?
		self.assertTrue( self.driver.find_element_by_partial_link_text( self.locale["module_starttext"] ) )


	def testStartPageContent(self):
		'''
		Does the overview page list the expected number of chaper sections?
		'''
		# count number of sections listed
		self._chooseLanguageVersion( "de" )

		content = self.getElement( "pageContents" )
		sections = content.find_elements_by_tag_name( "li" )
		self.assertEqual( 10, len( sections ), "Chapter 1 has the wrong number of sections" )


	def testChapter1Section2(self):
		'''
		Is the page in the right locale?
		'''

		self._chooseLanguageVersion("de")

		# Open the *second* subsection (as it's more interesting than the first one)
		self._navToChapter( "1", section="1.2", lang = "de" )

		# Check that keywords use the correct locale
		pageText = self.getElement( "pageContents" ).text.lower()
		self.assertTrue( self.locale["chapter"].lower() in pageText )
		self.assertTrue( self.locale["subsection_labelprefix"].lower() in pageText )
		self.assertTrue( self.locale["example_labelprefix"].lower() in pageText )
		self.assertTrue( self.locale["exercise_labelprefix"].lower() in pageText )

if __name__ == "__main__":
	#import sys;sys.argv = ['', 'Test.testName']
	unittest.main()
