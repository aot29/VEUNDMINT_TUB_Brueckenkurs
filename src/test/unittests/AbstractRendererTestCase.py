'''
Created on Aug 4, 2016

@author: ortiz
'''
import unittest
import os
from lxml import etree

import unittest
from plugins.VEUNDMINT.tcontent import TContent
from tex2x.renderers.AbstractRenderer import *

from tex2x.Settings import settings


class AbstractRendererTestCase(unittest.TestCase):
    """
    Provides a TContent object to test page and TOC renderers
    """
    
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
        self.tc.parent.level = ROOT_LEVEL
        
        #add some siblings
        sibling1 = TContent()
        sibling1.caption = "Sibling 1"
        sibling1.fullname = "html/section1"
        sibling1.myid = 456 
        sibling1.level = MODULE_LEVEL
        sibling2 = TContent()
        sibling2.caption = "Sibling 2"
        sibling2.fullname = "html/section2"
        sibling2.myid = 789 
        sibling2.level = MODULE_LEVEL
        self.tc.parent.children.append( sibling1 )        
        self.tc.parent.children.append( sibling2 )
        
        #add some children
        child1 = TContent()
        child1.caption = "Child 1"
        child1.fullname = "html/1/xcontent1.html"
        child1.level = SECTION_LEVEL
        child1.parent = self.tc
        child2 = TContent()
        child2.caption = "Child 2"
        child2.fullname = "html/2/xcontent2.html"
        child2.level = SECTION_LEVEL
        child2.parent = self.tc
        child3 = TContent()
        child3.caption = "Child 3"
        child3.fullname = "html/3/xcontent3.html"
        child3.level = SECTION_LEVEL
        child3.parent = self.tc
        self.tc.children.append( child1 )
        self.tc.children.append( child2 )
        self.tc.children.append( child3 )

        # Prev and next
        child2.left = child1
        child2.right = child3

        #add some grand children
        child11 = TContent()
        child11.caption = "Child 11"
        child11.fullname = "html/11/xcontent11.html"
        child11.tocsymb = "status1"
        child11.level = SUBSECTION_LEVEL
        child11.parent = child1
        child12 = TContent()
        child12.caption = "Child 12"
        child12.fullname = "html/12/xcontent12.html"
        child12.level = SUBSECTION_LEVEL
        child12.parent = child1
        child21 = TContent()
        child21.caption = "Child 21"
        child21.fullname = "html/21/xcontent21.html"
        child21.level = SUBSECTION_LEVEL
        child21.parent = child2

        child1.children.append( child11 )
        child1.children.append( child12 )
        child2.children.append( child21 )
        
    def tearDown(self):
        pass


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()