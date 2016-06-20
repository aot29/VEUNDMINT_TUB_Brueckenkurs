'''
Created on Jun 15, 2016

Test the TOC navigation area

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


    def testTitlePresent(self):
        '''
        Test the TOC title is present
        '''
        # Find the TOC title section of the page
        el = self.browser.find_element_by_class_name( "tocmintitle" )
        self.assertTrue( el, "TOC title is missing" )
        self.assertEqual( self.locale[ "module_content" ].lower(), el.text.lower(), "TOC title is wrong" )
        
        
    def testTocPresent(self):
        '''
        Test table of contents of the page
        '''
        # Find the toc section of the page
        toc = self.browser.find_element_by_id( "ftoc" )
        self.assertTrue( toc, "Page toc is missing" )

        # Link to chapter 1-10 should be there
        for n in range(1, 10):
            self.assertTrue( self.browser.find_element_by_partial_link_text( "%s %s" % ( self.locale[ 'chapter' ], n ) ), "No link to chapter %s found" % n)


    def testLegendPresent(self):
        '''
        Test the TOC legend is present
        '''
        # Find the TOC legend section of the page
        el = self.browser.find_element_by_class_name( "legende" )
        self.assertTrue( el, "Legend is missing" )


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()