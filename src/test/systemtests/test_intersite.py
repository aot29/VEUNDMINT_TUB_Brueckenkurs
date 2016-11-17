import unittest
import json
from test.systemtests.SeleniumTest import SeleniumTest
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.by import By

class IntersiteTest( SeleniumTest ):

    intersiteObj = None

    def setUp( self ):
        SeleniumTest.setUp(self)

        #we need to go to a page first so we can access window.localStorage
        self._chooseLanguageVersion('en')

        #clear the localstorage by going to logout.html
        url = "%s/html/de/logout.html" % self.start_url
        self._loadPage(url)

        #and make the javascripts set the intersite obj when loading the page
        self._chooseLanguageVersion('en')

    @unittest.skip("Test needs more attention after js refactoring")
    def testIntersiteObjAvailable(self):
        """
        Test that the intersite Obj from localstorage is available
        """
        self.assertIsNotNone(self.getIntersiteObj())

    @unittest.skip("Test needs more attention after js refactoring")
    def testIntersiteScoresSet(self):
        """
        Test that Scores are empty at the beginning and filled when an exercise is answered correctly
        """
        self.assertEquals(self.getIntersiteObj()['scores'], [])

        self._navToChapter("1", "1.2")

        questionInput = self.getElement('QFELD_1.2.2.QF602')
        questionInput.clear()
        questionInput.send_keys('7/10')

        #when navigating away the intersiteObj is saved in javascript onunload
        self._navToChapter("1", "1.2")

        #so it should now contain the scores from the whole page (7) we visited and
        #the exercise we entered should also have points
        scores = self.getIntersiteObj()['scores']
        self.assertEquals(len(scores), 7)

        found = False
        for score in scores:
            if score['id'] == 'QFELD_1.2.2.QF602':
                found = True
                self.assertEquals(score['maxpoints'], score['points'])

        self.assertTrue(found)

    def getIntersiteObj(self):
        intersite_obj_string = self.driver.execute_script('return window.localStorage.getItem("isobj_MFR-TUB")')
        return json.loads(intersite_obj_string)
