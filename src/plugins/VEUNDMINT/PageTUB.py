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
from plugins.VEUNDMINT.PageXmlRenderer import PageXmlRenderer


class PageTUB( AbstractHtmlRenderer, PageXmlRenderer ):
	"""
	Render page by applying XSLT templates, using the lxml library.
	"""
	
	def __init__( self, tplPath, lang, tocRenderer ):
		"""
		Please do not instantiate directly, use PageFactory instead (except for unit tests).
		
		@param tplPath - String path to the directory holding the xslt templates
		@param lang - String ISO-639-1 language code ("de" or "en")
		@param tocRenderer - TocRenderer an AbstractXMLRenderer that builds the table of contents
		"""
		super().__init__( lang )
		self.tplPath = tplPath
		self.lang = lang
		
		self.tocRenderer = tocRenderer

	
	def generateHTML( self, tc ):
		"""
		Applies the template to the page data. The result is a HTML string which is stored in tc.html.
		
		@param tc - TContent object encapsulating the data for the page to be rendered
		"""
		
		# get the base path
		basePath = self.getBasePath(tc)
		
		# Create the XML output
		xml = self.generateXML( tc )
		# toc
		xml.append( self.tocRenderer.generateXML( tc ) )
		# correct the links in content and TOC
		self.correctLinks( xml, basePath )
		# add base path to XML, as the transformer doesn't seem to support parameter passing
		xml.set( 'basePath', basePath )
		# add links to next and previous entries
		self._addPrevNextLinks(xml, tc, basePath)

		# Load the template
		templatePath = os.path.join( self.tplPath, "page.xslt" )
		template = etree.parse( templatePath )

		# Apply the template
		transform = etree.XSLT( template )
		result = transform( xml )
		
		
		# save the result in tc object
		tc.html = self._contentToString( result, tc )


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
	

	def _contentToString(self, xml, tc):
		"""
		TTM produces non-valid HTML, so it has to be added after XML has been parsed.
		Don't use tidy on the whole page, as tidy version 1 drops MathML elements (among other)
		
		@param xml - etree holding the page and toc without the content result of XSLT transformation
		@patam tc - TContent object for the page
		"""
		# Reduce the number of breaks clear=all's, since they mess-up the layout
		tc.content = tc.content.replace( '<br clear="all"><br clear="all"><br clear="all"><br clear="all">', '<br /><br />' )
		
		# replace the content placeholder added in PageXmlRenderer with the actual non-valid HTML content
		resultString = str( xml )
		resultString = resultString.replace( '<content></content>', tc.content )

		return resultString
	

	def _addPrevNextLinks(self, page, tc, basePath=''):
		"""
		Add links to previous and next pages
		
		@param page - etree Element holding content and TOC
		@param tc - a TContent object encapsulating page data and content
		@param basePath - String prefix for all links
		"""
		navPrev = tc.left
		if navPrev is None: 
			navPrev = tc.xleft		
		if navPrev is not None: 
			navPrevEl = etree.Element( "navPrev" )
			navPrevEl.set( "href", os.path.join(basePath, navPrev.fullname ) )
			page.append( navPrevEl )

		navNext = tc.right
		if navNext is None:
			navNext = tc.xright
		if navNext is not None:
			navNextEl = etree.Element( "navNext" )
			navNextEl.set( "href", os.path.join(basePath, navNext.fullname ) )
			page.append( navNextEl )

