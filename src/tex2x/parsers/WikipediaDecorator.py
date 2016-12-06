"""
	tex2x converter - Processes tex-files in order to create various output formats via plugins
	Copyright (C) 2014  VEMINT-Konsortium - http://www.vemint.de

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	@author Alvaro Ortiz for TU Berlin
"""
from lxml import etree
from tex2x.parsers.AbstractParser import AbstractParser
from urllib.parse import urlencode
from tex2x.annotators.WikipediaAnnotator import WikipediaAnnotator

class WikipediaDecorator( AbstractParser ):
	'''
	This class is meant to decorate TOCParser.
	Adds links to Wikipedia.
	'''
		
	def __init__(self, parser, lang='de' ):
		'''
		@param options Object
		@param sys - "A module exposing a class System" (Daniel Haase) 
		'''
		self.parser = parser
		self.options = parser.options
		self.sys = parser.sys
		self.lang = lang
		self.annotator = WikipediaAnnotator()
		

	def parse(self, *args, **kwargs):
		"""
		@param content - a list of [toc_node, content_node] items
		"""
		# call the decorated class' parse method
		tempTOC, tempContent = self.parser.parse(*args, **kwargs)

		# add annotations 		
		tempContent = self.addWikipediaAnnotations( tempContent, self.lang )

		return tempTOC, tempContent


	def addWikipediaAnnotations(self, tempContent, lang):
		'''
		Adds an annotations array to each page
		'''
		
		# get the list of Wikipedia entries for the given language
		wikipediaItems = self.annotator.generate( lang )

		#annotate each course page with links to the corresponding Wikipedia entries
		for p in tempContent:
			annotations = self.findAnnotationsForPage( p, wikipediaItems )
			p.append( annotations )
			
		return tempContent


	def findAnnotationsForPage(self, pageContent, wikipediaItems ):
		'''
		Find words from Wikipedia to add to course page as annotations 
		
		@param pageContent - the content of a page as etree
		'''
		annotations = []
		pageStr = etree.tostring( pageContent[1] ).decode('utf8').lower()
		for item in wikipediaItems:
			if pageStr.find( item.word.lower() ) != -1: annotations.append( item ) 
			
		return annotations

	
