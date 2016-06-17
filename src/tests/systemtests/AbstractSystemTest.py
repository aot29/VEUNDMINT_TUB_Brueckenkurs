'''
Created on Jun 15, 2016

Base class for all system tests

@author: alvaro
'''
import unittest
from selenium import webdriver
import json
import os.path

class AbstractSystemTest(unittest.TestCase):
    '''
    baseURL can be a file or a http URL. 
    baseURL should be absolute.
    If it's a file, it should be the complete path to a file. 
    If it's a http URL, then the path can use the forward slash if the server is so configured 
    '''
    baseUrl = "file:////var/www/html/tu9onlinekurstest/index.html"
    '''
    Absolute path to the checkout directory
    '''
    basePath = "~/Workspace/VEUNDMINT_TUB_Brueckenkurs/"
    '''
    Language to be used for locale
    (it would be better to read this from Option.py, but import doesn't work as expected)
    '''
    lang = "de"

    def setUp(self):
        # load locale file
        try:
            i18nPath = os.path.expanduser( os.path.join( self.basePath, "src/files/i18n/%s.json" % self.lang ) )
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
            

    def _openStartPage(self):
        '''
        Opens the start page of the online course in a browser. Used to test navigation elements and toc.
        '''
        self.browser.get( os.path.expanduser( self.baseUrl ) )


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
