import unittest
import os
from lxml import etree

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
		self.tc.myid = 123
		self.tc.level = 2
		
		# add a parent
		self.tc.parent = TContent()
		self.tc.parent.children.append( self.tc )
		self.tc.parent.level = 1
		
		#add some siblings
		sibling1 = TContent()
		sibling1.caption = "Sibling 1"
		sibling1.fullname = "html/section1"
		sibling1.myid = 456 
		sibling1.level = 2
		sibling2 = TContent()
		sibling2.caption = "Sibling 2"
		sibling2.fullname = "html/section2"
		sibling2.myid = 789 
		sibling2.level = 2
		self.tc.parent.children.append( sibling1 )		
		self.tc.parent.children.append( sibling2 )
		
		#add some children
		child1 = TContent()
		child1.caption = "Child 1"
		child1.fullname = "html/1/xcontent1.html"
		child1.level = 3
		child2 = TContent()
		child2.caption = "Child 2"
		child2.fullname = "html/2/xcontent2.html"
		child2.level = 3
		self.tc.children.append( child1 )
		self.tc.children.append( child2 )

		#add some grand children
		child11 = TContent()
		child11.caption = "Child 11"
		child11.fullname = "html/11/xcontent11.html"
		child11.tocsymb = "status1"
		child11.level = 4
		child12 = TContent()
		child12.caption = "Child 12"
		child12.fullname = "html/12/xcontent12.html"
		child12.level = 4
		child21 = TContent()
		child21.caption = "Child 21"
		child21.fullname = "html/21/xcontent21.html"
		child21.level = 4
		child1.children.append( child11 )
		child1.children.append( child12 )
		child2.children.append( child21 )
		
		self.page = PageTUB( self.tplPath, self.lang )
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
	
	
	def test_generateTocXML(self):
		'''
		Test that the table of contents XML contains all required elements and attributes
		'''		
		#TOC (there are 3 siblings in the test tc object instantiated in the setup of this test)
		self.assertTrue( self.xml.xpath('/page/toc'), "TOC is missing in XML" )
		self.assertEqual( 3, len( self.xml.xpath('/page/toc/entries/entry') ), "Expecting 2 entries in TOC in XML" )
		
		
	def test_generateTocEntryXML(self):
		'''
		Test that each TOC entry XML contains all required elements and attributes
		'''		
		#get the selected entry
		selected = self.xml.xpath('/page/toc/entries/entry[@selected="True"]')[0]
		
		# one sibling is selected
		selectedCount = 0
		for sibling in self.xml.xpath('/page/toc/entries/entry'):
			if sibling.xpath( '@selected' )[0] == "True": selectedCount += 1
		self.assertEqual( 1, selectedCount )
		
		# selected entry has children
		self.assertEqual( 2, len( selected.xpath('children/entry') ), "Expecting 2 children in TOC in XML" )
		# selected entry has grand children
		self.assertEqual( 3, len( selected.xpath('children/entry/children/entry') ), "Expecting 3 grand children in selected element in XML" )
		
		# Check that levels are present
		self.assertEqual( 2, int( selected.xpath('@level')[0] ) )
		self.assertEqual( 3, int( selected.xpath('children/entry/@level')[0] ) )
		

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
					self.assertTrue( 'href="#collapse"' in self.tc.html, "Selected TOC entry is missing in HTML. Expected %s" % sibling.fullname )
					
		# children and grand children
		children = self.tc.children
		for child in children:
			self.assertTrue( child.caption in self.tc.html )
			grandChildren = child.children
			for gc in grandChildren:
				self.assertTrue( gc.caption in self.tc.html )
				
		
		#legend
		self.assertTrue( 'id="legend"' in self.tc.html, "Legend is missing in HTML" )		
		
		
	def testCorrectLinks(self):
		xml = etree.Element( 'page' )
		
		# correct these
		image = etree.Element( 'img' )
		image.set( 'href', 'source.png' )
		xml.append( image )
		entry = etree.Element( 'entry' )
		entry.set( 'href', 'entry.html' )
		xml.append( entry )
		internalLink = etree.Element( 'a' )
		internalLink.set( 'href', 'index.html' )
		xml.append( internalLink )
		
		# do not correct these
		externalLink = etree.Element( 'a' )
		externalLink.set( 'href', 'http://www.example.com' )
		xml.append( externalLink )
		mailto = etree.Element( 'a' )
		mailto.set( 'href', 'mailto: a@b.com' )
		xml.append( mailto )
		
		basePath = ".."
		self.page.correctLinks( xml, basePath )
		self.assertTrue( basePath in image.get( 'href' ), "Link correction failed for link %s" % image.get( 'href' ) )
		self.assertTrue( basePath in entry.get( 'href' ), "Link correction failed for link %s" % entry.get( 'href' ) )
		self.assertTrue( basePath in internalLink.get( 'href' ), "Link correction failed for link %s" % internalLink.get( 'href' ) )
		
		self.assertFalse( basePath in externalLink.get( 'href' ), "Link correction failed for link %s" % externalLink.get( 'href' ) )
		self.assertFalse( basePath in mailto.get( 'href' ), "Link correction failed for link %s" % mailto.get( 'href' ) )
		
		
		