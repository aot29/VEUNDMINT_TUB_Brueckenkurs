'''
Created on Jun 16, 2016

Testet die Roulette-Uebungen

@author: alvaro
'''
import unittest
from test.systemtests.AbstractSystemTest import AbstractSystemTest

class RouletteTest( AbstractSystemTest ):

    def setUp(self):
        AbstractSystemTest.setUp( self )
        # navigate to chapter 1 section 1.2
        self._navToChapter( "1", "1.2", "de" )


    def testRouletteElement(self):
        '''
        Is the roulette exercise on te page?
        '''
        # get the first roulette exercise on the page
        roulette = self.driver.find_element_by_id( "ROULETTECONTAINER_VBKM01_FRACTIONTRAINING" )
        self.assertTrue( roulette, "Roulettecontainer not found" )


    def testLocale(self):
        '''
        Is the exercise in the right locale?
        '''
        # get the first roulette exercise on the page
        roulette = self.driver.find_element_by_id( "ROULETTECONTAINER_VBKM01_FRACTIONTRAINING" )
        # Check that keywords use the correct locale
        exerciseText = roulette.text.lower()
        self.assertTrue( self.locale["roulette_new"].lower() in exerciseText )
        self.assertTrue( self.locale["module_solution"].lower() in exerciseText )


    def testShowSolution(self):
        '''
        Is the solution shown after clicking on the hint button?
        '''
        # get the first roulette exercise on the page
        roulette = self.driver.find_element_by_id( "ROULETTECONTAINER_VBKM01_FRACTIONTRAINING" )
        # get the first hint element
        hintEl = self.driver.find_element_by_id( "MHint1" )
        self.assertTrue( hintEl, "Roulettecontainer not found" )

        # Check hint is hidden at first
        self.assertEqual( "display: none;", hintEl.get_attribute("style") , "Hint is not dispayed correctly")
        # Call display the hint-button directly in Javascript
        self.driver.execute_script( "toggle_hint('MHint1')" )
        # Check hint is revealed
        self.assertEqual( "display: block;", roulette.find_element_by_id( "MHint1" ).get_attribute("style") , "Hint is not dispayed correctly")


    def testRecognizeSolution(self):
        '''
        Is the correct solution recognized (marked in green)?
        Is the wrong solution recognized (marked in red)?
        '''

        # Call the hint-javascript to load the solution
        self.driver.execute_script( "toggle_hint('MHint1')" )

        # These exercises are fractions. Get the numerator and denominator of the solution (the solution comes last)
        nomXpath = "//div[@id='MHint1']/descendant::span[@class='mjx-numerator'][last()]"
        numerator = self.driver.find_element_by_xpath( nomXpath ).text
        denXpath = "//div[@id='MHint1']/descendant::span[@class='mjx-denominator'][last()]"
        denominator = self.driver.find_element_by_xpath( denXpath ).text

        # get the input field
        inputEl = self.driver.find_element_by_id( "QFELD_1.2.2.QF1" )

        # if input field is empty, icon should be "question mark"
        inputEl.clear()
        self.assertTrue( "questionmark" in self.driver.find_element_by_id( "QMQFELD_1.2.2.QF1" ).get_attribute( "src" ), "Answer is displaying the wrong image" )

        # if answer is wrong, icon should be "false"
        inputEl.send_keys( "1/0" )
        self.assertTrue( "false" in self.driver.find_element_by_id( "QMQFELD_1.2.2.QF1" ).get_attribute( "src" ), "Answer is displaying the wrong image" )

        # Put the solution in the input field: icon should be "right"
        answer = "%s/%s" % ( numerator, denominator )
        inputEl.clear()
        inputEl.send_keys( answer )
        self.assertTrue( "right" in self.driver.find_element_by_id( "QMQFELD_1.2.2.QF1" ).get_attribute( "src" ), "Answer is displaying the wrong image" )


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
