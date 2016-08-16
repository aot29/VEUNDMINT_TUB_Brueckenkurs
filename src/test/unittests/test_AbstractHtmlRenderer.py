'''
Created on Aug 4, 2016

@author: ortiz
'''
import unittest
from plugins.VEUNDMINT.tcontent import TContent
from tex2x.renderers.AbstractRenderer import AbstractHtmlRenderer
from lxml import etree

class test_AbstractHtmlRenderer(unittest.TestCase):

    def testCorrectLinks(self):
        """
        Test that internal links and references get corrected and external ones are left as-is.
        """
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
        AbstractHtmlRenderer.correctLinks( xml, basePath )
        self.assertTrue( basePath in image.get( 'href' ), "Link correction failed for link %s" % image.get( 'href' ) )
        self.assertTrue( basePath in entry.get( 'href' ), "Link correction failed for link %s" % entry.get( 'href' ) )
        self.assertTrue( basePath in internalLink.get( 'href' ), "Link correction failed for link %s" % internalLink.get( 'href' ) )
        
        self.assertFalse( basePath in externalLink.get( 'href' ), "Link correction failed for link %s" % externalLink.get( 'href' ) )
        self.assertFalse( basePath in mailto.get( 'href' ), "Link correction failed for link %s" % mailto.get( 'href' ) )
        
        

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()