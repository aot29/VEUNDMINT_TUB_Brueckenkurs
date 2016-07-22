'''
Created on Jun 15, 2016

Base class for all system tests

@author: alvaro
'''
import unittest
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import json
import os.path
import configparser as ConfigParser
from test.test_tools import getBaseDirectory
from settings import BASE_DIR, BASE_URL
from distutils.spawn import find_executable


class AbstractSystemTest(unittest.TestCase):
	'''Path to configuration file for the tests.'''
	configPath = os.path.join(BASE_DIR + "/", "src/test/", "testconfig.ini")

	def setUp(self):
		
		
		#Read the configuration file
		self.config = ConfigParser.ConfigParser()
		self.config.read( self.configPath )

		# load locale file
		localeFile = None
		try:
			i18nPath = os.path.expanduser( os.path.join( BASE_DIR, "src/files/i18n/%s.json" % self._getConfigParam( 'lang' ) ) )
			localeFile = open( i18nPath )
			self.locale = json.load( localeFile )

		finally:
			if localeFile:
				localeFile.close()

		# create the Web Driver with PhantomJS
		# TODO make this generic
						
		self.driver = webdriver.PhantomJS(executable_path=BASE_DIR + '/node_modules/phantomjs/lib/phantom/bin/phantomjs', service_log_path=BASE_DIR + '/ghostdriver.log')
		self.driver.set_window_size(1120, 550)
#		self.driver.set_page_load_timeout(5)
		self.driver.implicitly_wait(5)
		
		
	def tearDown(self):				
		# close the webdriver
		if self.driver:
			self.driver.quit()


	def _getConfigParam(self, key):
		return self.config.get( 'defaults', key )


	def _openStartPage(self):
		'''
		Opens the start page of the online course in the webdriver Used to test navigation elements and toc.
		'''
# 		print ('_openStartPage with %s ' % BASE_URL)
# 					
# 		if (self.driver.current_url != BASE_URL):
		self.driver.get( BASE_URL )
# 		
# 			wait = WebDriverWait(self.driver, 3)
# 			element = wait.until(EC.presence_of_element_located((By.ID,'languageChooser')))
# 		else:
# 			print("openStartPage was already on start Page")


	def _navToChapter(self, chapter, section=None, lang = "de"):
		'''
		Navigate to chapter specified by name.
		@param chapter: (required) a STRING specifying the chapter, e.g. "1" will open chapter 1
		@param section: (optional) a STRING specifying the section, e.g. "1.2" will open section 1.2
		@param lang: (optional) a STRING specifying the language code, e.g. "de" or "en"
		'''
		# Open the start page
		self._openStartPage()
		self._chooseLanguageVersion( lang )
		# Open chapter		
		element = self.driver.find_element_by_partial_link_text( "%s %s" % ( self.locale[ "chapter" ], chapter ) )
		element.click()

		# Open section
		if section != None:
			content = self.driver.find_element_by_id( "content" )
			content.find_element_by_partial_link_text( section ).click()
			
	def _chooseLanguageVersion(self, languagecode):
		'''
		Navigate to the specified language version of the website
		@param languagecode: (required) a STRING specifying the language code, e.g. "de" or "en"
		'''
		self._openStartPage()
		
		#print ('on page %s' % self.driver.current_url)

# 		wait = WebDriverWait(self.driver, 10)
# 		language_links = self.driver.find_elements_by_class_name('btn')
# 	
# 		print(language_links[0].get_attribute('href'))
# 		el = [x for x in language_links if languagecode in x.get_attribute('href')]
# 		el[0].click()
# 		
		self.driver.find_element_by_css_selector("a[href*='/" + languagecode + "/']").click();


# Can't call this directly, use child class
if __name__ == "__main__":
	raise NotImplementedError
