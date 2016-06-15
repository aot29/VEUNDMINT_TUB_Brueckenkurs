'''
Created on Jun 14, 2016

Unittest: are navigational elements present?
1. open the "module overview" page, 
2. check that expected nav elements are present, links and texts are correct

@author: alvaro
'''
import unittest
from selenium import webdriver
from selenium.webdriver.common.action_chains import ActionChains
import json
import os.path

class PageHeadTest(unittest.TestCase):
    baseUrl = "file:///home/alvaro/Workspace/VEUNDMINT_TUB_Brueckenkurs/tu9onlinekurstest/html"
    basePath = "/home/alvaro/Workspace/VEUNDMINT_TUB_Brueckenkurs/tu9onlinekurstest"
    pageUrl = "sectionx2.1.0.html"
    i18nPath = "i18n"
    lang = "en"
    

    def setUp(self):
        # load locale file
        localePath = os.path.join( self.basePath, self.i18nPath, self.lang + ".json")
        self.localeFile = open( localePath )
        self.locale = json.load( self.localeFile )
        # create the Firefox browser
        self.browser = webdriver.Firefox()
        # set try to find an element for max 10 seconds
        self.browser.implicitly_wait(10)
        # open the page
        self.browser.get( os.path.join( self.baseUrl, self.pageUrl ) )


    def tearDown(self):
        # close the browser
        if self.browser:
            self.browser.quit()
        # close the locale file
        if self.localeFile:
            self.localeFile.close()
        
        
    def testHeadButtonsPresent(self):
        '''
        Test head of the page and buttons
        '''
        # Find the head section of the page
        head = self.browser.find_element_by_id( "fhead" )
        self.assertTrue( head, "Page head is missing" )
        
        # Test nav buttons
        
        self._testButton( "loginbutton", "config.html", 
                          self.locale[ "ui-loginbutton" ], 
                          self.locale[ "hint-loginbutton" ] )
        self._testButton( "listebutton", "search.html", 
                          None, 
                          self.locale[ "hint-list" ] )
        self._testButton( "homebutton", "index.html", 
                          None, 
                          self.locale[ "hint-home" ] )
        self._testButton( "starbutton", "starClick", 
                          None, 
                          self.locale[ "msg-current-favorites" ] )
        self._testButton( "minusbutton", "changeFontSize", 
                          None, 
                          self.locale[ "hint-zoomout" ] )
        self._testButton( "plusbutton", "changeFontSize", 
                          None, 
                          self.locale[ "hint-zoomin" ] )
        self._testButton( "sharebutton", "shareClick", 
                          None, 
                          self.locale[ "msg-shared-page" ] )
        self._testButton( "settingsbutton", "toggle_settings", 
                          None, 
                          self.locale[ "hint-settings" ] )
        self._testButton( "menubutton", "menuClick", 
                          None, 
                          self.locale[ "hint-menu" ] )
        
        
    def _testButton(self, elid, href, text, hint):
        '''
        Test a navigation button for the right link and texts
        Are the buttons in the head section of the page present?
        Do they have the correct localized texts?
        Do they have the right links?
        
        @param elid: DOM id of the button element
        @param href: URL the button links to
        @param text: String displayed in the button element
        @param hint: String displayed on mouseover
        '''
        # Find the login button
        button = self.browser.find_element_by_id( elid )
        self.assertTrue( button, "%s is missing" % elid )

        # Check button text if button is a div 
        if button.tag_name == "div":
            self.assertEquals( text.lower(), button.text.lower(), "%s has wrong text" % elid )            
                
        # check the link
        link = self._resolveButtonLInk( elid, button.tag_name )
        self.assertTrue( href in link )
        
        # Check hint
        qtipNr = button.get_attribute('data-hasqtip')
        if qtipNr:
            # hint element is added to the page on mouseover
            hover = ActionChains(self.browser)
            hover.move_to_element(button).perform()
            qtipEl = self.browser.find_element_by_id( "qtip-%s-content" % qtipNr )
            # hint text should be part of displayed tooltip (not necessarily equal)
            self.assertTrue( hint in qtipEl.text, "%s has wrong hint text" % elid )


    def _resolveButtonLInk(self, elid, tag):
        '''
        Get the link from a navigation button, whichever type the button is
        @param elid: DOM id of the button element
        @param tagName: name of the element containing the button (i.e. div, a or button) 
        '''
        # if button is a text button, check the text displayed and get the link (parent of "div"-element)
        if tag == "div":
            linkEl = self.browser.find_element_by_xpath( "//div[@id='%s']/.." % elid )
            link = linkEl.get_attribute('href')
            
        # if button is a link, get only the link ("a"-element)
        elif tag == "a":
            linkEl = self.browser.find_element_by_xpath( "//a[@id='%s']" % elid )
            link = linkEl.get_attribute('href')
            
        # if button is a javascript button, get the "onClick" attribute
        elif tag == "button":
            linkEl = self.browser.find_element_by_xpath( "//button[@id='%s']" % elid )
            link = linkEl.get_attribute('onclick')
            
        return link
    
        
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
