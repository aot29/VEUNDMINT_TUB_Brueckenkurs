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

import os
from tex2xStruct import System
from plugins.basic import Option_scorm_basic as op
from lxml import etree
from lxml import html
from lxml.html import html5parser
from lxml.html import tostring as html_tostring
from copy import deepcopy
import shutil
from plugins.exceptions import PluginException
import fnmatch

from plugins import scorm_packer

#Import des "Quasi-Interfaces"
from plugins.basePlugin import Plugin as basePlugin
class Plugin(basePlugin):
	'''
	classdocs
	'''
	
	name = "SCORM_basic"

	def __init__(self):
		pass
	 
	def create_output(self):
		print("Plugin " + Plugin.name + " wird ausgeführt...")
		
		
		basePlugin.options = op.Option("..")
		
		#Ziel Ordner leer?
		self.check_if_dir_preexists(Plugin.options.targetpath)

		for toc_node in Plugin.tocxml.findall(".//"):
			for tupel in Plugin.content:
				#falls Inhalt zum Übersichtsknoten gehört:
				if tupel[0] == toc_node:
					self.create_module(toc_node)
					break

	def create_module(self, toc_node):
		
		self.make_sure_every_path_exists(toc_node)
		
		pathToFolder = os.path.join(Plugin.options.targetpath, toc_node.get("name"))
		
		
		self.create_xml_files(pathToFolder, toc_node)
		
		self.create_modstart_file(toc_node, pathToFolder, False)
		
		self.copy_required_files(toc_node)
		
		scorm_packer.pack(pathToFolder, toc_node.get("name"),self. get_full_title(toc_node))
	
	
	def make_sure_every_path_exists(self, toc_node):
		"""
		:param toc_node: node -- Inhaltsknoten dessen Pfade geprüft werden sollen
		
		Vor dem Packen der Zip-Pakete, werden alle benötigten Dateien eines Moduls in einem Ordner gesammelt.
		Die Funktion prüft die Existenz der Zielordner, um Probleme beim Kopieren zu vermeiden.
		"""
		if(not os.path.exists(os.path.join(Plugin.options.targetpath, toc_node.get("name")))):
			System.makePath(os.path.join(Plugin.options.targetpath, toc_node.get("name")))
			
		if(not os.path.exists(os.path.join(Plugin.options.targetpath, toc_node.get("name"), "images"))):
			System.makePath(os.path.join(Plugin.options.targetpath, toc_node.get("name"), "images"))
		
		if(not os.path.exists(os.path.join(Plugin.options.targetpath, toc_node.get("name"), "interaktion"))):
			System.makePath(os.path.join(Plugin.options.targetpath, toc_node.get("name"), "interaktion"))
		
		#deprecated sobald, flash vollständig ersetzt wurde	
		if(not os.path.exists(os.path.join(Plugin.options.targetpath, toc_node.get("name"), "swf"))):
			System.makePath(os.path.join(Plugin.options.targetpath, toc_node.get("name"), "swf"))
	
	def create_modstart_file(self, toc_node_wanted, targetPath, with_navigation = True):
		"""
		:param toc_node_wanted: node -- Spezifiziert zu welchen Modul die Modstart-Datei erstellt werden soll
		:param targetPath: Pfad -- Hier wird die Datei erstellt
		:param with_navigation: Boolean -- Optional: Gibt an, ob eine InterModul-Navigationsstruktur eingebunden werden soll (Standard: ja)
		
		Erzeugt eine Modstart-Datei in **targetPath** an zum Inhaltsknoten **toc_node_wanted**.
		"""
		
		#Wir zählen die Bereiche in den Dateien
		blocks = dict()
		 
		for tupel in Plugin.content:
			if tupel[0] == toc_node_wanted:
				count = 1
				for span in tupel[1].findall(".//span[@id='lo_status']"):
					count += 1
				
				blocks[tupel[1].get("class")] = count

		#Hier wird versucht eine redundante Generierung des Inhaltsverzeichnises für den linken Rand (CD Version) zu verhindern
		try:
			main_toc = self.main_toc
		except AttributeError:			
			#Inhaltsverzeichnis am linken Rand generieren
			if with_navigation: 
				main_toc = etree.Element("ul")
				main_toc.set("class", "level1")
				for toc_node in Plugin.tocxml.iterchildren():
					self.create_main_toc(1, main_toc, toc_node, Plugin.options.targetpath)#ist rekursiv
				#main_toc enthält jetzt die Menüstruktur für den linken Rand
				self.main_toc = main_toc
		

						
		#Laden der Template modstart.xhtml
		#zuzüglich allgemeiner Ergänzungen
		
		#parser = html.HTMLParser()
		#modstart_xmlfile = open(os.path.join(Plugin.options.sourcePlugin, "modstart.xhtml"), "rb")
		#modstart_template = etree.parse(modstart_xmlfile,parser).getroot()
		#modstart_template = html.html5parser.fromstring(modstart_xmlfile.read().decode())
		#modstart_xmlfile.close()
		
		modstart_xmlfile = open(os.path.join(Plugin.options.sourcePlugin, "modstart.xhtml"), "rb")
		parser = html.HTMLParser()
		modstart_template = etree.parse(modstart_xmlfile,parser).getroot()
		modstart_xmlfile.close()
		
		
		
		head = modstart_template.find(".//head")
		title = modstart_template.find(".//title")
		evemint_marker = modstart_template.find(".//div[@id='evemint_marker']")
		
		script_tag = etree.Element("script")
		script_tag.set("type", "text/javascript")
		head.append(script_tag)
		
		
		#Das Javascript-Array zu Beginn der mostart.xml wird im Folgenden generiert
		array_text = "var bereiche = new Array(\n"
		first = True
		
		for mod_struct in Plugin.options.ModuleStructure:			  
							 
			mod_structure = None
			for modname in blocks.keys():
				if modname == mod_struct[0]:
					mod_structure = mod_struct
					break;
			
			if not first:
				array_text += ",\n"
				
			if mod_structure == None:
				array_text += '["empty", "empty", [0]]';#Dummy für nicht vorhandenes Untermodul
				continue
			
			
			array_text += '["' + mod_structure[1] + '","' + modname + '",[0'
			for i in range(1, blocks[modname]):
				array_text += ",0"
				
			array_text += "]]"
			
			first = False
			
			
		array_text += ")\n"				
		script_tag.text = array_text
		
		#Jetzt kann es noch sein, dass die modstart.xthml mit zusätzlichen script-Tags
		#angereichert werden muss, um den neuen Flash-Ersatz zum Laufen zu bringen
		#(aus irgendeinem Grund reicht es leider nicht, dies in nachgeladenen Dateien zu tun)
		
		#zuerst aufräumen und alte Script-Tags anderer modstarts (im head-tag) wieder entfernen
		for adobe_script_tag in head.findall(".//script[@class='script_for_adobe']"):
			adobe_script_tag.getparent().remove(adobe_script_tag)
		
		for tupel in Plugin.content:
			#wir suchen die content tupel mit den xml dateien
			if tupel[0] == toc_node_wanted:
				#Gibt es Inhalt?
				if (len(tupel)>1):
					for adobe_script_tag in tupel[1].findall(".//script[@class='script_for_adobe']"):
							#wir achten darauf nichts doppelt einzufügen
							if (head.find(".//script[@src='" + adobe_script_tag.get("src") + "']") is None):
								head.append(adobe_script_tag)
								#print(adobe_script_tag.get("src"));
					if tupel[1].find(".//div[@id='introvideostart']") != None:#Gibt es ein Startbutton für die Materialeinführung in dem Bereich?
						evemint_xmlfile = open(os.path.join(Plugin.options.sourceCommonFiles,"evemint", "evemint_snippet_modstart.txt"), "rb")
						parser = html.HTMLParser()
						evemint_snippet = etree.parse(evemint_xmlfile,parser).getroot()
						evemint_marker.append(evemint_snippet)
						
						required = list()
						for videorahmen in evemint_snippet.findall(".//video"):
							for src_tag in videorahmen.findall(".//source"):
								required.append(os.path.basename(src_tag.get("src")))
											   
						#print(required)
						if len(required) > 0:
							Plugin.required_video_files.append([tupel[0], required])

		
		#Spezifischen Titel für die Modstart generieren
		#Wir gehen den Pfad durch die Inhaltsstruktur rückwärts, um
		#den vollständigen Titel ohne großen Aufwand zu erhalten 
		tmp = toc_node_wanted
		title.text = None
		while (tmp != None):
			if tmp.text != None:
				if title.text == None:
					title.text = tmp.text
				else:
					title.text = tmp.text + " - " + title.text
			tmp = tmp.getparent()
			 
		
		if not os.path.exists(os.path.join(targetPath, "xml/" + toc_node_wanted.get("name"))):
			System.makePath(os.path.join(targetPath, "xml/" + toc_node_wanted.get("name")))
			
		fobj = open(os.path.join(targetPath, "xml/" + toc_node_wanted.get("name") + "/modstart.xhtml"), "w")
		fobj.write(etree.tostring(modstart_template, pretty_print = False).decode())
		fobj.close()
		
	def copy_required_files(self, toc_node):
		"""
		:param toc_node: node -- Modul zu dem die Dateien kopiert werden sollen
		
		Kopiert alle benötigten Dateien eines Moduls in das entsprechende Verzeichnis.
		
		.. note::
			Zur Zeit werden alle Dateien kopiert und anschließend(!)
			die Geogebra-Interaktionen noch mal an Scorm angepasst. Fall direkt in ein Zip-Paket
			geschrieben werden soll, muss das berücksichtigt werden.
		"""
		
		#Pfad zum noch nicht verpackten SCORM-Paket,den brauchen wir gleich noch des Öfteren
		packet_path = os.path.join(Plugin.options.targetpath, toc_node.get("name"))
		
		#Allgemeine Grafiken kopieren
		System.copyFiletree(Plugin.options.sourcePlugin, packet_path, "images")
		
   		# Copying files is best handled by the build scripts.
		# Python scripts should be concerned about converting files, not moving them around

		#Benötigte Bilder des Inhalts kopieren
		#required_images = Plugin.required_images
		
		#for tupel in required_images:
		#	if (tupel[0] == toc_node):
		#		for image in tupel[1]:
		#			if os.path.exists(os.path.join(Plugin.options.sourceCommonFiles, "images", image)):
		#				System.copyFile(os.path.join(Plugin.options.sourceCommonFiles, "images"), os.path.join(packet_path, "images"), image)
  
		# What is meant by "interactions"?

		#Alle benötigten Interaktionen kopieren		
		required_interactions = Plugin.required_interactions
		for tupel in required_interactions:
			if (tupel[0] == toc_node):
				for interaction in tupel[1]:
					if os.path.exists(os.path.join(Plugin.options.sourceCommonFiles, "interaktion", interaction)):
						System.copyFile(os.path.join(Plugin.options.sourceCommonFiles), packet_path, os.path.join("interaktion", interaction))
		

		# Flash should not be used, as dead
						
		#Kopiere benötigte swf-Files
		#required_swf_files = Plugin.required_swf_files
		#for tupel in required_swf_files:
		#	if (tupel[0] == toc_node):
		#		for interaction in tupel[1]:
		#			if os.path.exists(os.path.join(Plugin.options.sourceCommonFiles, "swf", interaction)):
		#				System.copyFile(Plugin.options.sourceCommonFiles, packet_path, os.path.join("swf", interaction))
						
		#Kopiere benötigte Video-Files
		#for tupel in Plugin.required_video_files:
		#	if (tupel[0] == toc_node):
		#		for video in tupel[1]:
		#			if os.path.exists(os.path.join(Plugin.options.sourceCommonFiles, "video",video[:video.rindex(".")], video)):
		#				System.copyFile(Plugin.options.sourceCommonFiles, packet_path, os.path.join("video", video[:video.rindex(".")], video))
						

		
		#CSS-Files kopieren
		System.copyFiletree(Plugin.options.sourcePlugin, packet_path, "css")
		
		#xsd-Files kopieren
		System.copyFiletree(os.path.join(Plugin.options.sourcePlugin, "xsd"), packet_path, "")
		
		#js-Files kopieren
		System.copyFiletree(Plugin.options.sourcePlugin, packet_path, "js")
		
	def get_full_title(self, toc_node):
		node = toc_node
		title_list = list()
		while node.getparent() != None:
			title_list.insert(0, node.text)
			node = node.getparent()
			
		
		first = True
		full_title = ""
		for title in title_list:
			if not first:
				full_title = full_title + " - "
			full_title = full_title + title
			first = False
		
		
		