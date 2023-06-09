# -*- coding: UTF-8 -*-
'''
Created on Jun 21, 2016

@author: alvaro
'''
import unittest
from test.systemtests.SeleniumTest import SeleniumTest
import time

class TestLogin( SeleniumTest ):
	'''
	Tests for the login page
	'''
	registrationFieldIds = {'USER_VNAME', 'USER_SNAME', 'USER_EMAIL', 'USER_SGANG', 'USER_UNI', 'USER_UNAME'}
	myAccountFieldIds = {'USER_VNAME', 'USER_SNAME', 'USER_EMAIL', 'USER_SGANG', 'USER_UNI'}
	loginFieldIds = {'OUSER_LOGIN', 'OUSER_PW'}
	'''
	Testuser name and password
	'''
	TestUName = 'selenium'
	TestUPassword = 'XL3OAph'



	def setUp(self):
		# skip all tests if login is disabled
		if self._isLoginDisabled():
			raise unittest.SkipTest( "Test skipped because login is disabled in options" )
		SeleniumTest.setUp(self)
		# navigate to EN login page
		self._chooseLanguageVersion( 'en' )



	def testCheckRegistrationForm(self):
		'''
		Check that all fields are there, and that they are empty for an unregistered user
		'''
		# logout just to be sure
		self._logout()
		self._navToSpecialPage( 'VBKM_MISCSETTINGS' )

		for field in self.registrationFieldIds:
			#self._checkPresentAndEmpty( field )
			self.assertTrue( self.getElement( field ) )
			self.assertFalse( self.getElement( field ).get_attribute("value"), "Field %s is not empty when it should" % field )


	@unittest.skip("Test needs more attention after js refactoring")
	def testName(self):
		'''
		Are constraints on new usernames being checked upon registration?
		Check if image is right and login button is displayed when necessary.
		'''
		self._navToSpecialPage( 'VBKM_MISCSETTINGS' )

		inputEl = self.getElement( 'USER_UNAME' )
		imgEl = self.getElement( "checkuserimg" ) # the icon next to the input field

		# nothing in field
		inputEl.clear()
		self.driver.execute_script( "intersite.usercheck()" )
		self.assertTrue( "questionmark" in imgEl.get_attribute( "src" ), "Answer is displaying the wrong image" )
		self.assertFalse( self._isRegistrationEnabled() )

		# Loginname too short
		inputEl.clear()
		inputEl.send_keys( "abcde" )
		self.driver.execute_script( "intersite.usercheck()" ) # Just changing the field doesn't trigger the javascript
		self.assertTrue( "false" in imgEl.get_attribute( "src" ), "Answer is displaying the wrong image" )
		self.assertFalse( self._isRegistrationEnabled(), "Button displayed when it shouldn't" )

		# Loginname invalid chars
		inputEl.clear()
		inputEl.send_keys( u'abcdeä' )
		self.driver.execute_script( "intersite.usercheck()" )
		self.assertTrue( "false" in imgEl.get_attribute( "src" ), "Answer is displaying the wrong image" )
		self.assertFalse( self._isRegistrationEnabled(), "Button displayed when it shouldn't" )

		# Loginname too long
		inputEl.clear()
		inputEl.send_keys( 'abcdefghijklmnopqrstuvwxyz' )
		self.driver.execute_script( "intersite.usercheck()" )
		self.assertTrue( "false" in imgEl.get_attribute( "src" ), "Answer is displaying the wrong image" )
		self.assertFalse( self._isRegistrationEnabled(), "Button displayed when it shouldn't" )

		# Loginname OK
		inputEl.clear()
		inputEl.send_keys( "ab12_-+" )
		self.driver.execute_script( "intersite.usercheck()" )
		self.assertTrue( "right" in imgEl.get_attribute( "src" ), "Answer is displaying the wrong image" )
		self.assertTrue( self._isRegistrationEnabled(), "Button not displayed when it should" )


	def _login(self):
		"""
		login, using the test user "selenium"
		"""
		self._navToSpecialPage( 'VBKM_MISCLOGIN' )
		usernameInput = self.getElement( 'OUSER_LOGIN' )
		usernameInput.send_keys( self.TestUName )
		passwordInput = self.getElement( 'OUSER_PW' )
		passwordInput.send_keys( self.TestUPassword )
		button = self.getElement('loginButton')
		button.click()

		# give the server a chance
		time.sleep(10)


	def _logout(self):
		self._navToSpecialPage( 'VBKM_MISCLOGOUT' )

		# give the server a chance
		time.sleep(10)

	@unittest.skip("Test needs more attention after js refactoring")
	def testLogin(self):
		'''
		Test if the test user can login.
		The test user needs to be registered manually for the test to succeed.
		User data is in the source code of this class.
		'''
		# logout just to be sure
		self._logout()

		#login, using the test user "selenium"
		self._login()

		# load the my account page and check the fields are not empty
		self._navToSpecialPage( 'VBKM_MISCSETTINGS' )
		for name in self.myAccountFieldIds:
			inputEl = self.getElement( name )
			self.assertTrue( inputEl.get_attribute("value"), "Field %s is empty" % name )

		# logout
		self._logout()

		# load the registration page and check the fields are empty after logout
		self._navToSpecialPage( 'VBKM_MISCSETTINGS' )
		for name in self.myAccountFieldIds:
			inputEl = self.getElement( name )
			self.assertFalse( inputEl.get_attribute("value"), "Field %s is not empty when it should" % name )



	@unittest.skip("Password pop-up is in the way")
	def testRegister(self):
		'''
		Create a test account
		'''
		# Actually, this is the register button, but its ID is loginbutton
		self.getElement( 'loginButton' ).click()

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


	def _isRegistrationEnabled(self):
		'''
		Checks that the registration button is enabled

		@return boolean
		'''
		button = self.getElement( 'registrationButton' )
		#print("Button classes %s" % button.get_attribute( 'class' ))
		return not 'disabled' in button.get_attribute( 'class' )


if __name__ == "__main__":
	#import sys;sys.argv = ['', 'Test.testName']
	unittest.main()
