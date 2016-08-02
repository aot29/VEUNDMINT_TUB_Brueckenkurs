import unittest
import os
from plugins.VEUNDMINT.tcontent import TContent
from plugins.VEUNDMINT.PageTUB import PageTUB
from tex2x.Settings import settings


class test_PageTUB(unittest.TestCase):
	tplPath = os.path.join(settings.BASE_DIR, "src/templates_xslt")
	

	def setUp(self):
		self.lang = "en"
		
		# Setup a tc object for testing
		self.tc = TContent()
		self.tc.title = "Test Title"
		self.tc.caption = "Test"
		self.tc.fullname = "html/test"
		self.tc.content = "Some content."
			
		# add a parent
		self.tc.parent = TContent()
		self.tc.parent.children.append( self.tc )
		
		#add some siblings
		sibling1 = TContent()
		sibling1.caption = "Sibling 1"
		sibling1.fullname = "html/section1"
		sibling2 = TContent()
		sibling2.caption = "Sibling 2"
		sibling2.fullname = "html/section2"
		self.tc.parent.children.append( sibling1 )		
		self.tc.parent.children.append( sibling2 )
		
		#add some children
		child1 = TContent()
		child1.title = "Child 1"
		child1.fullname = "html/1/xcontent1.html"
		child2 = TContent()
		child2.title = "Child 2"
		child2.fullname = "html/2/xcontent2.html"
		self.tc.children.append( child1 )
		self.tc.children.append( child2 )


	def test_createPageXML(self):
		'''
		Test that the XML contains all required elements and attributes
		'''
		# create an XML element using the tc mock-up
		page = PageTUB( self.tplPath, self.lang )
		xml = page.generateXML( self.tc )

		#Title
		self.assertEqual( self.tc.title, xml.xpath('/page/title')[0].text, "Title is wrong in XML" )
		#Lang
		self.assertEqual( self.lang, xml.xpath('/page/@lang')[0], "Language code is wrong in XML" )
		# Content
		self.assertEqual( self.tc.content, xml.xpath('/page/content')[0].text, "Content is wrong in XML" )
		#TOC (there are 3 siblings in the test tc object instantiated in the setup of this test)
		self.assertTrue( xml.xpath('/page/toc'), "TOC is missing in XML" )
		self.assertEqual( 3, len( xml.xpath('/page/toc/entries/entry') ), "Expecting 2 entries in TOC in XML" )


	def test_generateHTML(self):
		'''
		Test that everything gets transformed to HTML.
		'''
		# generate HTML element using the tc mock-up
		page = PageTUB( self.tplPath, self.lang )
		page.generateHTML( self.tc )
		#print(self.tc.html)
		# HTML is stored in tc.html
		self.assertTrue( "<title>%s</title>" % self.tc.title in self.tc.html, "Title not found in HTML" )		
		#encoding
		self.assertTrue( "utf-8" in self.tc.html, "Wrong or missing encoding in HTML" )
		# language
		self.assertTrue( 'html lang="%s"' % self.lang in self.tc.html, "Wrong or missing language code in HTML" )
		# at least one stylesheet
		self.assertTrue( 'link rel="stylesheet" type="text/css"' in self.tc.html, "Missing stylesheets in HTML" )
		# at least one js
		self.assertTrue( 'type="text/javascript"' in self.tc.html, "Missing external javascript in HTML" )
		# MathJax got loaded
		self.assertTrue( 'https://cdn.mathjax.org/mathjax/2.6-latest/MathJax.js' in self.tc.html, "Missing external MathJax in HTML" )
		# i18n points to the right locale
		self.assertTrue( "$.i18n().load( {%s" % self.lang in self.tc.html, "i18n is missing or points to the wrong locale in HTML" )
		# navbar
		self.assertTrue( 'id="navbarTop"' in self.tc.html, "Navbar is missing in HTML" )		
		#toc
		self.assertTrue( 'id="toc"' in self.tc.html, "TOC is missing in HTML" )
		# Siblings in TOC (basePath is expected to be ../, as set in page.xslt)
		siblings = self.tc.parent.children
		for i in range( len( siblings ) ):
				sibling = siblings[i]
				self.assertTrue( 'href="../%s"' % sibling.fullname in self.tc.html, "TOC entry is missing in HTML. Expected %s" % sibling.fullname )				
		#legend
		self.assertTrue( 'id="legend"' in self.tc.html, "Legend is missing in HTML" )		
		# content
		self.assertTrue( self.tc.content in self.tc.html, "Content is missing in HTML" )
		
