## @package plugins.VEUNDMINT_TUB.parsers.HTMLParser
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

import os
from tex2x.AbstractParser import AbstractParser
from tex2x.Settings import settings
from lxml import html
from lxml import etree

class HTMLParser( AbstractParser ):
	"""
	Calls lxml.HTMLParser to generate an etree from an XML string.
	Can be decorated with VerboseParser to enable performance loging.

	@see http://lxml.de/api/lxml.etree.HTMLParser-class.html
	"""
	def __init__( self ):
		"""
		Constructor.
		"""
		## @var parser
		#  An HTML parser that is configured to return lxml.html Element
		self.parser = html.HTMLParser(remove_blank_text = False)


	def parse(self, xmlString):
		"""
		Calls lxml.HTMLParser to generate an etree from an XML string.
		@param xmlString - string containing XML, as produced by TTM
		@return etree containing HTML5 (XML)
		"""
		xmlString = self.replace_html_entities( xmlString )
		return etree.fromstring( xmlString, self.parser )


	def replace_html_entities(self, text):
		"""
		Diese Funktion entfernt alle alten HTML-Entitäten und ersetzt diese
		durch HTML5 konforme Entitäten.

		@param text: String -- Text, in welchem die HTML-Entitäten bearbeitet werden sollen
		@return String -- Text mit bereinigten Entitäten
		@author - Daniel Haase (except for the try-finally part)
		"""
		#Liste Lesen und verarbeiten
		fobj = open(os.path.join(settings.currentDir,"src", "entity_list.txt"), "r")
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
