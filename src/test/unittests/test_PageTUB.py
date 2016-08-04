import unittest
import os
from lxml import etree

from plugins.VEUNDMINT.tcontent import TContent
from plugins.VEUNDMINT.TocRenderer import TocRenderer
from plugins.VEUNDMINT.PageTUB import PageTUB
from tex2x.Settings import settings

from test.unittests.AbstractRendererTestCase import AbstractRendererTestCase
from tex2x.renderers.AbstractRenderer import *

class test_PageTUB(AbstractRendererTestCase):
	
	def setUp(self):
		AbstractRendererTestCase.setUp(self)
		
		tocRenderer = TocRenderer( self.tplPath, self.lang )
		self.page = PageTUB( self.tplPath, self.lang, tocRenderer )
		# create an XML element using the tc mock-up 
		# (only for testing, i.r.l. you can skip this step and do page.generateHTML directly)
		basePath = self.page.getBasePath( self.tc )
		self.xml = self.page.generateXML( self.tc, basePath )
		# generate HTML element using the tc mock-up
		self.page.generateHTML( self.tc )


	def test_generateXML(self):
		'''
		Test that the XML contains all required elements and attributes
		'''
		#Title
		self.assertEqual( self.tc.title, self.xml.xpath('/page/title')[0].text, "Title is wrong in XML" )
		#Lang
		self.assertEqual( self.lang, self.xml.xpath('/page/@lang')[0], "Language code is wrong in XML" )
		# Content
		self.assertEqual( self.tc.content, self.xml.xpath('/page/content')[0].text, "Content is wrong in XML" )
		

	def test_generateHTML(self):
		'''
		Test that everything gets transformed to HTML.
		'''
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
		
		#
		# TOC
		#
		
		self.assertTrue( 'id="toc"' in self.tc.html, "TOC is missing in HTML" )

		# Siblings in TOC (basePath is expected to be ../, as set in page.xslt)
		siblings = self.tc.parent.children
		for i in range( len( siblings ) ):
				sibling = siblings[i]

				# TOC entry captions present
				self.assertTrue( sibling.caption in self.tc.html, "TOC entry is missing in HTML. Expected %s" % sibling.caption )

				# TOC entry links present
				if sibling.myid != self.tc.myid:
					self.assertTrue( 'href="../%s"' % sibling.fullname in self.tc.html, "TOC entry is missing in HTML. Expected %s" % sibling.fullname )

				else:
					# one sibling is selected
					self.assertTrue( 'href="#collapse"' in self.tc.html, "Selected TOC entry is missing in HTML. Expected #collapse" )
					
		# children and grand children
		children = self.tc.children
		for child in children:
			self.assertTrue( child.caption in self.tc.html )
			grandChildren = child.children
			for gc in grandChildren:
				self.assertTrue( gc.caption in self.tc.html )
				
		
		#legend
		self.assertTrue( 'id="legend"' in self.tc.html, "Legend is missing in HTML" )		
		
		
	def testGetBasePath(self):
		"""
		Test that the base path corresponds to the entry level
		"""
		tc = TContent()
		self.tc.level = MODULE_LEVEL
		self.assertEquals("..", self.page.getBasePath( self.tc ))
		self.tc.level = SECTION_LEVEL
		self.assertEquals("../..", self.page.getBasePath( self.tc ))
		self.tc.level = SUBSECTION_LEVEL
		self.assertEquals("../..", self.page.getBasePath( self.tc ))
		

		