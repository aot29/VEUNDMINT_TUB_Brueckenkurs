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
import os
from tex2x.parsers.AbstractParser import AbstractParser

class ImageParser( AbstractParser ):
	'''
	Run Images parser.
	Can be decorated with VerboseDecorator to enable performance loging.
	'''
	def __init__(self, options ):
		'''
		@param options Object
		'''
		self.options = options
		

	def parse(self, content):
		'''
		Compile a list of required images
		@param content - a list of [toc_node, content_node] items
		'''
		return self.getRequiredImages( content )


	def getRequiredImages(self, content):
		"""
		Ermittelt alle benötigten Bilddateien. Anhand dieser Informationen können Plugins entscheiden, welche
		Dateien kopiert werden müssen. Zusätzlich kann so die Vollständigkeit der Quelldateien geprüft werden.

		Die Auflistung ist Modulweise, damit z.B. das Scorm-Plugin pro Paket nur die im Modul benötigten
		Bilddateien zuordnet und kopiert.
		
		@param content: zu analysierende content-Liste
		@returns image-Liste -- Liste der benötigten Bilddateien im Format [toc_node, Dateiname]
		@author Daniel Haase
		"""

		required_images = list()
		for tupel in content:
			for div in tupel[1:]:
				required = list()
				for img in div.findall(".//img"):
					#Bild nur hinzufügen, wenn es nicht zur Interaktion gehört
					if img.get("src") != None and img.get("src")[:img.get("src").find("/")] != "interaktion":
						#nur Dateiname, der Pfad wird vernachlässigt
						required.append(os.path.basename(img.get("src")))
					"""
					Passiert an anderer Stelle, da es je nach Tiefe des Inhalts
					gehandhabt werden muss

					#Korrigiere den Datei-Pfad noch bei Bedarf
					if (img.get("src")[:6] != "../../"):
						img.set("src", "../../" + img.get("src"))
					"""
				if len(required):
					required_images.append([tupel[0], required])
		#print((required_images))
		return required_images

