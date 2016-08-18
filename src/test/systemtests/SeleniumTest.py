import unittest
import os
from settings import BASE_URL, BASE_DIR
from selenium import webdriver
import configparser as ConfigParser
import json
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from tex2x.Settings import ve_settings as settings

class SeleniumTest(unittest.TestCase):
    configPath = os.path.join(BASE_DIR + "/", "src/test/", "testconfig.ini")

    # Xpaths for the bootstrap and non-bootstrap versions
    # Most xpaths assume you are starting from the root element (e.g. using self.driver).
    xpath = {
        'bootstrap': {
            'pageContents' : "//div[@id='pageContents']",
            'launchButton' : "//div[@id='pageContents']/a[@type='button']",
            'launchButtonTextElement' : "//div[@id='pageContents']/a[@type='button']/span[@data-i18n]",
            'TESTRESET' : "//button[@id='TESTRESET']",
            'TESTFINISH' : "//button[@id='TESTFINISH']",
            'TESTEVAL' : "//p[@id='TESTEVAL']",
            'lastTableCell' : "//div[@id='pageContents']//table//tr[last()]/td[last()]"
        },
        'html5': {
            'pageContents' : "//div[@id='content']",
            'launchButton' : "//div[@id='content']/button",
            'launchButtonTextElement' : "//div[@id='content']/button",
            'TESTRESET' : "//button[@id='TESTRESET']",
            'TESTFINISH' : "//button[@id='TESTFINISH']",
            'TESTEVAL' : "//p[@id='TESTEVAL']",
            'lastTableCell' : "//div[@id='content']//table//tr[last()]/td[last()]"
        }
    }

    @classmethod
    def setUpClass(self):
        #self.driver = webdriver.PhantomJS(executable_path=BASE_DIR + '/node_modules/phantomjs/lib/phantom/bin/phantomjs', service_log_path=BASE_DIR + '/ghostdriver.log')
        self.driver = webdriver.Firefox()
        self.driver.set_window_size(1120, 550)
        self.driver.set_page_load_timeout(5)
        self.driver.implicitly_wait(5)

        #Read the configuration file
        self.config = ConfigParser.ConfigParser()
        self.config.read( self.configPath )
        
        # set global timeout
        wait = WebDriverWait(self.driver, 3)

        # load locale file
        localeFile = None
        try:
            i18nPath = os.path.expanduser( os.path.join( BASE_DIR, "src/files/i18n/%s.json" % self._getConfigParam( self, 'lang' ) ) )
            localeFile = open( i18nPath )
            self.locale = json.load( localeFile )

        finally:
            if localeFile:
                localeFile.close()
                
        # set URL's
        self.start_url = os.getenv('BASE_URL', BASE_URL)


    @classmethod
    def tearDownClass(self):
        self.driver.close()
        self.driver.quit()


    def getElement( self, key ):
        """
        Get a DOM element by looking the key up in the array of xpaths.
        The xpath depends on whether the bootstrap on non-bootstrap version is being built 
        Use this instead of self.driver.find_element_by_xpath('...')
        
        @param key - String key in the self.xpath dict 
        """
        if settings.bootstrap == 1:
            val = self.xpath['bootstrap'][ key ]

        else:
            val = self.xpath['html5'][ key ]
        
        return self.driver.find_element_by_xpath( val )


    def _openStartPage(self, no_mathjax=False):
        '''
        Opens the start page of the online course in the webdriver Used to test navigation elements and toc.
        '''
        # 		print ('_openStartPage with %s ' % BASE_URL)
        #
        # 		if (self.driver.current_url != BASE_URL):
        # 		# get the url from environment, otherwise from settings
        if no_mathjax:
            self.driver.get( self.start_url + '?no_mathjax=' )
            #print('we are at: %s %s' % (start_url, '?no_mathjax='))
        else:
            self.driver.get( self.start_url )
            # print('we are at: %s' % start_url)

    def _navToChapter(self, chapter, section=None, lang = "de", no_mathjax=False):
        '''
        Navigate to chapter specified by name.
        @param chapter: (required) a STRING specifying the chapter, e.g. "1" will open chapter 1
        @param section: (optional) a STRING specifying the section, e.g. "1.2" will open section 1.2
        @param lang: (optional) a STRING specifying the language code, e.g. "de" or "en"
        '''

        if section is None:
            # Open chapter
            url = "%s/html/%s/sectionx%s.1.0.html" % ( self.start_url, lang, chapter )
            
        else:
            # Open section
            url = "%s/html/%s/%s.%s/modstart.html" % ( self.start_url, lang, chapter, section )
        
        self.driver.get( url )


    def _getConfigParam(self, key):
        return self.config.get( 'defaults', key )


    def _chooseLanguageVersion(self, languagecode, no_mathjax=False):
        '''
        Navigate to the specified language version of the website
        @param languagecode: (required) a STRING specifying the language code, e.g. "de" or "en"
        '''
        self._openStartPage(no_mathjax=no_mathjax)

        self.driver.find_element_by_css_selector("a[href*='/" + languagecode + "/']").click();
