"""
	tex2x converter - Processes tex-files in order to create various output formats via plugins
	Copyright (C) 2014  VEMINT-Konsortium - http://www.vemint.de

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	@author Daniel Haase for KIT
	@author Alvaro Ortiz for TU Berlin
"""
from tex2x.parsers.AbstractParser import AbstractParser

class LinkDecorator( AbstractParser ):
	'''
	This class is meant to decorate TOCParser.
	Add methods to correct where the links in the content point to.
	Can be decorated with VerboseDecorator to enable performance logging.
	'''
	def __init__(self, parser ):
		'''
		@param options Object
		@param sys - "A module exposing a class System" (Daniel Haase) 
		'''
		self.parser = parser
		self.options = parser.options
		self.sys = parser.sys
		

	def parse(self, *args, **kwargs):
		"""
		@param content - a list of [toc_node, content_node] items
		"""
		# call the decorated class' runner
	
		tempTOC, tempContent = self.parser.parse(*args, **kwargs)
		
		if not hasattr(self.options, "nolinkcorrection"): self.options.nolinkcorrection = 0
		
		if self.options.nolinkcorrection == 0:
			tempContent = self.correct_path_to_linked_files( tempContent )
			
		else:
			self.sys.message(self.sys.VERBOSEINFO, "tex2x link correction not requested by options")
		
		return tempTOC, tempContent


	def correct_path_to_linked_files(self, content):
		"""
		Bilder und Interaktionen liegen in einem gemeinsamen Verzeichnis auf einer
		höheren Ebene als die html/xml Dateien. Das kann auf der tex-Ebene noch nicht berücksichtigt werden und wird
		an dieser Stelle korrigiert.

		TODO: Derzeit handelt es sich konstant um 2 Ebenen. Das sollte jedeoch anhand der Position der zugehörigen toc_node
		im Inhaltsverzeichnis dynamisch korrigiert werden.
		
		@param content: content-Liste -- content-Liste der Inhalte deren Pfade korrigiert werden sollen.
		@author Daniel Haase
		"""
		for tupel in content:
			for div in tupel[1:]:
				#Interaktionen behandeln
				for a in div.findall(".//a"):
					if not a.get("href") is None and a.get("href")[:a.get("href").find("/")] == "interaktion":

						a.set("href", "../../" + a.get("href"))

				#Bilder allgemein behandeln
				for img in div.findall(".//img"):

					#Pfade von Bilddateien könnten unterschiedlich relativiert sein
					#erstmal werden alle gleich gemacht

					if (img.get("src") != None and img.get("src")[:6] != "../../"):
						img.set("src", "../../" + img.get("src"))


				for flashrahmen in div.findall(".//div[@class='flashrahmen']"):
					param = flashrahmen.find(".//param[@name='movie']")
					param.set("value", "../../" + param.get("value"))

					embed = flashrahmen.find(".//embed")
					embed.set("src", "../../" + embed.get("src"))

				for videorahmen in div.findall(".//video"):
					for source_tag in videorahmen.findall(".//source"):
						source_tag.set("src", "../../" + source_tag.get("src"))

				for iframe in div.findall(".//iframe"):
					iframe.set("src", "../../" + iframe.get("src"))
					
		return content
