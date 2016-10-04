import os
import unittest
import urllib
from test.systemtests.SeleniumTest import SeleniumTest
from test.systemtests.SeleniumTest import getUrlStatusCode
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from settings import BASE_DIR, scorm2004testurl

@unittest.skipIf(getUrlStatusCode(scorm2004testurl) is not 200,
    "Will not run this SCORM test as the scorm2004testwrap.htm is not in the \
    '/public' directory. Run 'gulp scormTest' first.")
class ScormTest( SeleniumTest ):
    """
    Tests for SCORM related functions
    """

    def setUp(self):
        SeleniumTest.setUp(self)
        self.scorm_start_url_prefix = self.start_url + '/scorm2004testwrap.htm?sco='

    def _loadPage(self, url, scormVersion="2004"):
        """
        Overwrite the parent method to load the page in the wrapped scorm env

        @param url - the url to load
        @param scormVersion - currently only "2004" is supported but there might be a wrapper for 1.2
        somewhere around TODO
        """
        url = url.replace(self.start_url,'')
        self.driver.get( '%s%s' % (self.scorm_start_url_prefix, url) )

        #wait for the iframe
        WebDriverWait(self.driver, 10).until(EC.frame_to_be_available_and_switch_to_it((By.ID, "wndSCORM2004Stage")))
        #and wait for all scripts loaded
        WebDriverWait(self.driver, 10).until(EC.presence_of_element_located((By.ID, "veundmint_ready")))

    def testScormUrlsWorking(self):
        """
        Test that the new _loadPage method works as expected
        """
        correctUrl = SeleniumTest._navToChapter(self, "3", "1.1")

        self._navToChapter("3", "1.1")

        self.assertEquals(self.driver.current_url, correctUrl)

    def testIsScormEnv(self):
        """
        Test that only succeeds in scorm environment
        """
        self._navToChapter("1")

        isScormEnv = self.driver.execute_script('return scormBridge.isScormEnv();')

        self.assertTrue(isScormEnv)

    def testScormBridgeGetSet(self):
        """
        Tests that Attributes can be set and get in ScormBridge
        """
        self._navToChapter("3")

        setSuccessful = self.driver.execute_script('return scormBridge.set("cmi.score.max", 42)')
        self.assertTrue(setSuccessful)

        getAgain = self.driver.execute_script('return scormBridge.get("cmi.score.max")')
        self.assertEquals(getAgain, '42')

    def testScormBridgeUpdateCourseScores(self):
        """
        Test if updateCourseScores method of scorm Bridge is successfully saving
        data. Called manually and once on page reload.
        """
        self._navToChapter("3")

        scoreObj = "[]"

        # set all scores to 0
        result = self.driver.execute_script('return scormBridge.updateCourseScore(%s)' % scoreObj)

        self.assertTrue(result)
        self.assertEquals(self.driver.execute_script('return scormBridge.gracefullyGet("cmi.core.score.max")'), '0')
        self.assertEquals(self.driver.execute_script('return scormBridge.gracefullyGet("cmi.core.score.min")'), '0')
        self.assertEquals(self.driver.execute_script('return scormBridge.gracefullyGet("cmi.core.score.raw")'), '0')

        # now set them to real values, only intest.scores should be taken into account
        scoreObj = "[{'maxpoints':10,'points':3,'intest':true},{'maxpoints':11,'points':4,'intest':true},{'maxpoints':100,'points':42,'intest':false}]"
        result = self.driver.execute_script('return scormBridge.updateCourseScore(%s)' % scoreObj)

        self.assertEquals(self.driver.execute_script('return scormBridge.gracefullyGet("cmi.core.score.max")'), '21')
        self.assertEquals(self.driver.execute_script('return scormBridge.gracefullyGet("cmi.core.score.min")'), '0')
        self.assertEquals(self.driver.execute_script('return scormBridge.gracefullyGet("cmi.core.score.raw")'), '7')

        # now test that it is also working when user answers an exercise of an 'Abschlusstest' from one chapter
        correct_answer = "{0;2}"
        self._navToChapter("1", "2.3")
        questionInput = self.getElement('QFELD_2.3.2.QF3')
        questionInput.clear()
        questionInput.send_keys(correct_answer)
        self.assertEquals(questionInput.get_attribute('value'), correct_answer)

        self.getElement('TESTFINISH').click()

        scoreRawAfterTest = self.driver.execute_script('return scormBridge.gracefullyGet("cmi.core.score.raw")')

        self.assertEquals(scoreRawAfterTest, '4')


    def testGetStudentAttributes(self):
        """
        Test some get Methods of the scormBridge.js
        """
        self._navToChapter("2")

        studentName = self.driver.execute_script('return scormBridge.getStudentName()')
        self.assertEquals("Claude's SCORM 2004 Test Wrapper", studentName)

        studentId = self.driver.execute_script('return scormBridge.getStudentId()')
        self.assertEquals("123456-1223435-112334<trick>4-1133-5[345ae/+.{/]", studentId)


    def testScormUrlAvailable(self):
        print (getUrlStatusCode(scorm2004testurl))
