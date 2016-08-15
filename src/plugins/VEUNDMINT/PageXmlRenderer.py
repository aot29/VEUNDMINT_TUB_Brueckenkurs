'''
	This file is part of the VEUNDMINT plugin package

	The VEUNDMINT plugin package is free software; you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as published by
	the Free Software Foundation; either version 3 of the License, or (at your
	option) any later version.

	The VEUNDMINT plugin package is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
	or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
	License for more details.

	You should have received a copy of the GNU Lesser General Public License
	along with the VEUNDMINT plugin package. If not, see http://www.gnu.org/licenses/.
	
	Created on Aug 5, 2016
	@author: Alvaro Ortiz for TUB (http://tu-berlin.de)
'''

from lxml import etree
import re
import os
from tidylib import tidy_document
from tex2x.renderers.AbstractRenderer import *

class PageXmlRenderer(AbstractXmlRenderer):
	"""
	Create a XML tree for a page. 
	As page contents rendered by TTM are non-valid HTML, only a placeholder element is added here.
	Actual page contents are added in PageTUB.
	"""


	def __init__(self, lang):
		"""
		Please do not instantiate directly, use PageFactory instead (except for unit tests).
		
		@param lang - String ISO-639-1 language code ("de" or "en")
		"""
		self.lang = lang
		
		
	def generateXML( self, tc ):
		"""
		Create a XML document representing a page from a TContent object
		
		@param tc - a TContent object encapsulating page data and content
		@param basePath - String prefix for all links
		@param lang - String ISO-639-1 language code ("de" or "en")
		@return an etree element
		"""
		# page is the root element
		xml = etree.Element( 'page' )

		#self._generateIds( tc )
		# language
		xml.set( 'lang', self.lang )
		# site ID
		#xml.set( 'siteId', tc.siteId )
		# UX ID
		xml.set( 'uxId', tc.uxid )
		# section ID
		#xml.set( 'sectionId', tc.sectionId )
		# document name
		xml.set( 'docName', tc.docname )
		# full name (URL)
		xml.set( 'fullName', tc.fullname )
		
		# title
		title = etree.Element( 'title' )
		title.text = tc.title
		xml.append( title )

		# content
		content = etree.Element( 'content' )
		xml.append( content )
		
		return xml


	def _generateIds(self, tc):
		"""
		compute number of chapters and section numbers
		
		@param tc - a TContent object encapsulating page data and content
		"""
		siteId = ""
		sectionId = -1
		currentTc = tc
		while currentTc.level != 0:
			if currentTc.level == MODULE_LEVEL:
				sectionId = currentTc.nr
			if not siteId:
				siteId = str( currentTc.pos )
			else:
				siteId = "%s.%s" % ( currentTc.pos, siteId )
			currentTc = currentTc.parent
			
		tc.siteId = siteId
		tc.sectionId = sectionId


class PageXmlDecorator( AbstractXmlRenderer ):
	"""
	Base class for all page decorators.
	"""
	def __init__(self, renderer):
		"""
		Initialize the base class with the class that will be decorated
		
		@param renderer - an object implementing AbstractXmlRenderer
		"""
		self.renderer = renderer
		
	
	def generateXml(self, tc):
		"""
		Decorate the class. This method is to be called 
		first thing in the overriding method by all extending decorator classes, 
		like this:
		xml = super().generateXml( tc )
		"""
		return self.renderer.generateXML(tc)
		

class RouletteDecorator( PageXmlDecorator ):
	"""
	Adds roulette-exercises to page xml.
	Implements the decorator pattern.
	"""
	
	def __init__(self, renderer, data):
		"""
		@param renderer - an object implementing AbstractXmlRenderer
		@param data - a dict containing the DirectRoulettes key
		"""
		super().__init__(renderer)
		self.data = data
	
	
	def generateXML(self, tc):
		"""
		Move the roulette questions wrapped in rouletteexc_start and rouletteexc-stop comments to the page header
		
		@param tc - a TContent object encapsulating page data and content
		@return an etree element
		"""
		# call the method from the superclass
		xml = super().generateXml( tc )
		
		# find the roulette questions hidden in the content
		roulettes = etree.Element( 'roulettes' )
		found = re.findall( "<!-- rouletteexc-start;(.+?);(.+?); //--\>(.+?)<!-- rouletteexc-stop;(.+?);(.+?); //--\>", tc.content, re.DOTALL )
		for match in found:
			rid = match[0] # name of the roulette exercise, e.g. VBKM01_FRACTIONTRAINING
			myid = match[1] # Index of the roulette on the page, e.g. 54
			print('DirectRoulettes' in self.data)
			if 'DirectRoulettes' in self.data and rid in self.data[ 'DirectRoulettes' ]:
				maxid = self.data[ 'DirectRoulettes' ][rid]
			else:
				raise Exception( "Roulette not found" )
			
			roulette = etree.Element( 'roulette' )
			roulette.set( 'rid', str( rid ) )
			roulette.set( 'myid', str( myid ) )
			roulette.set( 'maxid', str( maxid ) )
			roulettes.append( roulette )
		
		# remove the questions from the content
		tc.content = re.sub("<!-- rouletteexc-start;(.+?);(.+?); //--\>(.+?)<!-- rouletteexc-stop;(.+?);(.+?); //--\>", '', tc.content, 0, re.DOTALL)
		
		xml.append( roulettes )
		return xml

		
class QuestionDecorator(PageXmlDecorator):
	"""
	Adds questions to page xml.
	Implements the decorator pattern.
	"""
	
	def __init__(self, renderer):
		"""
		@param renderer - an object implementing AbstractXmlRenderer
		"""
		super().__init__(renderer)

	
	def generateXML(self, tc):
		"""
		Move the questions wrapped in onloadstart and onloadstop comments to the page header
		
		@param tc - a TContent object encapsulating page data and content
		@return an etree element
		"""
		# call the method from the superclass
		xml = super().generateXml(tc)

		# find the questions hidden in the content
		questions = etree.Element( 'questions' )
		match = re.findall( "\<!-- onloadstart //--\>(.*?)\<!-- onloadstop //--\>", tc.content )
		for found in match:
			question = etree.Element( 'question' )
			question.text = found
			questions.append( question )

		# remove the questions from the content			
		tc.content = re.sub( "\<!-- onloadstart //--\>(.*?)\<!-- onloadstop //--\>", '', tc.content )
		
		xml.append( questions )
		return xml




			