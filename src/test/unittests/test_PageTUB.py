import unittest
import os
from plugins.VEUNDMINT.tcontent import TContent
from plugins.VEUNDMINT.PageTUB import PageTUB


class test_PageTUB(unittest.TestCase):
	tplPath = os.environ['PYTHONPATH'] + "/src/templates_xslt"
	

	def setUp(self):
		self.tc = TContent()
		self.tc.title = "Test Title"
		self.tc.content = "Some content."
		self.lang = "en"
		

	def test_createPageXML(self):
		'''
		Test that the XML contains all required elements and attributes
		'''
		# create an XML element using the tc mock-up
		page = PageTUB( self.tplPath, self.lang )
		xml = page.createPageXML( self.tc )

		self.assertEqual( self.tc.title, xml.xpath('/page/title')[0].text, "Title is wrong" )
		self.assertEqual( self.lang, xml.xpath('/page/@lang')[0], "Language code is wrong" )
		self.assertEqual( self.tc.content, xml.xpath('/page/content')[0].text, "Content is wrong" )
		
		
	def test_generateHTML(self):
		'''
		Test that everything gets transformed to HTML.
		'''
		# generate HTML element using the tc mock-up
		page = PageTUB( self.tplPath, self.lang )
		page.generateHTML( self.tc )
		print(self.tc.html)
		# HTML is stored in tc.html
		self.assertTrue( "<title>%s</title>" % self.tc.title in self.tc.html, "Title not found in HTML" )		
		#encoding
		self.assertTrue( "utf-8" in self.tc.html, "Wrong or missing encoding" )
		# language
		self.assertTrue( '<html lang="%s"' % self.lang in self.tc.html, "Wrong or missing language code" )
		# at least one stylesheet
		self.assertTrue( '<link rel="stylesheet" type="text/css"' in self.tc.html, "Missing stylesheets" )
		# at least one js
		self.assertTrue( 'type="text/javascript"' in self.tc.html, "Missing external javascript" )
		# MathJax got loaded
		self.assertTrue( 'https://cdn.mathjax.org/mathjax/2.6-latest/MathJax.js' in self.tc.html, "Missing external MathJax" )
		# i18n points to the right locale
		self.assertTrue( "$.i18n().load( {%s" % self.lang in self.tc.html, "i18n is missing or points to the wrong locale" )
		# content
		self.assertTrue( self.tc.content in self.tc.html, "Content is missing" )
