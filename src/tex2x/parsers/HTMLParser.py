## @package tex2x.parsers.HTMLParser
#  Calls lxml.HTMLParser to generate an etree from an XML string.
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
#  \author Daniel Haase for KIT 
#  \author Alvaro Ortiz for TU Berlin

from lxml import html
from lxml import etree
import os
from tex2x.parsers.AbstractParser import AbstractParser

class HTMLParser( AbstractParser ):
	"""
	Calls lxml.HTMLParser to generate an etree from an XML string.
	Can be decorated with VerboseParser to enable performance loging.
	
	@see http://lxml.de/api/lxml.etree.HTMLParser-class.html
	"""
	def __init__(self, options, remove_blank_text = False):
		"""
		Constructor.
		
		@param options - Object encapsulating all the options necessary to run the tex2x converter. 
		@param remove_blank_text - discard empty text nodes that are ignorable (i.e. not actual text content)
		"""
		## @var options
		#   Object encapsulating all the options necessary to run the tex2x converter. 
		self.options = options
		
		## @var remove_blank_text
		#  Discard empty text nodes that are ignorable (i.e. not actual text content)
		self.remove_blank_text = remove_blank_text
		
		## @var parser
		#  An HTML parser that is configured to return lxml.html Element
		self.parser = html.HTMLParser(remove_blank_text = False)


	def parse(self, rawxml):
		"""
		Parse a string containing XML into a HTML5 etree.
		
		@param rawxml - String containing XML
		@return: etree - the HTML tree as parsed from the XML string given in the constructor
		"""
		rawxml = self.replace_html_entities( rawxml )
		return etree.fromstring( rawxml, self.parser )


	def replace_html_entities(self, text):
		"""
		Diese Funktion entfernt alle alten HTML-Entitäten und ersetzt diese
		durch HTML5 konforme Entitäten.

		@param text: String -- Text, in welchem die HTML-Entitäten bearbeitet werden sollen
		@return String -- Text mit bereinigten Entitäten		
		@author - Daniel Haase (except for the try-finally part)
		"""
		#Liste Lesen und verarbeiten
		fobj = open(os.path.join(self.options.currentDir,"src", "entity_list.txt"), "r")
		try:
			line_list = fobj.readlines()
			entity_list = list()
			for line in line_list:
				entity_list.append(line.split())
				#entity_list[-1][0] = "&amp;" + entity_list[-1][0][1:]
	
			#entity_list enthält jetzt je listen Eintrag
			#eine Liste mit zwei Strings
			#erster beschreibt eine alte Entity, z.B.: &Ropf;
			#zweiterer beschreibt den HTML5 Ersatz, z.B: &#8477;
	
			#Alles ersetzen
			for line in entity_list:
				text = text.replace(line[0], line[1])
			
		finally:
			if fobj: fobj.close();
			
		#Bearbeiteten Text zurückgeben
		return text