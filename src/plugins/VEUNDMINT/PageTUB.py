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
from plugins.VEUNDMINT.AbstractPage import AbstractPage

class PageTUB( AbstractPage ):


    def __init__( self, tplPath ):
        '''
        Please do not instantiate directly, use PageFactory instead (except for unit tests).
        '''
        self.tplPath = tplPath
    
    
    def generateHTML( self, tc ):
        '''
        Applies the template to the page data. The result is a HTML string which is stored in tc.html.
        
        @param tc - TContent object encapsulating the data for the page to be rendered
        '''
        page = self.createPage( tc )
        templatePath = os.path.join( self.tplPath, "page.xslt" )
        template = etree.parse( templatePath )
        if ( template is None ):
            raise Exception( 'Could not load template from file %s' % templatePath )
        transform = etree.XSLT( template )
        result = transform( page )
        tc.html = str(result)


    def createPage(self, tc):
        '''
        Create a XML document representing a page from a TContent object
        
        @param tc - a TContent object encapsulating page data and content
        @return an etree element
        '''
        page = etree.Element( 'page' )
        
        # page title
        title = etree.Element( 'title' )
        title.text = tc.title
        page.append( title )
        
        return page
        
        