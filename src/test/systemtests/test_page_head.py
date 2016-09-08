'''
Created on Jun 14, 2016

Unittest: are navigational elements present?
1. open the "module overview" page,
2. check that expected nav elements are present, links and texts are correct

@author: alvaro
'''
import unittest
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.select import Select
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

	def testChangeLanguageButton(self):
		'''
		Test if ChangeLanguageButton is present and working correctly, i.e.
		navigate to the same page in other language if language select is changed
		'''

		# does it show the correct version
		self._navToChapter("1", section="1.3", lang = "de")
		selectLanguageButton = self.getElement ( "selectLanguage" )
		selectLanguageSelect = Select(selectLanguageButton)

		pageDeUrl = self.driver.current_url
		print(pageDeUrl)

		self.assertTrue( selectLanguageButton, "selectLanguage button is missing" )

		#is the correct language selected?
		self.assertEqual(selectLanguageSelect.first_selected_option.text, "de")

		#navigate to other language
		for option in selectLanguageButton.find_elements_by_tag_name('option'):
			if option.text == 'en':
				option.click()
				break

		selectLanguageButton = self.getElement ( "selectLanguage" )
		selectLanguageSelect = Select(selectLanguageButton)

		#is the correct language selected?
		self.assertEqual(selectLanguageSelect.first_selected_option.text, "en")

		#did we land on the correct page?
		self.assertEqual(self.driver.current_url.replace("/en/", "/de/"), pageDeUrl)

if __name__ == "__main__":
    unittest.main()






if __name__ == "__main__":
	#import sys;sys.argv = ['', 'Test.testName']
	unittest.main()
