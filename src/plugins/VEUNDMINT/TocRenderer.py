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
    
    Created on Aug 4, 2016
    @author: Alvaro Ortiz for TUB (http://tu-berlin.de)
'''


from lxml import etree
import os
from tidylib import tidy_document
from tex2x.renderers.AbstractRenderer import *

class TocRenderer( AbstractXmlRenderer ):
    
    def __init__( self, tplPath, lang ):
        """
        Please do not instantiate directly, use PageFactory instead (except for unit tests).
        
        @param tplPath - String path to the directory holding the xslt templates
        @param lang - String ISO-639-1 language code ("de" or "en")
        """
        self.tplPath = tplPath
        self.lang = lang

    
    def generateXML( self, tc ):
        """
        Create XML for the table of contents
        
        @param tc - a TContent object encapsulating page data and content
        @return an etree element
        """
        toc = etree.Element( 'toc' )
        selectedId = tc.myid
        toc.set( 'forPage', str( selectedId ) )
        entries = etree.Element( 'entries' )

        # go through the tree contained in tc, starting one level up
        # get the root element for the TOC
        tocModule = self._getModule( tc )
        if tocModule is not None and tocModule.parent is not None:
            # siblings are at the modules at the same level than the current page
            siblings = tocModule.parent.children
            for i in range( len( siblings ) ):
                sibling = siblings[i]
                # add the new entry to the entries element
                entries.append( self.generateTocEntryXML( tocModule, sibling, selectedId ) )

        # add the entries to the toc element
        toc.append( entries )

        return toc


    def generateTocEntryXML(self, module, sibling, selectedId ):
        """
        Create XML for the table of contents
        
        @param module - a TContent object encapsulating a TOC entry
        @param sibling - a TContent object encapsulating a TOC entry
        @param selectedId - int id of the selected page
        @return an etree element
        """
        entry = self.generateSingleEntryXML( sibling, module.myid )

        # check if module is selected
        if sibling.myid == module.myid: 
            # if entry selected, append its children
            entry.append( self.generateTocEntryChildrenXML( sibling, selectedId ) )

        return entry


    def generateTocEntryChildrenXML( self, sibling, selectedId ):
        """
        Create XML for the table of contents
        
        @param sibling - a TContent object encapsulating a TOC entry
        @param selectedId - int the id of the currently selected page
        @return an etree element
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
        
        @param sibling - a TContent object encapsulating a TOC entry
        @param selectedId - int the id of the currently selected page
        @return an etree element
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
        caption.text = child.caption
        childEl.append( caption )
        
        return childEl
    
    
    def _getModule(self, tc):
        """
        Get the root of the TOC tree
        """
        if int( tc.level ) == ROOT_LEVEL: return tc        
        elif int( tc.level ) == MODULE_LEVEL: return tc
        elif int( tc.level ) == SECTION_LEVEL: return tc.parent
        elif int( tc.level ) == SUBSECTION_LEVEL: return tc.parent.parent
