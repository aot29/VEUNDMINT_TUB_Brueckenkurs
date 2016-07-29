import unittest
import os
from plugins.VEUNDMINT.tcontent import TContent
from plugins.VEUNDMINT.PageTUB import PageTUB


class test_PageTUB(unittest.TestCase):
	tplPath = os.environ['PYTHONPATH'] + "/src/templates_xslt"
	

	def setUp(self):
		self.tc = TContent()
		self.tc.title = "Test Title"


	def test_generateHTML(self):
		# generate HTML element using the tc mock-up
		page = PageTUB( self.tplPath )
		page.generateHTML( self.tc )
		# print(self.tc.html)
		# HTML is stored in tc.html
		self.assertTrue( "<title>%s</title>" % self.tc.title in self.tc.html, "Title not found in HTML" )		


	def test_createPage(self):

		# create an XML element using the tc mock-up
		page = PageTUB( self.tplPath )
		xml = page.createPage( self.tc )

		self.assertEqual( self.tc.title, xml.xpath('/page/title')[0].text, "Title is wrong" )