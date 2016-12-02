"""	
	tex2x converter - Processes tex-files in order to create various output formats via plugins
	Copyright (C) 2015  VEMINT-Konsortium - http://www.vemint.de

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
"""
"""
Todo:
- Das Plugin kann nur den letzten Ordner der Struktur anlegen (rest muss existieren)
- Checken, ob der Output-Ordner leer ist, sonst [Abfrage/ Fehlermeldung]
- Funktion schreiben: make-Ordner-Struktur
"""

import os
#from . import System
from plugins.basic import Option_html_basic as op
from tex2x import System
from lxml import etree
from lxml import html
from copy import deepcopy
from lxml.html import html5parser
import fnmatch


#Import des "Quasi-Interfaces"
#from . import basePluginVEMINT
from AbstractBasicPlugin import *

class Plugin(AbstractBasicPlugin):
	'''
	classdocs
	'''

	name = "HTML_basic"
	
	def __init__(self):
		pass
	 
	def create_output(self):
		"""
		Diese Funktion ist die Oberfunktion zur Erzeugung des Ausgabeformats
		In diesem Fall ist das Ziel HTML5
		"""
		print("Plugin " + Plugin.name + " wird ausgeführt...")
		
		basePlugin.options = op.Option("..")


		#Plugin.required_interactions = struct.required_interactions
		Plugin.required_interactions = list()#TODO: Liste besorgen
		Plugin.required_swf_files = list()#TODO: Liste besorgen
		Plugin.required_video_files = list()#TODO: Liste besorgen
		
		# Paths checks belong in the build system (makefiles), not in the classes providing functionality
		# self.check_if_dir_preexists(Plugin.options.targetpath)

		self.create_xml_files(Plugin.options.targetpath)
		self.create_modstart_files()
		
		self.copy_required_files()
		

	
	def copy_required_files(self):
		"""
		Kopiert alle nötigen Dateien für das HTML5 Format in den Zielordner
		
		Zusätzlich wird für im xml referenzierte Dateien eine Warnmeldung ausgegeben,
		falls diese nicht im Quellordner gefunden werden
		"""	 
		
		#alle HTML-Grunddateien kopieren
		System.copyFiletree(Plugin.options.sourcePlugin, Plugin.options.targetpath, "")
		#diese eine Datei wollen wir nicht in dem Verzeichnis haben (aber es ist leichter diese nachträglich zu löschen
		#als explizit alle gewünschten Dateien anzugeben oder jeder Datei vor dem Kopieren mit einer Blacklist zu vergleichen
		#d.h. solange es bei dieser einen Datei bleibt... (überhaupt nötig, wenn sie später überschrieben wird?)
		System.removeFile(os.path.join(Plugin.options.targetpath, "modstart.xhtml"))  
		
		# Copying files is best handled by the build scripts.
		# Python scripts should be concerned about converting files, not moving them around
		
		#Benötigte Bilder kopieren
		#for tupel in Plugin.required_images:
		#	for image in tupel[1]:
		#		if os.path.exists(os.path.join(Plugin.options.sourceCommonFiles, "images", image)):
		#			System.copyFile(Plugin.options.sourceCommonFiles, Plugin.options.targetpath, os.path.join("images", image))
		
		# What is meant by "interactions"?
		
		#Benötigte Interaktionen kopieren
		for tupel in Plugin.required_interactions:
			for interaction in tupel[1]:
				if os.path.exists(os.path.join(Plugin.options.sourceCommonFiles, "interaktion", interaction)):
					System.copyFile(Plugin.options.sourceCommonFiles, Plugin.options.targetpath, os.path.join("interaktion", interaction))

		# Flash should not be used, as dead
		
		#Kopiere benötigte swf-Files			
		#for tupel in self.required_swf_files:
		#	for interaction in tupel[1]:
		#		if os.path.exists(os.path.join(Plugin.options.sourceCommonFiles, "swf", interaction)):
		#			System.copyFile(Plugin.options.sourceCommonFiles, Plugin.options.targetpath, os.path.join("swf", interaction))
		#		else:
		#			print("Die Datei " + os.path.abspath(os.path.join(Plugin.options.sourceCommonFiles, "swf", interaction)) + " wird benötigt, liegt aber nicht vor.")
		
		#Kopiere benötigte Video-Files			
		#for tupel in Plugin.required_video_files:
		#	for video in tupel[1]:
		#		if os.path.exists(os.path.join(Plugin.options.sourceCommonFiles, "video", video[:video.rindex(".")], video)):
		#			System.copyFile(Plugin.options.sourceCommonFiles, Plugin.options.targetpath, os.path.join("video", video[:video.rindex(".")], video))
		#		else:
		#			print("Die Datei " + os.path.abspath(os.path.join(Plugin.options.sourceCommonFiles, "video", video[:video.rindex(".")], video)) + " wird benötigt, liegt aber nicht vor.")
	
			
	def create_modstart_files(self):
		"""
		Legt alle Modstart-Dateien zu den Modulen in den entsprechenden Verzeichnissen an.
		"""
		
		#Wir zählen die Bereiche in den Dateien
		blocks = dict()
		 
		for tupel in Plugin.content:
			if not tupel[0] in blocks:
				blocks[tupel[0]] = dict()
				
			count = 1
			for span in tupel[1].findall(".//span[@id='lo_status']"):
				count += 1
			
			blocks[tupel[0]][tupel[1].get("class")] = count
				
		#Laden der Template modstart.xhtml
		#zuzüglich allgemeiner Ergänzungen
		modstart_xmlfile = open(os.path.join(Plugin.options.sourcePlugin, "modstart.xhtml"), "rb")
		parser = html.HTMLParser()
		modstart_template = etree.parse(modstart_xmlfile,parser).getroot()
		modstart_xmlfile.close()
		head = modstart_template.find(".//head")
		title = modstart_template.find(".//title")
		inhalt = modstart_template.find(".//div[@id='inhalt']")
		
		#Notwendig, um Informationen über die vorhandenen bereiche abzulegen
		script_tag = etree.Element("script")
		script_tag.set("type", "text/javascript")
		head.append(script_tag)
		
		#Inhaltsverzeichnis am linken Rand 
		main_toc = etree.Element("ul")
		main_toc.set("class", "level1")
		main_toc.set("id", "navstart")
		
		
		for toc_node in self.tocxml.iterchildren():
			self.create_main_toc(1, main_toc, toc_node, Plugin.options.targetpath)#ist rekursiv
		#main_toc enthält jetzt die Menüstruktur für den linken Rand
		
		
		inhalt.clear()
		inhalt.set("id", "inhalt")
		inhalt.append(main_toc)
		inhalt.append(etree.Element("br"))
		
		
		#Das Javascript-Array zu Beginn der modstart.xhtml wird im Folgenden generiert
		for toc_node in self.tocxml.findall(".//*"):
			array_text = "var bereiche = new Array(\n"
			first = True
			

			if toc_node in blocks:
				for mod_struct in Plugin.options.ModuleStructure:			  
					
					mod_structure = None
					for modname in blocks[toc_node].keys():
						if modname == mod_struct[0]:
							mod_structure = mod_struct
							break;
						
					if not first:
						array_text += ",\n"
					else:
						first = False		
						
					if mod_structure == None:
						array_text += '["empty", "empty", [0]]';#Dummy für nicht vorhandenes Untermodul
						continue
					
					
					
					array_text += '["' + mod_structure[1] + '","' + modname + '",[0'
					for i in range(1, blocks[toc_node][modname]):
						array_text += ",0"
						
					array_text += "]]"
						
				
			array_text += ")\n"				
			script_tag.text = array_text
			
			
			#Spezifischen Titel für die Modstart generieren
			#Wir gehen den Pfad durch die Inhaltsstruktur rückwärts, um
			#den vollständigen Titel ohne großen Aufwand zu erhalten 
			tmp = toc_node
			title.text = None
			while (tmp != None):
				if tmp.text != None:
					if title.text == None:
						title.text = tmp.text
					else:
						title.text = tmp.text + " - " + title.text
				tmp = tmp.getparent()
						
		  
			if os.path.exists(os.path.join(Plugin.options.targetpath, "xml/" + toc_node.get("name"))):
				fobj = open(os.path.join(Plugin.options.targetpath, "xml/" + toc_node.get("name") + "/modstart.xhtml"), "w")
				fobj.write(etree.tostring(modstart_template, pretty_print = True).decode())
				fobj.close()
				
			
			