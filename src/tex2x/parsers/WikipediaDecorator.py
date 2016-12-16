## @package tex2x.parsers.WikipediaDecorator
#  Create the table of contents (TOC) and the content tree.
#
#  \copyright tex2x converter - Processes tex-files in order to create various output formats via plugins
#  Copyright (C) 2014  VEMINT-Konsortium - http://www.vemint.de
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#  \author Alvaro Ortiz for TU Berlin

from lxml import etree
from tex2x.parsers.AbstractParser import AbstractParser
from urllib.parse import urlencode
from tex2x.annotators.WikipediaAnnotator import WikipediaAnnotator

class WikipediaDecorator( AbstractParser ):
	"""
	Course pages are annotated with links to Wikipedia. A course page can have more than one annotation. 
	
	This class obtains a list of words from Wikipedia, and searches the course pages for where to place them. 
	The list of words is obtained from WikipediaAnnotator.

	This class is meant to decorate TOCParser.
	
	@see https://gitlab.tubit.tu-berlin.de/stefan.born/VEUNDMINT_TUB_Brueckenkurs/wikis/Verkn%C3%BCpfung-mit-Wikipedia
	"""
		
	def __init__(self, parser, lang='de' ):
		"""
		Constructor.
		
		@param options Object
		@param sys - "A module exposing a class System" (Daniel Haase)
		@see annotators.WikipediaAnnotator
		"""
		
		## @var parser
		#  Parser (object extending AbstractParser, in this case TOCParser)
		self.parser = parser
		
		## @var options
		# simplify access to the interface options member (Daniel Haase) - refactor
		self.options = parser.options
		
		## @var sys
		#  Simplify access to the interface options member (Daniel Haase) - refactor
		self.sys = parser.sys
		
		## @var lang
		#  The language of the page ('de' or 'en')
		self.lang = lang
		
		## @var annotator
		#  The Annotator object connects to the Wikipedia REST API and searches for interesting pages.
		self.annotator = WikipediaAnnotator()
		

	def parse(self, *args, **kwargs):
		"""
		Executes a parser (here TOCParser) and then adds links to Wikipedia.
		
		@param content - a list of [toc_node, content_node] items
		"""
		# call the decorated class' parse method
		tempTOC, tempContent = self.parser.parse(*args, **kwargs)

		# add annotations 		
		tempContent = self.addWikipediaAnnotations( tempContent, self.lang )

		return tempTOC, tempContent


	def addWikipediaAnnotations(self, tempContent, lang):
		"""
		Adds an array of Annotation objects to each page.
		
		@see annotators.AbstractAnnotator.Annotation		
		"""
		
		# get the list of Wikipedia entries for the given language
		wikipediaItems = self.annotator.generate( lang )

		#annotate each course page with links to the corresponding Wikipedia entries
		for p in tempContent:
			annotations = self.findAnnotationsForPage( p, wikipediaItems )
			p.append( annotations )
			
		return tempContent


	def findAnnotationsForPage(self, pageContent, wikipediaItems ):
		"""
		Look in the page text for words which have a corresponding Wikipedia entry.
		
		@param pageContent - the content of a page as etree
		"""
		annotations = []
		pageStr = etree.tostring( pageContent[1] ).decode('utf8').lower()
		for item in wikipediaItems:
			if pageStr.find( item.word.lower() ) != -1: annotations.append( item ) 
			
		return annotations

	
