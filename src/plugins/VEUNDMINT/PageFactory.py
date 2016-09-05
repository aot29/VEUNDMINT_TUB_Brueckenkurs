"""

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
"""


"""
   Forked from pagefactory.py (now PageKIT.py) to follow factory pattern.
"""

class PageFactory(object):
    '''
    Deals with the instantiation of page objects without requiring unnecessary coupling.
    Enables having different Page objects, which can be instantiated according to some parameter in Option.py
    '''

    def __init__(self, interface, outputplugin):
        self.sys = interface['system']
        self.data = interface['data']
        self.options = interface['options']
        self.outputplugin = outputplugin


    def getPage(self):
        '''
        Instantiate a Page object. All Page objects should extend AbstractHtmlRenderer.
        Which Page object is instantiated depends on options set in Option.py
        
        @return object implementing AbstractHtmlRenderer
        '''
        
        if ( self.options.bootstrap ):
            # When using bootstrap, use the Page object by TUB
            from plugins.VEUNDMINT.PageTUB import PageTUB
            from plugins.VEUNDMINT.TocRenderer import TocRenderer
            from plugins.VEUNDMINT.PageXmlRenderer import PageXmlRenderer, QuestionDecorator, RouletteDecorator 

            # get a basic page renderer
            xmlRenderer = PageXmlRenderer( self.options.lang )
            # decorate with questions and roulette exercises
            # the order is important, as roulette adds questions
            xmlRenderer =   RouletteDecorator( 
                                    QuestionDecorator( xmlRenderer ), self.data, self.options.strings
                                )
            # get a table of contents renderer            
            tocRenderer = TocRenderer()
            # get a page HTML renderer
            page = PageTUB( self.options.converterTemplates, xmlRenderer, tocRenderer )
            
        else:
            # By default, use the Page object by KIT
            from plugins.VEUNDMINT.PageKIT import PageKIT
            page = PageKIT( self.sys, self.data, self.options, self.outputplugin )
            
        return page 


