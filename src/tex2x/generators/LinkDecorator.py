## @package tex2x.parsers.LinkDecorator
#  Create the table of contents (TOC) and the content tree.
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

from tex2x.generators.AbstractGenerator import AbstractGenerator

class LinkDecorator( AbstractGenerator ):
	"""
	Add methods to correct where the links in the content point to.
	This class is meant to decorate TOCParser.
	Can be decorated with VerboseDecorator to enable performance logging.
	"""
	
	## PATH_PREFIX
	#  Prefix to add to links and image sources
	PATH_PREFIX = "../"
	
	def __init__(self, generator ):
		"""
		Constructor
		
		@param generator Object extending AbstractGenerator
		"""
		
		## @var generator
		#  Generator (object extending AbstractParser, in this case ContentGenerator)
		self.generator = generator
		
		## @var options
		# simplify access to the interface options member (Daniel Haase) - refactor
		self.options = generator.options
				

	def generate(self, *args, **kwargs):
		"""
		Call the ContentGenerator (the decorated class) and correct the links in the TOC and in the content tree.
		Links, inage sources, embedded video sources and iframe sources are corrected by adding the PATH_PREFIX.
		
		@param content - a list of [toc_node, content_node] items
		@return toc, content - two trees as returned by TOCParser
		"""
		# call the decorated class' parse method
		tempTOC, tempContent = self.generator.generate(*args, **kwargs)
		
		tempContent = self.correct_path_to_linked_files( tempContent )
		tempTOC = self.correct_path_to_linked_files( tempTOC )

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
						a.set("href", LinkDecorator.PATH_PREFIX + a.get("href"))

				#Bilder allgemein behandeln
				for img in div.findall(".//img"):
					img.set("src", LinkDecorator.PATH_PREFIX + img.get("src"))

				for videorahmen in div.findall(".//video"):
					for source_tag in videorahmen.findall(".//source"):
						source_tag.set("src", LinkDecorator.PATH_PREFIX + source_tag.get("src"))

				for iframe in div.findall(".//iframe"):
					iframe.set("src", LinkDecorator.PATH_PREFIX + iframe.get("src"))
					
		return content
