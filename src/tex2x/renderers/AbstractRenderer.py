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

import os

# Entity definition for &nbsp; needs to be added before parsing  
# perhaps load all entities from DTD?
ENTITIES = '<!DOCTYPE xsl:stylesheet [ <!ENTITY nbsp "&#160;"> ]>'

# Constants for levels
ROOT_LEVEL = 1
MODULE_LEVEL = 2
SECTION_LEVEL = 3
SUBSECTION_LEVEL = 4

class AbstractXmlRenderer(object):
    
    def generateXML(self, obj):
        '''
        Generates a XML as a string from the given object
        
        @param obj - Object any object used to hold the data
        '''
        raise NotImplementedError
       
    @staticmethod
    def getModule(tc):
        """
        Get the module corresponding to the selected page
        
        @param tc - a TContent object encapsulating page data and content
        @return TContent object - the tc of the corresponding module
        """
        if int( tc.level ) == ROOT_LEVEL: return tc        
        elif int( tc.level ) == MODULE_LEVEL: return tc
        elif int( tc.level ) == SECTION_LEVEL: return tc.parent
        elif int( tc.level ) == SUBSECTION_LEVEL: return tc.parent.parent
        else: return tc


    @staticmethod
    def isFirstPage(tc):
        """
        Is the given tc the first ('Welcome') page?
        
        @param tc - a TContent object encapsulating page data and content
        @return - boolean
        """
        if tc is None: return False
        return tc.uxid == 'VBKM_FIRSTPAGE'


    @staticmethod
    def isCoursePage(tc):
        """
        Is the page described by tc a course page, as opposed to the welcome or settings page
        
        @param tc - a TContent object encapsulating page data and content
        @return - boolean
        """
        return not ( AbstractXmlRenderer.isFirstPage( AbstractXmlRenderer.getModule( tc ) ) ) 
        

class AbstractHtmlRenderer(object):
    '''
    Base class for any Page object. Exposes an interface common to all Page objects.
    Please program to interface whenever possible (aka "programming by contract") to reduce coupling.
    '''
    
    def generateHTML(self, obj):
        '''
        Generates a HTML page as a string using loaded templates and the given object
        
        @param obj - Object any object used to hold the data for the HTML page
        '''
        raise NotImplementedError

    
    @staticmethod
    def correctLinks(xml, basePath ):
        """
        Add basePath to all entries, links and images
        
        @param xml - etree Element holding content as XML
        @param basePath - String prefix for all links
        """
        aHrefs = xml.xpath( "//a|//img|//entry" )
        for a in aHrefs:
            link = a.get( 'href' )
            
            # don't correct links to external resources
            if link is not None and 'http://' not in link and 'mailto:' not in link:
                a.set( 'href', os.path.join( basePath, link ) )

    