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

class AbstractAnnotator(object):
	'''
	Base class for all annotators.
	Annotator load data from any source, e.g. the web, the filesystem, a database.
	They return an array of Annotation objects
	'''
	def generate(self, *args, **kwargs ):
		"""
		@return - array of Annotation objects
		"""
		raise NotImplementedError
	
	
class Annotation():
	"""
	Object representing an annotation.
	"""
	def __init__(self, word, title, url):
		"""
		@param word - word to annotate
		@param title - title of the annotation, e.g. link text
		@param url - URL associated with the annotation, e.g. link target
		"""
		self.word = word
		self.title = title
		self.url = url
	
	
	def toEtree(self):
		"""
		Converts the annotation object to an etree element, with members as attributes.
		@return Element - an etree Element
		"""
		annotationEl = etree.Element( "annotation" )
		annotationEl.set( "word", self.word )
		annotationEl.set( "title", self.title )
		annotationEl.set( "url", self.url )
		return annotationEl
