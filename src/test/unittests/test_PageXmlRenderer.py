'''
Run with:
> cd src
> python3 -m unittest test.unittests.test_PageXmlRenderer.test_PageXmlRenderer

@author: ortiz
'''
import unittest
import os
from lxml import etree

from plugins.VEUNDMINT.tcontent import TContent
from tex2x.renderers.PageXmlRenderer import *
from tex2x.Settings import settings

from test.unittests.AbstractRendererTestCase import AbstractRendererTestCase
from tex2x.renderers.AbstractRenderer import *
from tex2x.renderers.PageXmlRenderer import RouletteDecorator

class test_PageXmlRenderer(AbstractRendererTestCase):
    
    def setUp(self):
        AbstractRendererTestCase.setUp(self)        
        page = PageXmlRenderer( self.options )
        pageWithQuestions = QuestionDecorator( page )
        self.renderer = RouletteDecorator( pageWithQuestions, self.data, self.i18strings )
        

    def test_renderXML(self):
        '''
        Test that the XML contains all required elements and attributes
        '''
        # create an XML element using the tc mock-up 
        # (only for testing, i.r.l. you can skip this step and do page.renderHTML directly)
        self.xml = self.renderer.renderXML( self.tc )
        
        #Title
        self.assertEqual( self.tc.title, self.xml.xpath('/page/title')[0].text, "Title is wrong in XML" )
        #Lang
        self.assertEqual( self.lang, self.xml.xpath('/page/@lang')[0], "Language code is wrong in XML" )
        # found a question in the sample content
        self.assertEqual( 1, len( self.xml.xpath( '/page/questions' ) ), "Expected a question, but none or more than one found" )
        # found a roulette exercise in the sample content
        # this is disabled until RouletteDecorator is refactored
        #self.assertEquals( 1, len( self.xml.xpath( '/page/roulettes' ) ), "Expected a roulette exercise, but none or more than one found" )

    

        