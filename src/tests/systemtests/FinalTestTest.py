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


    def testSubmitEmpty(self):
        '''
        Submitting an empty form should bring no points
        '''
        resetBtn = self.browser.find_element_by_id( 'TESTRESET' )
        resetBtn.click()
        submitBtn = self.browser.find_element_by_id( 'TESTFINISH' )
        submitBtn.click()
        response = self.browser.find_element_by_id( 'TESTEVAL' ).text
        expected = self.locale[ "msg-reached-points" ].replace( '$1', "0" ) # locale string is parametrized with $1
        self.assertTrue( expected in response, "Submitting an empty test form did not return 0 points" )
        

    def testLocale(self):
        '''
        Is the test in the right locale?
        '''
        # get the text of the page content
        # check that keywords use the correct locale
        pageText = self.browser.find_element_by_id( 'content' ).text.lower()
        self.assertTrue( self.locale["chapter"].lower() in pageText )
        self.assertTrue( self.locale["chapter"].lower() in pageText )
        self.assertTrue( self.locale["explanation_test"].lower() in pageText )
        self.assertTrue( self.locale["exercise_labelprefix"].lower() in pageText )
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
        exName = 'ADIV_1.5.1'
        lastTableCell = self.browser.find_element_by_xpath( "//div[@id='%s']/table//tr[last()]/td[last()]" % exName )
        self.assertTrue( lastTableCell.find_element_by_tag_name( 'input' ), 
                         "Multiple choice %s question is missing at least one answer button" % exName )
        
        
    def testAnswerIsExpression( self ):
        '''
        Exercise 1.5.5 takes a mathematical expression as answer

        Is the correct solution recognized (marked in green)?
        Is the wrong solution recognized (marked in red)?
        '''
        # get exercise
        exName = 'ADIV_1.5.5'
        exEl = self.browser.find_element_by_id( exName )
        # get the input field
        inputEl = exEl.find_element_by_tag_name( 'input' )
        # get the check field (question mark image)
        checkField = exEl.find_element_by_tag_name( 'img' )
        # get the submit button
        submitBtn = self.browser.find_element_by_id( 'TESTFINISH' )
        
        # if input field is empty, icon should be "question mark"
        inputEl.clear()
        submitBtn.click()
        self.assertTrue( "questionmark" in checkField.get_attribute( "src" ), 
                         "Exercise %s is displaying the wrong image when empty" % exName )

        # if answer is wrong, icon should be "false"
        inputEl.send_keys( "1/0" )
        submitBtn.click()
        self.assertTrue( "false" in checkField.get_attribute( "src" ), 
                         "Exercise %s is displaying the wrong image when wrong" % exName )


        # this is a problem as solution has to be entered in the test method
         
        # Put the solution in the input field: icon should be "right"
        # inputEl.clear()
        # inputEl.send_keys( "solution goes here" )
        # submitBtn.click()
        # self.assertTrue( "right" in checkField.get_attribute( "src" ), 
        #                  "Exercise %s is displaying the wrong image when correct" % exName )
        
        

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()