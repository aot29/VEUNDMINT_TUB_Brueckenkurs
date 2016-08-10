import unittest
import os
from settings import BASE_URL, BASE_DIR
from selenium import webdriver
import configparser as ConfigParser
import json
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By


class SeleniumTest(unittest.TestCase):
    configPath = os.path.join(BASE_DIR + "/", "src/test/", "testconfig.ini")

    @classmethod
    def setUpClass(self):
        self.driver = webdriver.PhantomJS(executable_path=BASE_DIR + '/node_modules/phantomjs/lib/phantom/bin/phantomjs', service_log_path=BASE_DIR + '/ghostdriver.log')
        #self.driver = webdriver.Firefox()
        self.driver.set_window_size(1120, 550)
        self.driver.set_page_load_timeout(5)
        self.driver.implicitly_wait(5)

        #Read the configuration file
        self.config = ConfigParser.ConfigParser()
        self.config.read( self.configPath )

        # load locale file
        localeFile = None
        try:
            i18nPath = os.path.expanduser( os.path.join( BASE_DIR, "src/files/i18n/%s.json" % self._getConfigParam( self, 'lang' ) ) )
            localeFile = open( i18nPath )
            self.locale = json.load( localeFile )

        finally:
            if localeFile:
                localeFile.close()

    @classmethod
    def tearDownClass(self):
        self.driver.close()
        self.driver.quit()

    def _openStartPage(self, no_mathjax=False):
        '''
        Opens the start page of the online course in the webdriver Used to test navigation elements and toc.
        '''
        # 		print ('_openStartPage with %s ' % BASE_URL)
        #
        # 		if (self.driver.current_url != BASE_URL):
        # 		# get the url from environment, otherwise from settings
        start_url = os.getenv('BASE_URL', BASE_URL)
        if no_mathjax:
            self.driver.get( start_url + '?no_mathjax' )
        else:
            self.driver.get( start_url )

    def _navToChapter(self, chapter, section=None, lang = "de", no_mathjax=False):
        '''
        Navigate to chapter specified by name.
        @param chapter: (required) a STRING specifying the chapter, e.g. "1" will open chapter 1
        @param section: (optional) a STRING specifying the section, e.g. "1.2" will open section 1.2
        @param lang: (optional) a STRING specifying the language code, e.g. "de" or "en"
        '''
        # Open the start page
        #self._openStartPage()
        self._chooseLanguageVersion( lang, no_mathjax=no_mathjax )

        # Open chapter
        #
        link_text = "%s %s" % ( self.locale[ "chapter" ], chapter )
        chapter_el = WebDriverWait(self.driver, 10).until(
        EC.presence_of_element_located((By.PARTIAL_LINK_TEXT, link_text))
        )

        chapter_el.click()

        # element = self.driver.find_element_by_partial_link_text( "%s %s" % ( self.locale[ "chapter" ], chapter ) )
        # element.click()

        # Open section
        if section != None:

            section_el = WebDriverWait(self.driver, 5).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, 'a[href*="' + chapter + "." + section + '"]'))
            )

            section_el.click()

    def _getConfigParam(self, key):
        return self.config.get( 'defaults', key )

    def _chooseLanguageVersion(self, languagecode, no_mathjax=False):
        '''
        Navigate to the specified language version of the website
        @param languagecode: (required) a STRING specifying the language code, e.g. "de" or "en"
        '''
        self._openStartPage(no_mathjax=no_mathjax)

        self.driver.find_element_by_css_selector("a[href*='/" + languagecode + "/']").click();
