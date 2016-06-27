'''
Created on Jun 15, 2016

Base class for all system tests

@author: alvaro
'''
import unittest
from selenium import webdriver
import json
import os.path, ConfigParser

class AbstractSystemTest(unittest.TestCase):
    '''Path to configuration file for the tests.'''
    configPath =  "../testconfig.ini"
    
    def setUp(self):
        #Read the configuration file
        self.config = ConfigParser.ConfigParser()
        self.config.read( self.configPath )

        # load locale file
        try:
            i18nPath = os.path.expanduser( os.path.join( self._getConfigParam( 'basePath' ), "src/files/i18n/%s.json" % self._getConfigParam( 'lang' ) ) )
            localeFile = open( i18nPath )
            self.locale = json.load( localeFile )
            
        finally:
            localeFile.close()

        # create the Firefox browser
        self.browser = webdriver.Firefox()

        # set timeout to 5 seconds
        self.browser.implicitly_wait(5)


    def tearDown(self):
        # close the browser
        if self.browser:
            self.browser.quit()
            

    def _getConfigParam(self, key):
        return self.config.get( 'defaults', key )
        

    def _openStartPage(self):
        '''
        Opens the start page of the online course in a browser. Used to test navigation elements and toc.
        '''
        self.browser.get( os.path.expanduser( self._getConfigParam( 'baseUrl' ) ) )


    def _navToChapter(self, chapter, section=None):
        '''
        Navigate to chapter specified by name.
        @param chapter: (required) a STRING specifying the chapter, e.g. "1" will open chapter 1 
        @param section: (optional) a STRING specifying the section, e.g. "1.2" will open section 1.2
        '''
        # Open the start page
        self._openStartPage()
        # Open chapter 
        self.browser.find_element_by_partial_link_text( "%s %s" % ( self.locale[ "chapter" ], chapter ) ).click()
        
        # Open section
        if section != None:
            content = self.browser.find_element_by_id( "content" )
            content.find_element_by_partial_link_text( section ).click()


# Can't call this directly, use child class
if __name__ == "__main__":
    raise NotImplementedError        
