'''
Created on Aug 4, 2016

@author: ortiz
'''
import unittest
from lxml import etree
from test.unittests.AbstractRendererTestCase import AbstractRendererTestCase
from tex2x.renderers.TocRenderer import TocRenderer
from tex2x.renderers.AbstractRenderer import *

class test_TocRenderer(AbstractRendererTestCase):
	
	def setUp(self):
		AbstractRendererTestCase.setUp(self)

		self.tocRenderer = TocRenderer()
		self.xml = self.tocRenderer.renderXML( self.tc )
	
	
	def  test_makeCaptionWithUmlaut(self):
		"""
		Check that umlaute and sz get converted, both UTF-8 and entity encoded
		"""
		# Umlaute as UTF-8 in the text
		self.tc.title = "äüöß"
		self.tc.caption = "Test"
		self.tc.level = SUBSECTION_LEVEL
		expected = "äüöß Test"
		self.assertEquals( expected, self.tocRenderer._makeCaption( self.tc ), "Wrong caption with umlaut" )
		
		# Umlaute as encoded as entities
		self.tc.title = "&#xE4;&#xFC;&#xF6;&#xDF;"
		self.tc.caption = "Test"
		self.tc.level = SUBSECTION_LEVEL
		expected = "äüöß Test"
		self.assertEquals( expected, self.tocRenderer._makeCaption( self.tc ), "Wrong caption with umlaut" )
		
	
	def  test_makeCaption(self):
		"""
		TOC captions and numbers correspond to their level
		"""

		# Module numbers start at the second digit of the caption
		# as the first digit is always 1, so 1.2 becomes 2
		self.tc.title = "Onlinebrückenkurs Mathematik Abschnitt 1.1.Elementary Arithmetic"
		self.tc.caption = "Elementary Arithmetic"
		self.tc.level = MODULE_LEVEL
		expected = "1. Elementary Arithmetic"
		self.assertEquals( expected, self.tocRenderer._makeCaption( self.tc ), "Wrong caption" )
		
		# section don't have numbers so get them from the link
		self.tc.title = "LS in two Variables"
		self.tc.fullname = "html/1.4.2/modstart.html"
		self.tc.caption = "LS in two Variables"
		self.tc.level = SECTION_LEVEL
		expected = "4.2. LS in two Variables"
		self.assertEquals( expected, self.tocRenderer._makeCaption( self.tc ), "Wrong caption" )		
		
		# subsection numbers start at the first digit		
		self.tc.title = "Onlinebrückenkurs Mathematik Abschnitt 1.5.1.Final Test Module 1"
		self.tc.caption = "Final Test Module 1"
		self.tc.level = SUBSECTION_LEVEL
		expected = "1.5.1. Final Test Module 1"
		self.assertEquals( expected, self.tocRenderer._makeCaption( self.tc ), "Wrong caption" )
		

	def test_getModule(self):
		'''
		Test that the module corresponding to the selected page is found 
		'''
		# if selected page is root, then return root
		tocRoot = AbstractXmlRenderer.getModule( self.tc.parent )
		self.assertEquals( ROOT_LEVEL, tocRoot.level )
		
		tocRoot = AbstractXmlRenderer.getModule( self.tc )
		self.assertEquals( MODULE_LEVEL, tocRoot.level )
		
		tocRoot = AbstractXmlRenderer.getModule( self.tc.children[0] )
		self.assertEquals( MODULE_LEVEL, tocRoot.level )
		
		tocRoot = AbstractXmlRenderer.getModule( self.tc.children[0].children[0] )
		self.assertEquals( MODULE_LEVEL, tocRoot.level )


	def test_generateTocXML(self):
		'''
		Test that the table of contents XML contains all required elements and attributes
		'''
		#TOC (there are 3 siblings in the test tc object instantiated in the setup of this test)
		self.assertTrue( self.xml.xpath('/toc'), "TOC is missing in XML" )
		self.assertEqual( 3, len( self.xml.xpath('/toc/entries/entry') ), "Expecting 3 entries in TOC in XML" )
		
		
	def test_generateTocEntryXML(self):
		'''
		Test that each TOC entry XML contains all required elements and attributes
		'''		
		#get the selected entry
		selected = self.xml.xpath('/toc/entries/entry[@selected="True"]')[0]
		
		# one sibling is selected
		selectedCount = 0
		for sibling in self.xml.xpath('/toc/entries/entry'):
			if sibling.xpath( '@selected' )[0] == "True": selectedCount += 1
		self.assertEqual( 1, selectedCount )
		
		# selected entry has children
		self.assertEqual( 3, len( selected.xpath('children/entry') ), "Expecting 2 children in TOC in XML" )
		# selected entry has grand children
		self.assertEqual( 3, len( selected.xpath('children/entry/children/entry') ), "Expecting 3 grand children in selected element in XML" )
		
		# Check that levels are present
		self.assertEqual( 2, int( selected.xpath('@level')[0] ) )
		self.assertEqual( 3, int( selected.xpath('children/entry/@level')[0] ) )


if __name__ == "__main__":
	#import sys;sys.argv = ['', 'Test.testName']
	unittest.main()