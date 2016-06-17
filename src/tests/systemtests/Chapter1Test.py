'''
Created on Jun 15, 2016

@author: alvaro
'''
import unittest
from tests.systemtests.AbstractSystemTest import AbstractSystemTest


class Chapter1Test( AbstractSystemTest ):
    '''
    Test chapter 1
    '''
    def setUp( self ):
        AbstractSystemTest.setUp(self)
        # navigate to chapter 1
        self._navToChapter( "1" )


    def testStartPageContent(self):
        '''
        Does the overview page list the expected number of chaper sections?
        '''
        # count number of sections listed
        content = self.browser.find_element_by_id( "content" )
        sections = content.find_elements_by_tag_name( "li" )
        self.assertEqual( 5, len( sections ), "Chapter 1 has the wrong number of sections" )


    def testLaunchButton(self):
        '''
        Does the "launch module" Button on the chapter 1 page contains the right locale?
        '''
        self.assertTrue( self.browser.find_element_by_partial_link_text( self.locale["module_starttext"].upper() ) )


    def testChapter1Section2(self):
        '''
        Is the page in the right locale?
        '''
        # Open the *second* subsection (as it's more interesting than the first one)
        self._navToChapter( "1", "1.2" )
        
        # Check that keywords use the correct locale
        pageText = self.browser.find_element_by_id( "content" ).text.lower()
        self.assertTrue( self.locale["chapter"].lower() in pageText )
        self.assertTrue( self.locale["subsection_labelprefix"].lower() in pageText )
        self.assertTrue( self.locale["example_labelprefix"].lower() in pageText )
        self.assertTrue( self.locale["exercise_labelprefix"].lower() in pageText )
        
        
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()