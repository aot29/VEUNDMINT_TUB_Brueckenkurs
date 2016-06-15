'''
Created on Jun 15, 2016

Test chapter 1

@author: alvaro
'''
import unittest
from tests.systemtests.AbstractSystemTest import AbstractSystemTest


class Test( AbstractSystemTest ):

    def setUp(self):
        AbstractSystemTest.setUp( self )
        # open the start page
        self._openStartPage()
        # Open chapter 1
        self.browser.find_element_by_partial_link_text( "Chapter 1" ).click()


    def tearDown(self):
        AbstractSystemTest.tearDown( self )


    def testLaunchButton(self):
        '''
        Does the launch Button contains the right locale?
        '''
        self.assertTrue( self.browser.find_element_by_partial_link_text( self.locale["module_starttext"].upper() ) )

    
    def testOverviewPageContent(self):
        '''
        Does the overview page list the expected number of chaper sections?
        '''
        content = self.browser.find_element_by_id( "content" )
        sections = content.find_elements_by_tag_name( "li" )
        self.assertEqual( 5, len( sections ), "Chapter 1 has the wrong number of sections" )


    def testChapter1Section2(self):
        '''
        Is the page in the right locale?
        '''
        # Open the *second* subsection (as it's more interesting than the first one)
        content = self.browser.find_element_by_id( "content" )
        content.find_element_by_partial_link_text( "1.2" ).click()
        # Check that keywords use the correct locale
        pageText = self.browser.find_element_by_id( "content" ).text.lower()
        self.assertTrue( self.locale["chapter"].lower() in pageText )
        self.assertTrue( self.locale["subsection_labelprefix"].lower() in pageText )
        self.assertTrue( self.locale["example_labelprefix"].lower() in pageText )
        self.assertTrue( self.locale["exercise_labelprefix"].lower() in pageText )
        
    
    def testRoulette(self):
        pass
    
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()