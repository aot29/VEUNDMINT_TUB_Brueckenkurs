'''
Created on Jul 29, 2016

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
'''

''' 
	Render page by applying XSLT templates, using the lxml library.
	
	@author: Alvaro Ortiz for TUB (http://tu-berlin.de)
'''

from lxml import etree
import os
import tidylib
from tidylib import tidy_document
from tex2x.renderers.AbstractPage import AbstractPage

class PageTUB( AbstractPage ):


	def __init__( self, tplPath, lang ):
		'''
		Please do not instantiate directly, use PageFactory instead (except for unit tests).
		'''
		self.tplPath = tplPath
		self.lang = lang
		
		'''
		Use tidy to cleanup tc.content.
		Do not use tidy on the final output of Page, as tidy will remove empty spans required by bootstrap.
		'''
		self.tidyOptions = {
			"output-xml": 1,	 # XML instead of HTML4
			"indent": 0,		   # Pretty; not too much of a performance hit
			"tab-size": 2,
			"tidy-mark": 0,		# No tidy meta tag in output
			"wrap": 0,			 # No wrapping
			"alt-text": "",		# Help ensure validation
			"doctype": 'strict',   # Little sense in transitional for tool-generated markup...
			"force-output": 1,	 # May not get what you expect but you will get something}
			"wrap": 0,
			"show-body-only": True # Doesn't work
		}	
	
	def generateHTML( self, tc ):
		'''
		Applies the template to the page data. The result is a HTML string which is stored in tc.html.
		
		@param tc - TContent object encapsulating the data for the page to be rendered
		'''
		# Create the XML inout
		page = self.createPageXML( tc )

		# Load the template
		templatePath = os.path.join( self.tplPath, "page.xslt" )
		template = etree.parse( templatePath )
		if ( template is None ):
			raise Exception( 'Could not load template from file %s' % templatePath )

		# Apply the template
		transform = etree.XSLT( template )
		result = transform( page )

		# save the result in tc object
		tc.html = str(result) # don't use tidy on the whole page, as version 1 drops-empty-elements


	def createPageXML(self, tc):
		'''
		Create a XML document representing a page from a TContent object
		
		@param tc - a TContent object encapsulating page data and content
		@return an etree element
		'''
		page = etree.Element( 'page' )
		page.set( 'lang', self.lang )
		
		# page title
		title = etree.Element( 'title' )
		title.text = tc.title
		page.append( title )
		
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
		contentString = '<!DOCTYPE xsl:stylesheet [ <!ENTITY nbsp "&#160;"> ]>' + contentString
		content = etree.fromstring( contentString )
		#print( etree.tostring( content.find('content') ) )
		page.append( content.find('content') )
		
		# toc
		page.append( self.createTocXML( tc ) )
		
		return page

	
	def createTocXML(self, tc):
		'''
		Create XML for the table of contents
		
		@param tc - a TContent object encapsulating page data and content
		@return an etree element
		'''
		toc = etree.Element( 'toc' )

		entries = etree.Element( 'entries' )
		for child in tc.children:
			entry = etree.Element( 'entry' )
			# href is an attribute
			entry.set( 'href', child.fullname )
			# title is an element, as it could contain HTML-tags
			title = etree.Element( 'title' )
			title.text = child.title
			entry.append( title )
			# add the new entry to the entries element
			entries.append( entry )
		
		# add the entries to the toc element
		toc.append( entries )

		return toc


