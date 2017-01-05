import unittest
import os
from settings import BASE_URL, BASE_DIR
from selenium import webdriver
#import configparser as ConfigParser
import json
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from tex2x.Settings import ve_settings as settings
from tex2x.AbstractRenderer import AbstractXmlRenderer

class SeleniumTest(unittest.TestCase):
	# Most xpaths assume you are starting from the root element (e.g. using self.driver).
	# use with self.getElement('key')
	# To retrieve an element by id, e.g. from the content of the page,
	# it's not necessary to add it here to use self.getElement('id')
	xpath = {
		'pageContents' : "//div[@id='pageContents']",
		'pageTitle' : "//h1",
		'launchButton' : "//div[@id='pageContents']/a[@type='button']",
		'launchButtonTextElement' : "//div[@id='pageContents']/a[@type='button']/span[@data-i18n]",
		'TESTRESET' : "//button[@id='TESTRESET']",
		'TESTFINISH' : "//button[@id='TESTFINISH']",
		'TESTEVAL' : "//p[@id='TESTEVAL']",
		'lastTableCell' : "//div[@id='pageContents']//table//tr[last()]/td[last()]",
		'navbarTop' : "//div[@id='navbarTop']",
		'numerator' : "//div[@id='MHint1']/descendant::span[@class='mjx-numerator'][last()]",
		'denominator' : "//div[@id='MHint1']/descendant::span[@class='mjx-denominator'][last()]",
		'tocTitle' : "//div[@id='toc']/h3",
		'toc' : "//div[@id='toc']",
		'legend' : "//div[@id='legend']",
		'registrationButton' : "//a[@id='newUserButton']",
		'signupButton' : "//a[@href='../en/signup.html']",
		'loginButtonNavBar' : "//a[@href='../de/login.html']",
		'loginButton' : "//button[@onclick='intersite.userlogin_click();']"
	}

	#
	# Each test forks its own process, so needs its own driver. Otherwise they get in the way of each other and cause random errors.
	# Todo: Some stuff can go in setUpClass (but not the driver)
	#
	def setUp(self):
		self.driver = webdriver.PhantomJS(executable_path=BASE_DIR + '/node_modules/phantomjs/lib/phantom/bin/phantomjs', service_log_path=BASE_DIR + '/ghostdriver.log', service_args=['--ignore-ssl-errors=true'])

		#self.driver = webdriver.Firefox()
		self.driver.set_window_size(1120, 550)
		self.driver.set_page_load_timeout(30)

		# load locale file
		localeFile = None
		try:
			# load DE locale by default
			i18nPath = os.path.expanduser( os.path.join( BASE_DIR, "src/files/i18n/%s.json" % 'de' ) )
			localeFile = open( i18nPath )
			self.locale = json.load( localeFile )

		finally:
			if localeFile:
				localeFile.close()

		# set URL's

		#
		# to change the base URL, do something like
		# export BASE_URL=http://localhost:3000/
		#
		self.start_url = os.getenv('BASE_URL', BASE_URL)


	def tearDown(self):
		self.driver.close()
		self.driver.quit()

	def getElement( self, key ):
		"""
		Method has 2 usages:
		1. Retrieve a DOM element from the navigation etc.
		In this case, the DOM element is retrieved by looking up the key up in the array of xpaths.

		2. Retrieve a DOM element from the page content. The element is retrieved by id

		Use this instead of self.driver.find_element_by_xpath('...') or self.driver.find_element_by_id( '...' )

		@param key - String case 1: key in the self.xpath dict or case 2: element id
		"""
		if key in self.xpath.keys():
			#element = self.driver.find_element_by_xpath( self.xpath[ key ] )
			element = WebDriverWait(self.driver, 30).until(EC.presence_of_element_located((By.XPATH, self.xpath[ key ])))

		else:
			#element = self.driver.find_element_by_id( key )
			element = WebDriverWait(self.driver, 30).until(EC.presence_of_element_located((By.ID, key)))

		return element


	def isBootstrap(self):
		"""
		Is the bootstrap version being tested?
		"""
		return settings.bootstrap


	def _openStartPage(self, no_mathjax=False):
		'''
		Opens the start page of the course (the choose language page) in the webdriver Used to test navigation elements and toc.
		'''
		# 		print ('_openStartPage with %s ' % BASE_URL)
		#
		# 		if (self.driver.current_url != BASE_URL):
		# 		# get the url from environment, otherwise from settings
		start_url = os.getenv('BASE_URL', BASE_URL)

		self._loadPage( start_url )



	#TODO does this work as expected ? e.g. _navToChapter("1", "1.1")
	def _navToChapter(self, chapter, section=None, lang = "de", no_mathjax=False):
		'''
		Navigate to chapter specified by name.
		@param chapter: (required) a STRING specifying the chapter, e.g. "1" will open chapter 1
		@param section: (optional) a STRING specifying the section, e.g. "1.2" will open section 1.2
		@param lang: (optional) a STRING specifying the language code, e.g. "de" or "en"
		'''
		# Open the start page
		#self._openStartPage()
		#self._chooseLanguageVersion( lang )

		if section is None:
			# Open chapter
			url = "%s/html/%s/sectionx%s.1.0.html" % ( self.start_url, lang, chapter )

		else:
			# Open section
			url = "%s/html/%s/%s.%s/modstart.html" % ( self.start_url, lang, chapter, section )

		self._loadPage( url )
		return url


	def _navToSpecialPage(self, key, lang="de"):
		if key in AbstractXmlRenderer.specialPagesUXID.keys():
			url = "%s/html/%s/%s.html" % ( self.start_url, lang, AbstractXmlRenderer.specialPagesUXID[key] )

		else:
			print( "Key must be in AbstractXmlRenderer.specialPagesUXID" )

		self._loadPage( url )


	def _chooseLanguageVersion(self, lang):
		'''
		Navigate to the specified language version of the website
		@param languagecode: (required) a STRING specifying the language code, e.g. "de" or "en"
		'''
		url = "%s/html/%s/" % ( self.start_url, lang )
		self._loadPage( url )


	def _isLoginDisabled(self):
		"""
		1 if login has been disabled in Option.py
		"""
		return (settings.disableLogin == 1)


	def _loadPage(self, url):
		"""
		Try to load a URL without causing errors or timeouts.

		@param url - the url to load
		"""
		self.driver.get( url )
		WebDriverWait(self.driver, 10).until(EC.presence_of_element_located((By.ID, "pageContents")))


	def getUrlStatusCode(url):
		import urllib.request
		try:
			r = urllib.request.urlopen(url)
			return r.getcode()
		except:
			return 404
		finally:
			r.close()
