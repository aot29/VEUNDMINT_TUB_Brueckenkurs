import os
import unittest
from test.systemtests.SeleniumTest import SeleniumTest
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from settings import BASE_DIR

@unittest.skipIf(not os.path.isfile(
    os.path.join(BASE_DIR, 'public', 'scorm2004testwrap.htm')),
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


    def testGetStudentAttributes(self):
        """
        Test some get Methods of the scormBridge.js
        """
        self._navToChapter("2")

        studentName = self.driver.execute_script('return scormBridge.getStudentName()')
        self.assertEquals("Claude's SCORM 2004 Test Wrapper", studentName)

        studentId = self.driver.execute_script('return scormBridge.getStudentId()')
        self.assertEquals("123456-1223435-112334<trick>4-1133-5[345ae/+.{/]", studentId)
