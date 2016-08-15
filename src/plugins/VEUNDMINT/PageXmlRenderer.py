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
		
		
	def generateXML(self, tc):
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
		
		# add questions
		xml.append( self._getQuestions( tc ) )

		# add roulettes
		xml.append( self._getRoulettes( tc ) )

		return xml


	def _getRoulettes(self, tc):
		"""
		Move the roulette questions wrapped in rouletteexc_start and rouletteexc-stop comments to the page header
		
		@param tc - a TContent object encapsulating page data and content
		@return an etree element
		"""
		# find the roulette questions hidden in the content
		roulettes = etree.Element( 'roulettes' )
		match = re.findall( "\<!-- rouletteexc_start //--\>(.*?)\<!-- rouletteexc-stop //--\>", tc.content )
		for found in match:
			roulette = etree.Element( 'roulette' )
			roulette.text = found
			roulettes.append( roulette )
		
		# remove the questions from the content			
		tc.content = re.sub( "\<!-- rouletteexc_start //--\>(.*?)\<!-- rouletteexc-stop //--\>", '', tc.content )
		
		return roulettes
		

	def _getQuestions(self, tc):
		"""
		Move the questions wrapped in onloadstart and onloadstop comments to the page header
		
		@param tc - a TContent object encapsulating page data and content
		@return an etree element
		"""
		# find the questions hidden in the content
		questions = etree.Element( 'questions' )
		match = re.findall( "\<!-- onloadstart //--\>(.*?)\<!-- onloadstop //--\>", tc.content )
		for found in match:
			question = etree.Element( 'question' )
			question.text = found
			questions.append( question )

		# remove the questions from the content			
		tc.content = re.sub( "\<!-- onloadstart //--\>(.*?)\<!-- onloadstop //--\>", '', tc.content )
		
		return questions


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


			