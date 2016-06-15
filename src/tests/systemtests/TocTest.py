'''
Created on Jun 15, 2016

@author: alvaro
'''
import unittest
from tests.systemtests.AbstractSystemTest import AbstractSystemTest


class TocTest( AbstractSystemTest ):
    pageUrl = "sectionx2.1.0.html"


    def setUp(self):
        AbstractSystemTest.setUp( self )
        # open a page to test it
        self._openStartPage()


    def tearDown(self):
        AbstractSystemTest.tearDown( self )


    def testTocButtonsPresent(self):
        '''
        Test table of contents of the page
        '''
        # Find the toc section of the page
        toc = self.browser.find_element_by_id( "ftoc" )
        self.assertTrue( toc, "Page toc is missing" )

        for n in range(1, 11):
            self.browser.find_element_by_link_text( "sectionx" )


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()