'''
Created on Sep 15, 2016

@author: ortiz
'''
import unittest
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from test.quicktests.QuickTest import QuickTest

class Test(QuickTest):

	def testLocalizedTextsPresent(self):
		url = "http://localhost:3000/html/de/sectionx1.1.0.html"
		self.driver.get( url )
		pageContents = WebDriverWait(self.driver, 30).until(EC.presence_of_element_located((By.ID, "pageContents")))
		pageText = pageContents.get_attribute('innerHTML')
		
		# test that at least some of the localized strings are there 
		self.assertTrue( "Weiterführende Inhalte" in pageText )
		# test that math content gets localized
		self.assertTrue( '<math xmlns="http://www.w3.org/1998/Math/MathML">' in pageText )
		# test that values containing macros get expanded
		self.assertTrue( '<tt>' in pageText )


if __name__ == "__main__":
	#import sys;sys.argv = ['', 'Test.testName']
	unittest.main()