import unittest
import os
from lxml import etree

from plugins.VEUNDMINT.tcontent import TContent
from plugins.VEUNDMINT.PageXmlRenderer import PageXmlRenderer
from tex2x.Settings import settings

from test.unittests.AbstractRendererTestCase import AbstractRendererTestCase
from tex2x.renderers.AbstractRenderer import *

class test_PageXmlRenderer(AbstractRendererTestCase):
    
    def setUp(self):
        AbstractRendererTestCase.setUp(self)
        
        self.renderer = PageXmlRenderer( self.lang )
        # create an XML element using the tc mock-up 
        # (only for testing, i.r.l. you can skip this step and do page.generateHTML directly)
        self.xml = self.renderer.generateXML( self.tc )


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
        

        

        