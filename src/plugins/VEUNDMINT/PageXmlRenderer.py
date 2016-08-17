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


class RouletteDecorator( PageXmlDecorator ):
	"""
	Adds roulette-exercises to page xml.
	Implements the decorator pattern.
	"""
	
	def __init__(self, renderer, data, i18strings):
		"""
		@param renderer - an object implementing AbstractXmlRenderer
		@param data - a dict containing the DirectRoulettes key
		"""
		super().__init__(renderer)
		self.data = data
		self.i18strings = i18strings
	
	
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

		def droul(m):
			"""
			forked from PageKIT by Daniel Haase. 
			Refactor this.
			This creates a json dictionary which html5_mintmod.py stores in a file if it's large enough.
			Then mintscripts_bootstrap loads it.
			There are several problems:
			* All 300 JSON objects get preloaded, which is silly. There should be a backend service that provides them one by one. 
			* There is HTML in this Python class, which is no no (see below for generating XML)
			* html5_mintmod.py has its own problems, see comments there
			"""
			rid = m.group(1)
			myid = int(m.group(2))
			maxid = 0
			if rid in self.data['DirectRoulettes']:
				maxid = self.data['DirectRoulettes'][rid]
			else:
				raise Exception("Could not find roulette id " + rid)
			bt = "<button type=\"button\" class=\"btn btn-success roulettebutton\" onclick=\"rouletteClick('%s',%s,%s);\">%s</button>" % ( rid, myid, maxid, self.i18strings['roulette_new'] )
			# take care not to have any " in the string, as it will be passed as a string to js
			s = "<div id='DROULETTE" + rid + "." + str(myid) + "'>" + m.group(3) + bt + "</div>"
			# div for id=0 is being set into HTML, remaining blocks are stored and will be written to that div by javascript code
			t = ""
			if myid == 0:
				# generate container div and its first entry, as well as the JS array variable
				t += "<div class='dynamic_inset' id='ROULETTECONTAINER_" + rid + "'>" + s + "</div>"
				tc.sitejson["_RLV_" + rid] = list()
			tc.sitejson["_RLV_" + rid].append(s)
			if len(tc.sitejson["_RLV_" + rid]) != (myid + 1):
				raise Exception("Roulette inset id " + str(myid) + ", does not match ordering of LaTeX environments");
			return t

		tc.content = re.sub(r"\<!-- rouletteexc-start;(.+?);(.+?); //--\>(.+?)\<!-- rouletteexc-stop;\1;\2; //--\>\n*", droul, tc.content, 0, re.S)


		"""
		Use the following code as a base for refactoring. This produces XML with the roulette exercises. 
		This XML could be used to store the exercises in a JSON file, or perhaps write a JSON file directly?
		Whatever, exercises should be loaded from the backend dynamically, not stored in a browser-side javascript array, all 300 of them.
		"""
		def droulXML_for_refactoring( match ):
			"""
			Generates XML and placeholders when a roulette is found in the content
			
			@param match - a match object from re.sub
			@returns string containing a placeholder for the first roulette in each group
			"""			
			# Process the match found in the page
			rid = match.group(1) # name of the roulette exercise, e.g. VBKM01_FRACTIONTRAINING
			myid = int( match.group(2) ) # Index of the roulette on the roulette group, e.g. 54
			exercise = match.group(3) # the content of the exercise
			if 'DirectRoulettes' in self.data and rid in self.data[ 'DirectRoulettes' ]:
				maxid = self.data[ 'DirectRoulettes' ][rid]
			else:
				raise Exception( "Roulette not found" )

			# create a XML-roulette element			
			roulette = etree.Element( 'roulette' )
			roulette.set( 'rid', str( rid ) )
			roulette.set( 'myid', str( myid ) )
			roulette.set( 'maxid', str( maxid ) )
			roulette.text = exercise
			roulettes.append( roulette )
			
			# generate placeholder div
			response = ''
			if myid == 0:
				response = exercise
				
			return response
		
		# find the roulette questions in the content and replace them with placeholders
		#tc.content = re.sub(r"\<!-- rouletteexc-start;(.+?);(.+?); //--\>(.+?)\<!-- rouletteexc-stop;\1;\2; //--\>\n*", droulXML, tc.content, 0, re.S)

		# add the roulettes to the xml
		#xml.append( roulettes )

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

		# remove the question object comments from the content			
		tc.content = re.sub( "\<!-- onloadstart //--\>(.*?)\<!-- onloadstop //--\>", '', tc.content )
		
		xml.append( questions )
		return xml




			