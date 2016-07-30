import unittest
import os
from plugins.VEUNDMINT.tcontent import TContent
from plugins.VEUNDMINT.PageTUB import PageTUB


class test_PageTUB(unittest.TestCase):
	tplPath = os.environ['PYTHONPATH'] + "/src/templates_xslt"
	

	def setUp(self):
		self.tc = TContent()
		self.tc.title = "Test Title"
		self.lang = "en"


	def test_generateHTML(self):
		# generate HTML element using the tc mock-up
		page = PageTUB( self.tplPath, self.lang )
		page.generateHTML( self.tc )
		#print(self.tc.html)
		# HTML is stored in tc.html
		self.assertTrue( "<title>%s</title>" % self.tc.title in self.tc.html, "Title not found in HTML" )		
		#encoding
		self.assertTrue( "utf-8" in self.tc.html, "Wrong or missing encoding" )
		# language
		self.assertTrue( '<html lang="%s">' % self.lang in self.tc.html, "Wrong or missing language code" )
		# at least one stylesheet
		self.assertTrue( '<link rel="stylesheet" type="text/css"' in self.tc.html, "Missing stylesheets" )
		# at least one js
		self.assertTrue( 'type="text/javascript"></script>' in self.tc.html, "Missing external javascript" )
		# MathJax got loaded
		self.assertTrue( 'https://cdn.mathjax.org/mathjax/2.6-latest/MathJax.js' in self.tc.html, "Missing external MathJax" )
		


	def test_createPageXML(self):
		# create an XML element using the tc mock-up
		page = PageTUB( self.tplPath, self.lang )
		xml = page.createPageXML( self.tc )

		self.assertEqual( self.tc.title, xml.xpath('/page/title')[0].text, "Title is wrong" )
		self.assertEqual( self.lang, xml.xpath('/page/@lang')[0], "Language code is wrong" )
