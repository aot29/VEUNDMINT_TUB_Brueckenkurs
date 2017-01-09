## @package tex2x.renderers.TocRenderer
#  Generates a table of contents for the selected page.
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
import re
import html
from tex2x.AbstractRenderer import *
from tex2x.Settings import settings

class TocRenderer( AbstractXmlRenderer ):
	"""
	Generates a table of contents for the selected page (the TContent tc object passed to renderXML)
	"""

	def __init__(self):
		"""
		Constructor.
		Instantiated by PageFactory.
		Needs to override constructor from parent abstract class.
		"""
		pass


	def renderXML( self, tc ):
		"""
		Create XML for the table of contents

		@param tc - a TContent object encapsulating page data and content
		@return an etree element representing the TOC
		"""
		toc = etree.Element( 'toc' )

		# skip on special pages
		if AbstractXmlRenderer.isSpecialPage( tc ) : return toc

		pageId = tc.myid
		# add a parameter to the tree: the currently selected page
		toc.set( 'forPage', str( pageId ) )
		# course description
		toc.set( 'description', settings.description )

		# the TOC entries tree
		entries = etree.Element( 'entries' )

		# get the module element for the TOC
		tocModule = AbstractXmlRenderer.getModule( tc )
		if tocModule is not None and tocModule.parent is not None:
			# siblings are at the modules at the same level than the current page
			siblings = tocModule.parent.children
			# get the id of the currently selected module
			moduleId = tocModule.myid
			for i in range( len( siblings ) ):
				sibling = siblings[i]
				# add the new entry to the entries element
				entries.append( self.generateTocEntryXML( sibling, moduleId, pageId ) )

		# add the entries to the toc element
		toc.append( entries )

		#print( AbstractXmlRenderer.toString( toc ) )

		return toc


	def generateTocEntryXML(self, sibling, moduleId, pageId ):
		"""
		Create XML for the table of contents

		@param sibling - a TContent object encapsulating a TOC entry
		@param moduleId -  - int id of the currently selected module
		@param pageId - int id of the currently selected page
		@return an etree element representing this TOC entry.
		"""
		entry = self.generateSingleEntryXML( sibling, moduleId )

		# check if module is selected
		if sibling.myid == moduleId:
			# if entry selected, append its children
			entry.append( self.generateTocEntryChildrenXML( sibling, pageId ) )

		return entry


	def generateTocEntryChildrenXML( self, sibling, selectedId ):
		"""
		Create XML for the table of contents

		@param sibling - a TContent object encapsulating a TOC entry
		@param selectedId - int the id of the currently selected page
		@return an etree element representing the children of this TOC entry.
		"""
		childrenElement = etree.Element( 'children' )
		for child in sibling.children:
			childEl = self.generateSingleEntryXML( child, selectedId )

			# Append grand children recursively
			if hasattr(child, 'children') and child.children is not None:
				children2 = self.generateTocEntryChildrenXML( child, selectedId )
				childEl.append( children2 )

			childrenElement.append( childEl )

		return childrenElement


	def generateSingleEntryXML(self, child, selectedId):
		"""
		Create XML for single entries or children of entries in the table of contents

		@param child - a TContent object encapsulating a TOC entry
		@param selectedId - int the id of the currently selected page
		@return an etree element representing a TOC entry.
		"""
		childEl = etree.Element( 'entry' )

		# Set link for TOC entry
		# Sections don't have links, as there are actually only modules and subsections
		# In PageKIT, these are redirects to the first subsection
		childEl.set( 'id', str( child.myid ) )

		if ( child.level != SECTION_LEVEL ):
			childEl.set( 'href', child.fullname )

		# status is an attribute (optional)
		if hasattr( child, 'tocsymb' ) and child.tocsymb is not None:
			childEl.set( 'status', child.tocsymb )

		# Modules are level 2, sections are level 3 etc.
		childEl.set( 'level', str( child.level ) )

		# Mark the entry as selected
		if child.myid == selectedId:
			childEl.set( 'selected', 'True' )
		else:
			childEl.set( 'selected', 'False' )

		# caption is an element, as it could contain HTML-tags
		caption = etree.Element( "caption" )
		caption.text = self._makeCaption( child )
		childEl.append( caption )

		return childEl


	def _makeCaption(self, tc):
		"""
		Make the caption to be displayed for each TOC entry.
		The caption is the text displayed for each toc entry.

		@param tc - a TContent object encapsulating a TOC entry
		@return - String, the text to be displayed for this entry in the TOC.
		"""

		# don't add section numbers to captions on the first page (imprint, course information etc.)
		if not AbstractXmlRenderer.isCoursePage(tc): return tc.caption

		pageIndex = tc.title
		# For module captions, remove the first digit and point
		if tc.level == MODULE_LEVEL:
			match = re.search('(?<=\d\.)\w+', tc.title)
			if match:
				pageIndex = match.group(0) + '.'

		# section captions are not numbered, so get the number from the link (the 2 last digits from the folder name)
		elif tc.level == SECTION_LEVEL:
			match = re.search( '(?<=\d\.)\d+\.\d+', tc.fullname)
			if match:
				pageIndex = match.group(0) + '.'

		# match at least one digit followed by a point possibly followed by one or more digits etc
		if tc.level == SUBSECTION_LEVEL:
			match = re.search( '\d+\.\d*\.*\d*\.*', tc.title )
			if match:
				pageIndex = match.group(0)

		response = "%s %s" % ( pageIndex, tc.caption )

		# Need to unescape to cope with different formats in LaTeX files.
		# If umlaute are written as e.g. "a in LaTeX, they get converted to unicode entities, such as &#228;
		# which in turn get escaped as &amp;228; during XSL transformation.
		return html.unescape( response )
