'''
Created on Aug 4, 2016

@author: ortiz
'''
import unittest
from test.unittests.AbstractRendererTestCase import AbstractRendererTestCase
from plugins.VEUNDMINT.TocRenderer import TocRenderer
from tex2x.renderers.AbstractRenderer import *

class test_TocRenderer(AbstractRendererTestCase):
    
    def setUp(self):
        AbstractRendererTestCase.setUp(self)

        self.tocRenderer = TocRenderer( self.tplPath, self.lang )
        self.xml = self.tocRenderer.generateXML( self.tc )
        

    def test_getModule(self):
        '''
        Test that the module corresponding to the selected page is found 
        '''
        # if selected page is root, then return root
        tocRoot = self.tocRenderer._getModule( self.tc.parent )
        self.assertEquals( ROOT_LEVEL, tocRoot.level )
        
        tocRoot = self.tocRenderer._getModule( self.tc )
        self.assertEquals( MODULE_LEVEL, tocRoot.level )
        
        tocRoot = self.tocRenderer._getModule( self.tc.children[0] )
        self.assertEquals( MODULE_LEVEL, tocRoot.level )
        
        tocRoot = self.tocRenderer._getModule( self.tc.children[0].children[0] )
        self.assertEquals( MODULE_LEVEL, tocRoot.level )


    def test_generateTocXML(self):
        '''
        Test that the table of contents XML contains all required elements and attributes
        '''        
        #TOC (there are 3 siblings in the test tc object instantiated in the setup of this test)
        self.assertTrue( self.xml.xpath('/toc'), "TOC is missing in XML" )
        self.assertEqual( 3, len( self.xml.xpath('/toc/entries/entry') ), "Expecting 2 entries in TOC in XML" )
        
        
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
        self.assertEqual( 2, len( selected.xpath('children/entry') ), "Expecting 2 children in TOC in XML" )
        # selected entry has grand children
        self.assertEqual( 3, len( selected.xpath('children/entry/children/entry') ), "Expecting 3 grand children in selected element in XML" )
        
        # Check that levels are present
        self.assertEqual( 2, int( selected.xpath('@level')[0] ) )
        self.assertEqual( 3, int( selected.xpath('children/entry/@level')[0] ) )


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()