# -*- coding: UTF-8 -*-
'''
Created on Jun 21, 2016

@author: alvaro
'''
import unittest
from test.systemtests.SeleniumTest import SeleniumTest

class TestLogin( SeleniumTest ):
    '''
    Tests for the login page
    '''
    registrationFieldIds = {'USER_VNAME', 'USER_SNAME', 'USER_EMAIL', 'USER_SGANG', 'USER_UNI', 'USER_UNAME'}
    '''
    Testuser name and password
    '''
    TestUName = 'TestUser12345'
    TestUPassword = 'xxxxx'

    def setUp(self):
        SeleniumTest.setUp(self)
        # navigate to EN login page
        self._chooseLanguageVersion( 'en' )
        # Actually, this is the register button, but its ID is loginbutton
        self.getElement( 'loginbutton' ).click()


    def testCheckRegistrationForm(self):
        '''
        Check that all fields are there, and that they are empty for an unregistered user
        '''
        for id in self.registrationFieldIds:
            self._checkPresentAndEmpty( id )


    def testName(self):
        '''
        Are constraints on new usernames being checked upon registration?
        Check if image is right and login button is displayed when necessary.
        '''
        inputEl = self.driver.find_element_by_id( 'USER_UNAME' )
        imgEl = self.driver.find_element_by_id( "checkuserimg" ) # the icon next to the input field

        # nothing in field
        inputEl.clear()
        self.driver.execute_script( "usercheck()" )
        self.assertTrue( "questionmark" in imgEl.get_attribute( "src" ), "Answer is displaying the wrong image" )
        self.assertFalse( self._getRegistrationButton() )

        # Loginname too short
        inputEl.clear()
        inputEl.send_keys( "abcde" )
        self.driver.execute_script( "usercheck()" ) # Just changing the field doesn't trigger the javascript
        self.assertTrue( "false" in imgEl.get_attribute( "src" ), "Answer is displaying the wrong image" )
        self.assertFalse( self._getRegistrationButton(), "Button displayed when it shouldn't" )

        # Loginname invalid chars
        inputEl.clear()
        inputEl.send_keys( u'abcdeä' )
        self.driver.execute_script( "usercheck()" )
        self.assertTrue( "false" in imgEl.get_attribute( "src" ), "Answer is displaying the wrong image" )
        self.assertFalse( self._getRegistrationButton(), "Button displayed when it shouldn't" )

        # Loginname too long
        inputEl.clear()
        inputEl.send_keys( 'abcdefghijklmnopqrstuvwxyz' )
        self.driver.execute_script( "usercheck()" )
        self.assertTrue( "false" in imgEl.get_attribute( "src" ), "Answer is displaying the wrong image" )
        self.assertFalse( self._getRegistrationButton(), "Button displayed when it shouldn't" )

        # Loginname OK
        inputEl.clear()
        inputEl.send_keys( "ab12_-+" )
        self.driver.execute_script( "usercheck()" )
        self.assertTrue( "right" in imgEl.get_attribute( "src" ), "Answer is displaying the wrong image" )
        self.assertTrue( self._getRegistrationButton(), "Button not displayed when it should" )


    @unittest.skip("needs more attention")
    def testRegister(self):
        '''
        Create a test account
        '''
        # Input phony values for the test user
        self.driver.find_element_by_id( 'USER_VNAME' ).send_keys( 'VNAME Test' )
        self.driver.find_element_by_id( 'USER_SNAME' ).send_keys( 'SNAME Test' )
        self.driver.find_element_by_id( 'USER_EMAIL' ).send_keys( 'EMAIL Test' )
        self.driver.find_element_by_id( 'USER_SGANG' ).send_keys( 'SGANG Test' )
        self.driver.find_element_by_id( 'USER_UNI' ).send_keys( 'UNI Test' )
        self.driver.find_element_by_id( 'USER_UNAME' ).send_keys( self.TestUName )
        # The registration button should appear
        self.assertTrue( self._getRegistrationButton(), "Registration button not displayed when it should" )
        # Click on the registration button

        # There's an error when I try this: Invalid Command Method. Perhaps unsupported by the PhantomJS driver?
        # A simple solution would be to remove the prompt, which doesn't add to the user experience anyway.

        self._getRegistrationButton().click()
        passPrompt = self.driver.switch_to.alert;
        passPrompt.send_keys( self.TestUPassword )


    def _checkPresentAndEmpty(self, inputId):
        '''
        Check if an input field is present and is empty
        @param inputName String the id of an input field
        '''
        self.assertTrue( self.getElement( inputId ) )
        self.assertFalse( self.getElement( inputId ).get_attribute("value") )


    def _getRegistrationButton(self):
        '''
        @return the registration button element if it is present on the page or empty list.
        '''
        #btnPath = "//div[@class='usercreatereply']//child::button" # path to the create-user button (present when constraints are met)
        # get a list of elements, otherwise an exception is thrown when no element is found
        elList = self.driver.find_elements_by_xpath( self.xpath['bootstrap']['registrationButton'] )
        resp = False
        if len( elList ) != 0 : resp = elList[0]
        return resp


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
