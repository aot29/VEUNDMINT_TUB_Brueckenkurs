'''
Created on Jun 16, 2016

@author: alvaro
'''
import unittest
from tests.systemtests.AbstractSystemTest import AbstractSystemTest

class FinalTestTest( AbstractSystemTest ):
    '''
    Test the final test for module 1
    '''

    def setUp( self ):
        AbstractSystemTest.setUp(self)
        # navigate to chapter 1, final test (1.5)
        self._navToChapter( "1", "1.5" )


    def testLocale(self):
        '''
        Is the test in the right locale?
        '''
        # get the text of the page content
        # check that keywords use the correct locale
        pageText = self.browser.find_element_by_id( 'content' ).text.lower()
        self.assertTrue( self.locale["chapter"].lower() in pageText )
        self.assertTrue( self.locale["module_labelprefix"].lower() in pageText )
        self.assertTrue( self.locale["explanation_test"].lower() in pageText )
        self.assertTrue( self.locale["exercise_labelprefix"].lower() in pageText )
        # where do these come from?
        self.assertTrue( "Submit test".lower() in pageText )
        self.assertTrue( "Reset and restart".lower() in pageText )
        self.assertTrue( "The test evaluation will be displayed here".lower() in pageText )


    def testExercise_1_5_5( self ):
        '''
        Exercise 1.5.5 takes a mathematical expression as answer

        Is the correct solution recognized (marked in green)?
        Is the wrong solution recognized (marked in red)?
        '''
        # get the input field
        inputEl = self.browser.find_element_by_id( "QFELD_1.5.2.QF6" )
        # get the submit button
        submitBtn = self.browser.find_element_by_id( 'TESTFINISH' )
        
        # if input field is empty, icon should be "question mark"
        inputEl.clear()
        submitBtn.click()
        self.assertTrue( "questionmark" in self.browser.find_element_by_id( "QMQFELD_1.5.2.QF6" ).get_attribute( "src" ), "Answer is displaying the wrong image" )

        # if answer is wrong, icon should be "false"
        inputEl.send_keys( "1/0" )
        submitBtn.click()
        self.assertTrue( "false" in self.browser.find_element_by_id( "QMQFELD_1.5.2.QF6" ).get_attribute( "src" ), "Answer is displaying the wrong image" )

        # Put the solution in the input field: icon should be "right"
        inputEl.clear()
        inputEl.send_keys( "x^(3/2)" )
        submitBtn.click()
        self.assertTrue( "right" in self.browser.find_element_by_id( "QMQFELD_1.5.2.QF6" ).get_attribute( "src" ), "Answer is displaying the wrong image" )
        
        

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()