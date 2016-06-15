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
    baseUrl = "file:///home/alvaro/Workspace/VEUNDMINT_TUB_Brueckenkurs/tu9onlinekurstest/html"
    basePath = "/home/alvaro/Workspace/VEUNDMINT_TUB_Brueckenkurs/tu9onlinekurstest"
    i18nPath = "i18n"
    lang = "en"
    pageUrl = "sectionx2.1.0.html"


    def setUp(self):
        # load locale file
        localePath = os.path.join( self.basePath, self.i18nPath, self.lang + ".json")
        self.localeFile = open( localePath )
        self.locale = json.load( self.localeFile )
        # create the Firefox browser
        self.browser = webdriver.Firefox()
        # set try to find an element for max 10 seconds
        self.browser.implicitly_wait(10)


    def tearDown(self):
        # close the browser
        if self.browser:
            self.browser.quit()
        # close the locale file
        if self.localeFile:
            self.localeFile.close()


    def _openStartPage(self):
        '''
        Opens the start page of the online course in a browser. Used to test navigation elements and toc.
        '''
        self.browser.get( os.path.join( self.baseUrl, self.pageUrl ) )


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
