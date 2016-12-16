## @package tex2x.annotators.AbstractAnnotator
#  Base classes for the annotation functionality. Annotations are extra information or links added to interesting words or specific pages in the course. See class documentation for details.
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

class AbstractAnnotator(object):
	"""
	Base class for all Annotators. Annotators compile a list of interesting words from any source, e.g. the web, the filesystem, a database.
	These words are then added to specific pages as annotations.
	
	@see Annotation
	"""
	def generate(self, *args, **kwargs ):
		"""
		Generate an array of annotation objects. This array contains all the annotations used for the course.
		
		@example If you wish to annotate the course with Wikipedia entries, the annotation array will contain
		all Annotation objects representing all interesting Wikipedia entries for the whole course. 
		
		@return - array of Annotation objects
		"""
		raise NotImplementedError
	
	
class Annotation():
	"""
	Object representing an annotation. 
	
	Annotations are snippets that are added to a page automatically.
	* Annotations are added to specific pages
	* Annotations are language-specific
	* Annotations can be links to external sources
	
	@example If you wish to add a link to the Wikipedia entry for "Radius" each time the word "circle" is found in the text:
	Annotation( "circle", "Click here for an explanation of radius", "https://en.wikipedia.org/wiki/Radius" )
	
	"""	
	def __init__(self, word, title, url):
		"""
		Constructor.
		
		@param word - word to annotate
		@param title - title of the annotation, e.g. link text
		@param url - URL associated with the annotation, e.g. link target
		"""
		## @var word
		#  Word to annotate
		self.word = word

		## @var title
		#  Title of the annotation, e.g. link text
		self.title = title
		
		## @var url
		# URL associated with the annotation, e.g. link target
		self.url = url
	
	
	def toEtree(self):
		"""
		Converts the annotation object to an etree element, with members as attributes.
		Use this in combination with (XSLT) templates to display an annotation.
		
		@return Element - an etree Element
		"""
		annotationEl = etree.Element( "annotation" )
		annotationEl.set( "word", self.word )
		annotationEl.set( "title", self.title )
		annotationEl.set( "url", self.url )
		return annotationEl
