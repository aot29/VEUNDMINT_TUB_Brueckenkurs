'''
Created on Jun 16, 2016

Testet die Roulette-Uebungen

@author: alvaro
'''
import unittest
from tests.systemtests.AbstractSystemTest import AbstractSystemTest


class RouletteTest( AbstractSystemTest ):


    def testLocale(self):
        '''
        Is the exercise in the right locale?
        '''
        # navigate to chapter 1 section 1.2
        self._navToChapter( "1", "1.2" )
        # get the first roulette exercise on the page
        roulette = self.browser.find_element_by_id( "ROULETTECONTAINER_VBKM01_FRACTIONTRAINING" )
        self.assertTrue( roulette, "Roulettecontainer not found" )
        # Check that keywords use the correct locale
        exerciseText = roulette.text.lower()
        self.assertTrue( self.locale["roulette_new"].lower() in exerciseText )
        self.assertTrue( self.locale["module_solution"].lower() in exerciseText )


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()