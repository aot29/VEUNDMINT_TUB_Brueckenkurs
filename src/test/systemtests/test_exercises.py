'''
Created on Jun 16, 2016

Testet die Roulette-Uebungen

@author: alvaro
'''
import unittest
from test.systemtests.SeleniumTest import SeleniumTest
from selenium.webdriver.support.ui import WebDriverWait

class RouletteTest( SeleniumTest ):

    def setUp(self):
        SeleniumTest.setUp( self )
        # navigate to chapter 1 section 1.2
        self._navToChapter( "1", "1.2", "de")


    def testRouletteElement(self):
        '''
        Is the roulette exercise on the page?
        '''
        # get the first roulette exercise on the page
        roulette = self.getElement( "ROULETTECONTAINER_VBKM01_FRACTIONTRAINING" )
        self.assertTrue( roulette, "Roulettecontainer not found" )


    def testLocale(self):
        '''
        Is the exercise in the right locale?
        '''
        # get the first roulette exercise on the page
        roulette = self.getElement( "ROULETTECONTAINER_VBKM01_FRACTIONTRAINING" )
        # Check that keywords use the correct locale
        exerciseText = roulette.text.lower()
        self.assertTrue( self.locale["roulette_new"].lower() in exerciseText )
        self.assertTrue( self.locale["module_solution"].lower() in exerciseText )


    def testShowSolution(self):
        '''
        Is the solution shown after clicking on the hint button?
        '''
        # get the first roulette exercise on the page
        roulette = self.getElement( "ROULETTECONTAINER_VBKM01_FRACTIONTRAINING" )
        # get the first hint element
        hintEl = self.getElement( "MHint1" )
        self.assertTrue( hintEl, "Roulettecontainer not found" )

        # Check hint is hidden at first
        self.assertEqual( "display: none;", hintEl.get_attribute("style") , "Hint is not dispayed correctly")
        # Call display the hint-button directly in Javascript
        self.driver.execute_script( "toggle_hint('MHint1')" )
        # Check hint is revealed
        self.assertEqual( "display: block;", self.getElement( "MHint1" ).get_attribute("style") , "Hint is not dispayed correctly")


    def testRecognizeSolution(self):
        '''
        Is the correct solution recognized (marked in green)?
        Is the wrong solution recognized (marked in red)?
        '''

        # Call the hint-javascript to load the solution
        self.driver.execute_script( "toggle_hint('MHint1')" )

        # These exercises are fractions. Get the numerator and denominator of the solution (the solution comes last)

        # Works in Firefox but not in PhantoJS
        #numerator = self.getElement( 'numerator' ).text
        #denominator = self.getElement( 'denominator' ).text
        numerator = 66
        denominator = 13

        # get the input field
        inputEl = self.getElement( "QFELD_1.2.2.QF1" )

        if self.isBootstrap():
            # if input field is empty, icon should be "question mark"
            inputEl.clear()
            self.assertTrue( "question-sign" in self.getElement( "QMQFELD_1.2.2.QF1" ).get_attribute( "class" ), "Answer is displaying the wrong image" )

            # if answer is wrong, icon should be "false"
            inputEl.send_keys( "1/0" )
            self.assertTrue( "remove" in self.getElement( "QMQFELD_1.2.2.QF1" ).get_attribute( "class" ), "Answer is displaying the wrong image" )

            # Put the solution in the input field: icon should be "right"
            answer = "%s/%s" % ( numerator, denominator )
            inputEl.clear()
            inputEl.send_keys( answer )
            self.assertTrue( "ok" in self.getElement( "QMQFELD_1.2.2.QF1" ).get_attribute( "class" ), "Answer %s is displaying the wrong image" % answer )

        else:
            # if input field is empty, icon should be "question mark"
            inputEl.clear()
            self.assertTrue( "questionmark" in self.getElement( "QMQFELD_1.2.2.QF1" ).get_attribute( "src" ), "Answer is displaying the wrong image" )

            # if answer is wrong, icon should be "false"
            inputEl.send_keys( "1/0" )
            self.assertTrue( "false" in self.getElement( "QMQFELD_1.2.2.QF1" ).get_attribute( "src" ), "Answer is displaying the wrong image" )

            # Put the solution in the input field: icon should be "right"
            answer = "%s/%s" % ( numerator, denominator )
            inputEl.clear()
            inputEl.send_keys( answer )
            self.assertTrue( "right" in self.getElement( "QMQFELD_1.2.2.QF1" ).get_attribute( "src" ), "Answer is displaying the wrong image" )

class ExercisesTest( SeleniumTest ):

    def testInputLoadedCorrectly(self):
        """
        Test if the user input in an exercise question is reloaded when the page
        is reloaded / navigated away. In js the localstorage object should be used
        to populate input fields made by the user.
        """

        correct_answer = '3/8'

        wait = WebDriverWait(self.driver, 30)
        self._navToChapter("1", "1.2")

        questionInput = self.getElement('QFELD_1.2.2.QF601')
        questionInput.clear()
        questionInput.send_keys(correct_answer)
        self.assertEquals(questionInput.get_attribute('value'), correct_answer)

        #reload the page and check that the value is still in the input
        self._navToChapter("1", "1.2")
        questionInput = self.getElement('QFELD_1.2.2.QF601')
        self.assertEquals(questionInput.get_attribute('value'), correct_answer)



if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
