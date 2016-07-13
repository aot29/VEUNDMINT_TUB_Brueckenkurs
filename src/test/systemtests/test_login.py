# -*- coding: UTF-8 -*-
'''
Created on Jun 21, 2016

@author: alvaro
'''
import unittest
from test.systemtests.AbstractSystemTest import AbstractSystemTest

class Test( AbstractSystemTest ):
    '''
    Tests for the login page
    '''

    def setUp(self):
        AbstractSystemTest.setUp(self)
        # navigate to login page
        self._openStartPage()
        self.browser.find_element_by_id( 'loginbutton' ).click()


    def testName(self):
        '''
        Are constraints on new usernames being checked upon registration?
        Check if image is right and login button is displayed when necessary.
        '''
        inputEl = self.browser.find_element_by_id( 'USER_UNAME' )
        imgEl = self.browser.find_element_by_id( "checkuserimg" ) # the icon next to the input field
        btnPath = "//div[@class='usercreatereply']//child::button" # path to the create-user button (present when constraints are met)

        # nothing in field
        inputEl.clear()
        self.browser.execute_script( "usercheck()" )
        self.assertTrue( "questionmark" in imgEl.get_attribute( "src" ), "Answer is displaying the wrong image" )
        self.assertFalse( len( self.browser.find_elements_by_xpath( btnPath ) ) )

        # Loginname too short
        inputEl.clear()
        inputEl.send_keys( "abcde" )
        self.browser.execute_script( "usercheck()" ) # Just changing the field doesn't trigger the javascript
        self.assertTrue( "false" in imgEl.get_attribute( "src" ), "Answer is displaying the wrong image" )
        self.assertFalse( len( self.browser.find_elements_by_xpath( btnPath ) ), "Button displayed when it shouldn't" )

        # Loginname invalid chars
        inputEl.clear()
        inputEl.send_keys( u'abcdeä' )
        self.browser.execute_script( "usercheck()" )
        self.assertTrue( "false" in imgEl.get_attribute( "src" ), "Answer is displaying the wrong image" )
        self.assertFalse( len( self.browser.find_elements_by_xpath( btnPath ) ), "Button displayed when it shouldn't" )

        # Loginname too long
        inputEl.clear()
        inputEl.send_keys( 'abcdefghijklmnopqrstuvwxyz' )
        self.browser.execute_script( "usercheck()" )
        self.assertTrue( "false" in imgEl.get_attribute( "src" ), "Answer is displaying the wrong image" )
        self.assertFalse( len( self.browser.find_elements_by_xpath( btnPath ) ), "Button displayed when it shouldn't" )

        # Loginname OK
        inputEl.clear()
        inputEl.send_keys( "ab12_-+" )
        self.browser.execute_script( "usercheck()" )
        self.assertTrue( "right" in imgEl.get_attribute( "src" ), "Answer is displaying the wrong image" )
        self.assertTrue( len( self.browser.find_elements_by_xpath( btnPath ) ), "Button not displayed when it should" )


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
