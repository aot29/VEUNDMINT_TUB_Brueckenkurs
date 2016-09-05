'''
Created on Aug 22, 2016

@author: ortiz
'''
import unittest
from tex2x.renderers.AbstractRenderer import AbstractXmlRenderer
from test.systemtests.SeleniumTest import SeleniumTest

class SpecialPages( SeleniumTest ):
	"""
	Special pages are: search, data, login, logout, config
	The actual list is in: AbstractXmlRenderer.specialPagesUXID
	"""

	def setUp(self):
		SeleniumTest.setUp(self)
		self.pageNames = AbstractXmlRenderer.specialPagesUXID
		self.lang = 'de'



	def testSpecialPagePresent(self):
		"""
		Special pages should be available and have the correct localized title
		"""
		for i18nKey,pageName in self.pageNames.items():
			url = "%s/html/%s/%s.html" % ( self.start_url, self.lang, pageName )
			self.driver.get( url )
			content = self.getElement( 'pageContents' )
			self.assertTrue( content, "No content found for %s" % url)


	@unittest.skip("Login button needs an ID")
	def testSpecialPageReachable(self):
		"""
		Links to special pages should work from any level
		"""
		self._navToChapter("1", no_mathjax=True)
		self.getElement( 'loginButtonNavBar' ).click()
		url = self.driver.current_url
		self.assertTrue( self.pageNames['VBKM_MISCLOGIN'] in url, "Could not open page %s" % url )

		self._navToChapter("1", "1.2", no_mathjax=True)
		self.getElement( 'loginButtonNavBar' ).click()
		url = self.driver.current_url
		self.assertTrue( self.pageNames['VBKM_MISCLOGIN'] in url, "Could not open page %s" % url )


if __name__ == "__main__":
	#import sys;sys.argv = ['', 'Test.testSpecialPagePresent']
	unittest.main()