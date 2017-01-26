## @package plugins.VEUNDMINT_TUB.generators.ContentGenerator
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

from copy import deepcopy
from lxml import etree
from tex2x.AbstractGenerator import AbstractGenerator
from tex2x.System import ve_system as sys
from tex2x.Settings import settings

class ContentGenerator( AbstractGenerator ):
	"""
	Run the ContentGenerator to create the table of contents and the content tree.
	Instantiated by the Dispatcher.
	Can be decorated with VerboseParser to enable performance logging.
	"""
	def __init__(self ):
		"""
		Constructor. Needs to overrides the constructor of the abstract base class.
		"""
		pass


	def generate( self, htmltree ):
		"""
		Create the table of contents (TOC) and the content tree.

		Extrahiert aus dem XML-Baum die Struktur des Inhaltsverzeichnisses (Inhalts-Struktur-Tags werden in den Optionen definiert)
		Da sie Struktur extrem flexibel sein soll,
		wird das Inhaltsverzeichnis als XML-Baum erstellt.

		Gleichzeitig werden die Inhalte entsprechend geteilt und in einer Liste abgelegt,
		deren Elemente folgende Struktur haben: [toc_node, content_node].
		So ist jeder Schnippsel einem Knoten im Inhaltsverzeichnis zugeordnet.

		Inhaltsverzeichnis:
		self.tocxml enthält ein aus der xml Datei generiertes Inhaltsverzeichnis in Form von
		etree-xml. Die einzelnen Knoten werden später genutzt, um Referenzen darauf weiterzugeben
		und so schnell Inhalte zu einem Knoten aus dem Inhaltsverzeichnis zuzuordnen. Wichtig ist
		also, dass die Referenzen auf die Knoten zu diesem Zweck weitergereicht werden und nicht
		etwa tiefe Kopien. Plugins sollten daher auf keinen Fall die Objekte am Ende der Referenz
		manipulieren. In menschenlesbarer Form würde der Inhalt von self.tocxml so aussehen:

		\<tableOfContents\>
		  \<h1 name="1"\>Rechengesetze
			  \<h2 name="1.1"\>Ungleichungen
				  \<h3 name="1.1.1"\>Anordnungen\<\/h3\>
			  \<\/h2\>
		  \<\/h1\>
		  \<h1 name="2"\>Analysis
			  \<h2 name="2.1"\>Analysis kompakt
				  \<h3 name="2.1.1"\>Analysis kompakt\<\/h3\>
			  \<\/h2\>
			  \<h2 name="2.2"\>Folgen und Grenzwerte
				  \<h3 name="2.2.1"\>Zahlenfolgen\<\/h3\>
			  \<\/h2\>
		  \<\/h1\>
		\<\/tableOfContents\>


		Inhalte:
		self.content ist eine Liste aller Inhaltsabschnitte. Mit Inhaltsabschnitt ist hier gemeint,
		was in VEMINT bspw. die Hinführung wäre (modgenetisch). Mehrere Inhaltsabschnitte ergeben
		ein Modul und gehören zu einer Referenz auf einen Knoten aus dem self.tocxml. Weiter gehören
		zu einem Inhaltsabschnitt evt. noch Lösungen zu Aufgaben, welche aus dem Inhalt selbst
		extrahiert wurden.
		Ein Element aus der Liste self.content ist also wieder eine Liste und ist wie folgt aufgebaut:
		[toc_node, inhaltsabschnitt, lösung1, lösung2, ... lösungN]
		Dabei ist jedes Element vom Typ etree.Element

		(Es kann auch sein, dass keine Lösungen enthalten waren, dann wäre das obige Listenbeispiel nur
		zwei Elemente lang)

		Die Reihenfolge der Inhaltsabschnitte in self.content entspricht dabei lediglich der
		Reihenfolge der Abschnitte aus der XML-Vorlage.


		Benötigte Inhalte (derzeit Bilder, Interaktionen, swf-Files, adobe-Files):
		Nach dem Zerschneiden, werden die Inhaltsabschnitte nach verlinkten Dateien durchsucht.
		Diese finden sich aufgelistet in den Attributen get_required_X (X entsprechend ersetzen).
		Ein Listenelement besteht wieder aus einer Liste, nach dem Schema: [toc_node, Dateiname]
		Also analog zu self.content.

		@param htmltree - an etree containing parsed HTML
		@return two trees (see explanation in German )
		@author Daniel Haase for KIT
		"""

		#Kopie, um Schreibweise zu verkürzen
		contentStructure = settings.ContentStructure

		root = htmltree
		body = root.find("body")

		if body is None:
			body = root

		toc = etree.Element("tableOfContents")
		toc_node = toc

		previous_level = -1
		content = []

		#print(etree.tostring(body[0], pretty_print = True).decode())

		for node in body[0].iterchildren():
			level = -1;
			for i in range(len(contentStructure)):
				if self._checkContentStructure(node, contentStructure[i]):
					level = i;
					break;


			#level != -1 bedeutet es handelt sich um einen Ebenen-Wechsel
			#und ein Knoten wird zum toc hinzugefügt
			if (level != -1):
				#Wir müssen tiefer in die Struktur hinein
				if (level > previous_level):
					i = previous_level + 1;
					while (i <= level):
						new_element = etree.Element(contentStructure[i])
						toc_node.append(new_element)
						toc_node = new_element
						toc_node.set("level", str(level+1))
						i += 1;

				#Entsprechend viele Ebenen zurück gehen
				if (level <= previous_level):
					i = previous_level
					while (i>=level):
						toc_node = toc_node.getparent()
						i -= 1

					new_element = etree.Element(contentStructure[level])
					toc_node.append(new_element)
					toc_node = new_element
					toc_node.set("level", str(level+1))

				#name Attribut hinzufügen
				#Auf der ersten Ebene sieht das Attribut so aus: name="tth_chAp1"
				if node.tag == contentStructure[0]:
					new_element.set("name", node.getprevious().get("id")[8:])
				else: #sonst so name="tth_sEc1.1.1"
					new_element.set("name", node.getprevious().get("id")[7:])
				#Text zum hinzugefügten Knoten hinzufügen
				new_element.text = ""
				if node.text != None:
					new_element.text = node.text
				elif len(node) > 1 and node[1] != None and node[1].tail != None:
					new_element.text = node[1].tail#Strip ergänzen?
				if (len(node) and node[0].tail != None):
					new_element.text = new_element.text + node[0].tail#Strip ergänzen?

				#Unnötige Leerzeichen werden noch entfernt
				if new_element.text != None:
					new_element.text = new_element.text.strip()


			#Es gab keinen Ebenen-Wechsel
			#haben wir einen Knoten gefunden, der Teil eines Moduls ist?
			if level == -1:
				#Es wurde ein zugehöriges Modul gefunden
				#Modul wird gespeichert mit zugehörigem Knoten aus dem Inhaltsverzeichnis
				if node.get("class") != None and settings.ModuleStructureClass in node.get("class") and node.get("class").index(settings.ModuleStructureClass) == 0:
					#Jetzt sehen wir uns die Zahl an, die in der Klasse mit angegeben wird
					number = ""
					if (len(node.get("class")) > len(settings.ModuleStructureClass)):
						try:
							int(node.get("class")[len(settings.ModuleStructureClass):])#Test auf Integer
							number = node.get("class")[len(settings.ModuleStructureClass):]#wir benutzen die Nummer anschließend als String weiter
						except:
							print("Fehler beim Parsen der xcontent-Nummer")
					else:
						sys.message(sys.CLIENTWARN, "Dissection found class " + settings.ModuleStructureClass + ", but without a number")



					content_node = deepcopy(node)

					content.append([toc_node, content_node])
					continue


			#letzten level merken, um oben zu wissen, wie viele Ebenen gewechselt werden
			if (level != -1):
				previous_level = level
				previous_node = toc_node

		return toc, content


	def _checkContentStructure(self, node, tag):
		"""
		check if node tag belongs to the content structure from options AND if it is structure tag generated by ttm

		@author Daniel Haase
		"""
		if (node.tag == tag):
			try:
				ttmid = node.getprevious().get("id")
				if ttmid[0:4] == "tth_":
					return True
				else:
					# previous node has an id, but it's not from ttm
					return False
			except:
				# has no previous node or previous node has no defined "id"
				return False

			return True
		else:
			return False
