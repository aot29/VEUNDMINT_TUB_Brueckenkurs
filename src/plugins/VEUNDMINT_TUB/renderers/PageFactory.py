## @package tex2x.renderers.PageFactory
#  The page factory is used to create page objects. Avoids unnecessary coupling and 
#  potentially opens the way to having alternative page objects.
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
from tex2x.Settings import ve_settings as settings
from tex2x.System import ve_system as sys

class PageFactory(object):
	"""
	Deals with the instantiation of page objects without requiring unnecessary coupling.
	Enables having different Page objects, which can be instantiated according to some parameter in Option.py
	"""

	def __init__(self, data, outputplugin):
		"""
		Constructor
		Instantiated by Plugin class in html5_mintmodtex.py
		
		@param interface undocumented data structure (Daniel Haase)
		@param outputplugin Plugin (object implementing AbstractPlugin)		
		"""
		
		## @var data
		#  data member, undocumented (Daniel Haase) 
		self.data = data
				
		## @var outputplugin
		#  Plugin (object implementing AbstractPlugin):
		self.outputplugin = outputplugin


	def getPage(self):
		"""
		Instantiate a Page object. All Page objects should extend AbstractHtmlRenderer.
		Which Page object is instantiated depends on options set in Option.py
		
		@return object implementing AbstractHtmlRenderer
		"""
		
		if ( not  settings.bootstrap ): raise Exception( 'Only Bootstrap Page renderer is supported in this version' )
		
		# When using bootstrap, use the Page object by TUB
		from .PageTUB import PageTUB
		from .TocRenderer import TocRenderer
		from .PageXmlRenderer import PageXmlRenderer, QuestionDecorator, RouletteDecorator 

		# get a basic page renderer
		xmlRenderer = PageXmlRenderer()
		
		# decorate with questions and roulette exercises
		# the order is important, as roulette adds questions
		xmlRenderer =   RouletteDecorator(
							QuestionDecorator( xmlRenderer ), 
							self.data, settings.strings
						)

		# get a table of contents renderer			
		tocRenderer = TocRenderer()

		# get a page HTML renderer
		page = PageTUB( xmlRenderer, tocRenderer, self.data )

		return page 


