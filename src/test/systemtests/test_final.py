'''
Created on Jun 16, 2016

@author: alvaro
'''
import unittest
from test.systemtests.SeleniumTest import SeleniumTest
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

class FinalTestTest( SeleniumTest ):
    '''
    Test the final test for module 1
    '''

    def setUp( self ):
        SeleniumTest.setUp(self)
        # navigate to chapter 1, final test (1.5)
        self._navToChapter( "1", "1.5", no_mathjax=True )


    def testSubmitEmpty(self):
        '''
        Submitting an empty form should bring no points
        '''
        resetBtn = self.getElement( 'TESTRESET' )
        resetBtn.click()
        submitBtn = self.getElement( 'TESTFINISH' )
        submitBtn.click()
        response = self.getElement( 'TESTEVAL' ).text
        expected = self.locale[ "msg-reached-points" ].replace( '$1', "0" ) # locale string is parametrized with $1
        self.assertTrue( expected in response, "Submitting an empty test form did not return 0 points" )


    def testLocale(self):
        '''
        Is the test in the right locale?
        '''
        # get the text of the page content
        # check that keywords use the correct locale
        #
        content = self.getElement( 'pageContents' )
        page_text = content.text.lower()

        self.assertTrue( self.locale["chapter"].lower() in page_text )
        self.assertTrue( self.locale["chapter"].lower() in page_text )
        self.assertTrue( self.locale["explanation_test"].lower() in page_text )
        self.assertTrue( self.locale["exercise_labelprefix"].lower() in page_text )
        # where do these come from?
        #self.assertTrue( "Submit test".lower() in pageText )
        #self.assertTrue( "Reset and restart".lower() in pageText )
        #self.assertTrue( "The test evaluation will be displayed here".lower() in pageText )


    def testAnswerIsMultipleChoice(self):
        '''
        Exercise 1.5.1 takes a multiple choice answer
        The 3-state multiple choice buttons should appear.
        '''
        # the last table cell (bottom/right) should not be empty
        lastTableCell = self.getElement( 'lastTableCell' )
        self.assertTrue( lastTableCell.find_element_by_tag_name( 'input' ),
                         "Multiple choice %s question is missing at least one answer button" )


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
