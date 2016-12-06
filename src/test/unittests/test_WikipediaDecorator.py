'''
Created on Dec , 2016

Activate Python venv if necessary, then run with:
> cd src
> python3 -m unittest test.unittests.test_WikipediaDecorator.test_WikipediaDecorator

@author: Alvaro Ortiz
'''
import os
import sys
import unittest
from lxml import etree
from tex2x.dispatcher.Dispatcher import Dispatcher
from tex2x.annotators.WikipediaAnnotator import WikipediaAnnotator
from tex2x.parsers.WikipediaDecorator import WikipediaDecorator
from test.unittests.AbstractRendererTestCase import *

class test_WikipediaDecorator(AbstractRendererTestCase):

	def setUp(self):
		AbstractRendererTestCase.setUp(self)
		dispatcher = Dispatcher(True, "VEUNDMINT", "" )
		self.mockparser = MockParser( dispatcher.options, dispatcher.sys )

	
	def testCreate(self):
		'''
		Check if a WikipediaDecorator can be created at all
		'''
		wd = WikipediaDecorator( self.mockparser )
		self.assertTrue(True)


	def testAddAnnotations(self):
		'''
		Check that the WikipediaDecorator adds an annotations array to each page
		'''
		rawxml = "<root>test</root>"
		xml = etree.fromstring( rawxml )
		wd = WikipediaDecorator( self.mockparser )
		toc, content = wd.parse( xml )
		
		# content is an array
		# each element has 3 elements. The 3. are the annotations
		for p in content:
			self.assertIsNotNone( p[3] )
		
			
	def testListMathWikipedia(self):
		"""
		List the entries of the maths category in Wikipedia
		"""
		annotator = WikipediaAnnotator( )
		mathWords = annotator.generate( 'de' )
		self.assertTrue( len( mathWords ) > 0 )
		

	def testListMathWikipediaEN(self):
		"""
		List the entries of the maths category in Wikipedia
		"""
		annotator = WikipediaAnnotator( )
		annotations = annotator.generate( 'en' )
		mathWords = [item.word for item in annotations]
		self.assertTrue( len( mathWords ) > 0 )
		print(mathWords)
		self.assertTrue( 'Variable' in mathWords )
		self.assertTrue( 'Term' in mathWords )
		self.assertTrue( 'Equation' in mathWords )
		self.assertTrue( 'Function' in mathWords )


	def testFindMathWords(self):
		"""
		Find words to link to Wikipedia in the text
		"""
		rawxml = """
		<div>Eine <b>Variable</b><!-- mpreindexentry;;Variable;;1;;1;;1;;1;;9; //--> 
		ist ein Symbol (typischerweise ein Buchstabe), das als Platzhalter f&#252;r einen unbestimmten Wert\neingesetzt wird. 
		Ein <b>Term</b><!-- mpreindexentry;;Term;;1;;1;;1;;1;;10; //--> ist ein mathematischer Ausdruck, der Variablen, 
		Rechenoperationen und weitere Symbole enthalten kann,\nund der nach Einsetzung von Zahlen f&#252;r die Variablen einen konkreten Zahlenwert 
		ergibt. Terme k&#246;nnen zu Gleichungen bzw. Ungleichungen\nkombiniert oder in Funktionsbeschreibungen eingesetzt werden, 
		dazu sp&#228;ter mehr.\n</div>
		"""
		lang = 'de'
		xml = etree.fromstring( rawxml )
		wd = WikipediaDecorator( self.mockparser, lang )
		annotator = WikipediaAnnotator()
		wikipediaItems = annotator.generate( lang )
		annotations = wd.findAnnotationsForPage( [None, xml], wikipediaItems )
		self.assertTrue( len( annotations ) > 0 )

		words = [item.word for item in annotations]
		self.assertTrue( 'Variable' in words )
		self.assertTrue( 'Term' in words )
		self.assertTrue( 'Gleichung' in words )
		self.assertTrue( 'Funktion' in words )

	def testFindMathWordsEN(self):
		"""
		Find words to link to Wikipedia in the English text
		"""
		rawxml = """
		<div>A variable is a symbol (typically a letter) used as a placeholder for an indeterminate value. 
		A term is a mathematical expression that can contain variables, arithmetic operations and further symbols and, 
		after substituting variables with numbers, can be evaluated to a specific value. Terms can be combined into equations 
		and inequalities, respectively, or they can be inserted into function descriptions, as we shall see later.</div>
		"""
		lang = 'en'
		xml = etree.fromstring( rawxml )
		wd = WikipediaDecorator( self.mockparser, lang )
		annotator = WikipediaAnnotator()
		wikipediaItems = annotator.generate( lang )
		annotations = wd.findAnnotationsForPage( [None, xml], wikipediaItems )
		self.assertTrue( len( annotations ) > 0 )

		words = [item.word for item in annotations]
		self.assertTrue( 'Variable' in words )
		self.assertTrue( 'Term' in words )
		self.assertTrue( 'Equation' in words )
		self.assertTrue( 'Function' in words )
	
if __name__ == '__main__':
	unittest.main()
	