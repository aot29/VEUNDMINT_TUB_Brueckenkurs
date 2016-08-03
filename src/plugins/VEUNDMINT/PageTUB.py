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
from tex2x.renderers.AbstractPage import AbstractPage

class PageTUB( AbstractPage ):
	"""
	Render page by applying XSLT templates, using the lxml library.	
	"""
	
	# Constants for levels
	MODULE_LEVEL = 2
	SECTION_LEVEL = 3
	SUBSECTION_LEVEL = 4

	# Entity definition hack
	ENTITIES = '<!DOCTYPE xsl:stylesheet [ <!ENTITY nbsp "&#160;"> ]>'

	def __init__( self, tplPath, lang ):
		"""
		Please do not instantiate directly, use PageFactory instead (except for unit tests).
		
		@param tplPath - String path to the directory holding the xslt templates
		@param lang - String ISO-639-1 language code ("de" or "en")
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
		page.append( self.generateTocXML( tc ) )

		# add links to next and previous entries
		self.addPrevNextLinks(page, tc, basePath)
		
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

		
	def generateTocXML( self, tc ):
		"""
		Create XML for the table of contents
		
		@param tc - a TContent object encapsulating page data and content
		@return an etree element
		"""
		toc = etree.Element( 'toc' )
		entries = etree.Element( 'entries' )

		# go through the tree contained in tc, starting one level up
		parent = tc.parent
		if parent is not None:
			# siblings are at the same level than the current page
			siblings = parent.children
			for i in range( len( siblings ) ):
				sibling = siblings[i]
				# add the new entry to the entries element
				entries.append( self.generateTocEntryXML( tc, sibling ) )
		
		# correct links to sections in TOC
		sectionEntries = entries.xpath("//entry[@level = %s]" % self.SECTION_LEVEL)
		modstartSuffix = "modstart.html"
		for entry in sectionEntries:
			link = os.path.join( entry.get( 'href' ), modstartSuffix )				
			entry.set( 'href', link )
			
		# add the entries to the toc element
		toc.append( entries )
		
		return toc


	def generateTocEntryXML(self, tc, sibling):
		"""
		Create XML for the table of contents
		
		@param tc - a TContent object encapsulating a TOC entry
		@param sibling - a TContent object encapsulating a TOC entry
		@return an etree element
		"""
		entry = self.generateSingleEntryXML( sibling )

		# check if entry is selected
		if sibling.myid == tc.myid: 
			isSelected = "True"
			# if entry selected, append its children
			entry.append( self.generateTocEntryChildrenXML( sibling ) )
			
		else:
			isSelected = "False"

		entry.set( "selected", isSelected )
				
		return entry


	def generateTocEntryChildrenXML( self, sibling ):
		"""
		Create XML for the table of contents
		
		@param sibling - a TContent object encapsulating a TOC entry
		@return an etree element
		"""
		childrenElement = etree.Element( 'children' )		
		for child in sibling.children:
			childEl = self.generateSingleEntryXML( child )

			# Append grand children recursively
			if hasattr(child, 'children') and child.children is not None:
				children2 = self.generateTocEntryChildrenXML( child )
				childEl.append( children2 )
	
			childrenElement.append( childEl )
			
		return childrenElement
	
	
	def generateSingleEntryXML(self, child):
		"""
		Create XML for single entries or children of entries in the table of contents
		
		@param sibling - a TContent object encapsulating a TOC entry
		@return an etree element
		"""		
		childEl = etree.Element( 'entry' )
		
		# set link
		childEl.set( 'href', child.fullname )
		
		# status is an attribute (optional)
		if hasattr( child, 'tocsymb' ) and child.tocsymb is not None:
			childEl.set( 'status', child.tocsymb )
	
		# Modules are level 2, sections are level 3 etc.
		childEl.set( 'level', str( child.level ) )
	
		# caption is an element, as it could contain HTML-tags
		caption = etree.Element( "caption" )
		caption.text = child.caption
		childEl.append( caption )
		
		return childEl


	def addPrevNextLinks(self, page, tc, basePath):
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
		for l in range( self.MODULE_LEVEL, tc.level ):
			basePath = os.path.join( '..', basePath )
			
		return basePath

	
	def correctLinks(self, page, basePath ):
		"""
		Add basePath to all entries, links and images
		
		@param page - etree Element holding content and TOC
		@param basePath - String prefix for all links
		"""
		aHrefs = page.xpath( "//a|//img|//entry" )
		for a in aHrefs:
			link = a.get( 'href' )
			
			# don't correct links to external resources
			if link is not None and 'http://' not in link and 'mailto:' not in link:
				a.set( 'href', os.path.join( basePath, link ) )


