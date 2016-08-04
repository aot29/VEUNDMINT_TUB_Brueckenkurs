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
        sectionEntries = entries.xpath("//entry[@level = %s]" % SECTION_LEVEL)
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