

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
		
		tocRenderer = TocRenderer()
		self.page = PageTUB( self.tplPath, self.lang, tocRenderer )
		# generate HTML element using the tc mock-up
		self.page.generateHTML( self.tc )


	def testEnhanceContent(self):
		'''
		HTML Content from examples, info and exercises gets transformed
		'''
		original = """<div class="exmprahmen">
		<b>Example 1.1.9</b> &nbsp;
		<br>The following expressions are terms:
		<ul>
		<li>x·(y+z)-1: for x=1, y=2, and z=0 one obtains, for example, the value 1.
		
		</li>
		<li>sin(α)+cos(α): for α= 0∘ and β= 0∘ one obtains, for example, the value 1 (for the calculation of sine and cosine refer to (VERWEIS)).
		
		</li>
		<li>1+2+3+4: no variables occur, however this is a term (which always gives the value 10).
		
		</li>
		<li>α+β 1+γ : for example, α=1, β=2, and γ=3 give the value 3 4 . But γ=-1 is not allowed.
		
		</li>
		<li>sin(π(x+1)): this term, for example, always gives the value zero, if x is substituted with an integer number.
		
		</li>
		<li>z: a single variable is also a term.
		
		</li>
		<li>1+2+3+…+(n-1)+n is a term, in which the variable n occurs in the term itself and defines its length as well.
		
		</li>
		</ul>
		</div>"""

		

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
				self.assertTrue( 'href="../%s"' % sibling.fullname in self.tc.html, "TOC entry is missing in HTML. Expected %s" % sibling.fullname )
					
		# children and grand children
		children = self.tc.children
		for child in children:
			self.assertTrue( child.caption in self.tc.html )
			grandChildren = child.children
			for gc in grandChildren:
				self.assertTrue( gc.caption in self.tc.html )
				
		
		#legend
		self.assertTrue( 'id="legend"' in self.tc.html, "Legend is missing in HTML" )		
		
		#tabs or lauch button (self.tc is a module overview page)
		self.assertTrue( 'btn btn-primary' in self.tc.html, "Launch button is missing in HTML" )
		self.assertFalse( 'nav nav-tabs' in self.tc.html, "Tabs are rendered when they shouldn't in HTML" )
		
		# questions
		self.assertTrue( 'CreateQuestionObj("LSFF3",1,"(3-x)*(x+1)","QFELD_1.3.5.QF1",4,"10;x;5;1",4,0,1);' in self.tc.html, "Missing question javascript" )
		
	
	def testPrevNextLInks(self):
		# Create the XML output for a page with left and right neighbors
		siblings = self.tc.children
		xml = self.page.generateXML( siblings[1] )
		self.assertTrue( len( siblings ) >= 3 )
		# add links to next and previous entries
		self.page._addPrevNextLinks(xml, siblings[1] )
		#print( etree.tostring( xml ) )
		self.assertEquals( siblings[2].fullname, xml.xpath('navNext/@href')[0], "Next page not found" )
		self.assertEquals( siblings[0].fullname, xml.xpath('navPrev/@href')[0], "Prev page not found" )


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
		

		