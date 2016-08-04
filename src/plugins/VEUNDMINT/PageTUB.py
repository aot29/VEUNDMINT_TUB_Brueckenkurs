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
	
	Created on Jul 29, 2016
	@author: Alvaro Ortiz for TUB (http://tu-berlin.de)
'''


from lxml import etree
import os
from tidylib import tidy_document
from tex2x.renderers.AbstractRenderer import *

class PageTUB( AbstractHtmlRenderer, AbstractXmlRenderer ):
	"""
	Render page by applying XSLT templates, using the lxml library.	
	"""
	
	# Entity definition for &nbsp; needs to be added before parsing  
	# perhaps load all entities from DTD?
	ENTITIES = '<!DOCTYPE xsl:stylesheet [ <!ENTITY nbsp "&#160;"> ]>'

	def __init__( self, tplPath, lang, tocRenderer ):
		"""
		Please do not instantiate directly, use PageFactory instead (except for unit tests).
		
		@param tplPath - String path to the directory holding the xslt templates
		@param lang - String ISO-639-1 language code ("de" or "en")
		@param tocRenderer - TocRenderer an AbstractXMLRenderer that builds the table of contents
		"""
		self.tplPath = tplPath
		self.lang = lang
				
		#Use tidy to cleanup tc.content.
		#Do not use tidy on the final output of Page, as tidy will remove empty spans required by bootstrap.
		self.tidyOptions = {
			"output-xml": 1,		# XML instead of HTML4
			"indent": 0,			# Pretty; not too much of a performance hit
			"tab-size": 2,
			"tidy-mark": 0,			# No tidy meta tag in output
			"wrap": 0,				# No wrapping
			"alt-text": "",			# Help ensure validation
			"doctype": 'strict',	# Little sense in transitional for tool-generated markup...
			"force-output": 1,		# May not get what you expect but you will get something}
			"wrap": 0,
			"show-body-only": True	# Doesn't work
		}
		
		self.tocRenderer = tocRenderer

	
	def generateHTML( self, tc ):
		"""
		Applies the template to the page data. The result is a HTML string which is stored in tc.html.
		
		@param tc - TContent object encapsulating the data for the page to be rendered
		"""
		# get the base path
		basePath = self.getBasePath(tc)
		
		# Create the XML output
		xml = self.generateXML( tc, basePath )

		# Load the template
		templatePath = os.path.join( self.tplPath, "page.xslt" )
		template = etree.parse( templatePath )
		if ( template is None ):
			raise Exception( 'Could not load template from file %s' % templatePath )

		# Apply the template
		transform = etree.XSLT( template )
		#print( etree.tostring( xml ))
		result = transform( xml )
		
		# save the result in tc object
		tc.html = str(result) # don't use tidy on the whole page, as version 1 drops-empty-elements


	def generateXML(self, tc, basePath):
		"""
		Create a XML document representing a page from a TContent object
		
		@param tc - a TContent object encapsulating page data and content
		@param basePath - String prefix for all links
		@return an etree element
		"""
		# page is the root element
		page = etree.Element( 'page' )
		page.set( 'lang', self.lang )
		
		# title
		title = etree.Element( 'title' )
		title.text = tc.title
		page.append( title )
		
		# content
		page.append( self.generateContentXML( tc ) )
		
		# toc
		page.append( self.tocRenderer.generateXML( tc ) )

		# add links to next and previous entries
		self._addPrevNextLinks(page, tc, basePath)
		
		# correct the links in content and TOC
		self.correctLinks( page, basePath )
		
		# add base path to XML, as the transformer doesn't seem to support parameter passing
		page.set( 'basePath', basePath )
				
		return page


	def generateContentXML( self, tc ):
		"""
		Get the content from tc, cleanup using tidy, parse it and return XML
		
		@param tc - a TContent object encapsulating page data and content
		@return an etree element
		"""
		# tidy-up page contents from tc.content
		tidyContent, self.tidyErrors = tidy_document( tc.content, self.tidyOptions )
		# Wrap inside a content element
		# Tidy returns a whole HTML page, just use the content part
		# It should be possible to force tidy to return a fragment, but it doesn't work (see self.tidyOptions)
		contentString = tidyContent.replace( '<body>', '<content>' )
		contentString = contentString.replace( '</body>', '</content>' )

		# Drop the clear=all, since they mess-up the layout
		contentString = contentString.replace( '<br clear="all" />', '' )

		# add this to fix &nbsp;.
		contentString = self.ENTITIES + contentString
		# parse content string to etree
		content = etree.fromstring( contentString )
	
		return content.find('content')

	def _addPrevNextLinks(self, page, tc, basePath):
		"""
		Add links to previous and next pages
		
		@param page - etree Element holding content and TOC
		@param tc - a TContent object encapsulating page data and content
		@param basePath - String prefix for all links
		"""
		navPrev = tc.navleft()
		if navPrev is not None: 
			navPrevEl = etree.Element( "navPrev" )
			navPrevEl.set( "href", os.path.join(basePath, navPrev.fullname ) )
			page.append( navPrevEl )
			
		navNext = tc.navright()
		if navNext is not None: 
			navNextEl = etree.Element( "navNext" )
			navNextEl.set( "href", os.path.join(basePath, navNext.fullname ) )
			page.append( navNextEl )


	def getBasePath(self, tc):
		"""
		Set base path to point up from the level of the current tc object
		
		@param tc - TContent object encapsulating the data for the page to be rendered
		"""
		basePath = ".."
		
		if tc.level == ROOT_LEVEL:
			basePath = ".."
		if tc.level == MODULE_LEVEL:
			basePath = ".."
		if tc.level == SECTION_LEVEL:
			basePath = "../.."
		if tc.level == SUBSECTION_LEVEL:
			basePath = "../.."
		
		return basePath


