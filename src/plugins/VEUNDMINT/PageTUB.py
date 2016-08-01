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
        self._setTidyBaseOptions()
    
    
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
        tc.html, self.tidyErrors = tidy_document( str(result) )


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
        
        # page content
        content = etree.Element( 'content' )
        content.text = tc.content
        page.append( content )
        
        return page

        
    def _setTidyBaseOptions( self ):
        '''
        Use tidy to make code more readable.
        Note that changing the options might invalidate some unit tests
        '''
        tidylib.BASE_OPTIONS = {
            "output-xhtml": 1,     # XHTML instead of HTML4
            "indent": "auto",           # Pretty; not too much of a performance hit
            "tab-size": 2,
            "tidy-mark": 0,        # No tidy meta tag in output
            "wrap": 0,             # No wrapping
            "alt-text": "",        # Help ensure validation
            "doctype": 'strict',   # Little sense in transitional for tool-generated markup...
            "force-output": 1,     # May not get what you expect but you will get something}
            "wrap": 0
        }
