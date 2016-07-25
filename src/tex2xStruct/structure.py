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
"""

from . import Option as op
import os
import time
import re
from lxml import html
from lxml import etree
from copy import deepcopy
from lxml.html import html5parser
from io import StringIO
from plugins.exceptions import PluginException
import subprocess
from . import System as TSystem
import imp
import json
import traceback
import sys
import subprocess


import plugins


# note: imports must be early (before having copied all the files to
# temporary directories), otherwise all the relative paths will be wrong (= set
# to the temporary directories), and important files from BASE_DIR cannot be
# found
from tex2x.parsers.TTMParser import TTMParser




class Structure(object):
    '''
    Die Aufgabe der Strukturklasse ist es eine xml Datei zu parsen,
    einige allgemeine Bearbeitungsschritte durchzuführen und die aufbereiteten Elemente
    für die Plugins zur weiterverarbeitung zu erläutern. Im Folgenden werden dabei einzelne
    Verarbeitungsschritte erläutert, sowie im Zuge dieser etablierte Datenstrukturen. (Dabei
    verlässt sich dieses Skript auf einige inhaltliche Strukturen der XML-Datei!!!)


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

    '''


    def __init__(self):
        '''
        Constructor
        '''



    def startTex2x(self, verbose, plugin_name, override):
        """
        Wird vom Konstruktor aufgerufen und leitet die Verarbeitung der Materialien ein.
        Zusätzlich werden die Optionen aus der Option-Klasse eingebunden und berücksichtigt.
        Die Bearbeitung erfolgt dabei im Groben nach folgenden Schritten:

        * Aus den tex-Sourcen per ttm eine xml-Datei erzeugen

        * xml-Datei einlesen

        * Aus xml-Datei Strukturen herstellen (Kapitel, Module, Inhaltsverzeichnis, Lösungen, etc.)

        * Prüfen der benötigten Quelldateien auf Vollständigkeit im input-Ordner

        * Erstellen der verschiedenen Ausgabeformate anhand der in den Optionen spezifizierten Plugins
        """

        currentDir = ".."

        """
        --------------------- BEGIN DEFINITION OF THE MODULE INTERFACE ------------------------------------------------------

        INITIALIZE INTERFACE DATA MEMBER, WHICH SERVES AS THE SOLE COMMUNICATION INTERFACE TO LINKED MODULES
        AS DESCRIBED IN THE tex2x LICENSE. LINKED MODULES (PLUGINS) MAY ONLY USE THE FOLLOWING DATA MEMBERS
        FOR COMMUNICATION AND FUNCTION CALLS:

        """
        self.interface = dict()

        # data member: linked modules may READ/WRITE/CHANGE/DELETE elements of the data member,
        # added elements must not contain functions or code of any kind.
        self.interface['data'] = dict()

        # options member: A module exposing a class "Option", linked modules must provide the class definition and may READ but not modify data exposed by this object reference
        # class Options must be under LGPL or GPL license
        try:
            options_file = "Option.py"
            for ov in override:
                m = re.match(r"(.+?)=(.+)", ov)
                if m.group(1) == "options":
                    options_file = m.group(2) # should be located in same directory as the generic option object for the plugin
            module = imp.load_source(plugin_name, os.path.join("plugins", plugin_name, options_file))
            self.interface['options'] = module.Option(currentDir, override)
        except Exception:
            formatted_lines = traceback.format_exc().splitlines()
            if formatted_lines[-1].find("AttributeError: 'module' object has no attribute 'Option'") < 0:
                print(traceback.format_exc())
            else:
                print("\nCannot load options of plugin '" + plugin_name + "'.\n")
            self.interface['options'] = None

        # system member: A module exposing a class "System", linked modules may provide the class definition and may CALL functions exposed by this object reference
        # class System must be under GPL license
        try:
            module = imp.load_source(plugin_name, os.path.join("plugins", plugin_name, "system.py"))
            self.interface['system'] = module.System(self.interface['options'])
        except Exception:
            formatted_lines = traceback.format_exc().splitlines()
            if formatted_lines[-1].find("AttributeError: 'module' object has no attribute 'System'") < 0:
                print(traceback.format_exc())
            else:
                print("\nCannot load System facility of plugin '" + plugin_name + "', using system from tex2x\n")

            self.interface['system'] = TSystem

        # preprocessor_plugins member: A list of modules exposing a class "Preprocessor" which has a function "preprocess"
        try:
            self.interface['preprocessor_plugins'] = []
            for p in self.interface['options'].usePreprocessorPlugins:
                module = imp.load_source(plugin_name + "_preprocessor_" + p, self.interface['options'].pluginPath[p])
                self.interface['preprocessor_plugins'].append(module.Preprocessor(self.interface))
        except Exception:
            formatted_lines = traceback.format_exc().splitlines()
            if formatted_lines[-1].find("AttributeError: 'module' object has no attribute 'Preprocessor'") < 0:
                print(traceback.format_exc())
            else:
                print("\nCannot load preprocessor plugins for '" + plugin_name + "'.\n")
            self.interface['preprocessor_plugins'] = []

        # output_plugins member: A list of modules exposing a class "Plugin" which has a function "create_output"
        try:
            self.interface['output_plugins'] = []
            for p in self.interface['options'].useOutputPlugins:
                module = imp.load_source(plugin_name + "_output_" + p, self.interface['options'].pluginPath[p])
                self.interface['output_plugins'].append(module.Plugin(self.interface))
        except Exception:
            formatted_lines = traceback.format_exc().splitlines()
            if formatted_lines[-1].find("AttributeError: 'module' object has no attribute 'Plugin'") < 0:
                print(traceback.format_exc())
            else:
                print("\nCannot load output plugins for '" + plugin_name + "'.\n")
            self.interface['output_plugins'] = []

        # simplify access
        self.options = self.interface['options']
        self.sys = self.interface['system']
        self.data = self.interface['data']


        # --------------------- END DEFINITION OF THE MODULE INTERFACE ------------------------------------------------------


        if hasattr(self.options, "overrides"):
            for ov in self.options.overrides:
                self.sys.message(self.sys.VERBOSEINFO, "tex2x called with override option: " + ov[0] + " -> " + ov[1])


        schritt = 1
        total_time = 0;

        if verbose:
            time_start = time.time()

        #Preprocessing aus den Plugins aktivieren
        for pp in self.interface['preprocessor_plugins']:
            pp.preprocess()

        if verbose:
            time_end = time.time()
            time_diff = time_end - time_start
            print("Schritt " + str(schritt) + ": " + str(time_diff) + "s")
            print("Preprocessing starten\n")
            total_time += time_diff
            schritt += 1

        if verbose:
            time_start = time.time()

        #ttm starten - xml-Vorlage erzeugen
        if self.options.ttmExecute:
            self.start_ttm()
        else:
            self.prepare_xml_file()



        if verbose:
            time_end = time.time()
            time_diff = time_end - time_start
            print("Schritt " + str(schritt) + ": " + str(time_diff) + "s")
            print("ttm starten\n")
            total_time += time_diff
            schritt += 1

        #XML parsen
        if verbose:
            time_start = time.time()

        try:
            xmlfile = open(self.options.ttmFile, "rb")
            xmltext = xmlfile.read().decode( 'utf8', 'ignore' ) # force utf8 here, otherwise it won't build
            xmlfile.close()
            self.sys.message(self.sys.VERBOSEINFO, "Successfully decoded xml output")
        except:
            # old ttm produces latin1 encoded xml if given tex was latin1
            self.sys.message(self.sys.CLIENTINFO, "Could not decode xml output as utf8, trying encoding " + self.options.stdencoding)
            xmltext = self.sys.readTextFile(self.options.ttmFile, self.options.stdencoding)

        #MathML manuell optimieren, da die Ausgabe des ttm nicht ausreichend ist
        xmltext = self.optimize_mathml(xmltext)

        if verbose:
            time_end = time.time()
            time_diff = time_end - time_start
            print("Schritt " + str(schritt) + ": " + str(time_diff) + "s")
            print("(Optimiere MathML aus dem ttm per RegEx) \n")
            total_time += time_diff
            schritt  += 1

        #Vor dem Parsen werden alle Entities durch die neuen Versionen ersetzt
        xmltext = self.replace_html_entities(xmltext)

        # include raw xml text for plugins
        self.data['rawxml'] = xmltext

        #parser = html5lib.HTMLParser(tree=treebuilders.getTreeBuilder(self.options.parserName))
        #self.xmltree_raw = parser.parse(xmlfile)

        parser = html.HTMLParser(remove_blank_text = False)
        #self.xmltree_raw = etree.parse(StringIO(xmltext),parser)

        self.xmltree_raw = etree.fromstring(xmltext, parser)
        #self.xmltree_raw = html5parser.fromstring(xmltext)
        #self.xmltree_raw = html5parser.document_fromstring(xmlfile.read())

        self.sys.timestamp("XMLTree parsed")

        if verbose:
            time_end = time.time()
            time_diff = time_end - time_start
            print("Schritt " + str(schritt) + ": " + str(time_diff) + "s")
            print("(Entities durch HTML5 konforme Entities ersetzen und XML parsen) \n")
            total_time += time_diff
            schritt  += 1

        #Inhaltsverzeichnis erstellen und Inhalt zusammenschneiden
        if verbose:
            time_start = time.time()


        self.create_toc_and_disect_content()
        self.sys.timestamp("toc/content created")

        if verbose:
            time_end = time.time()
            time_diff = time_end - time_start
            print("Schritt " + str(schritt) + ": " + str(time_diff) + "s")
            print("(Inhaltsverzeichnis erstellen und Content-Blöcke passend dazu ausschneiden)\n")
            total_time += time_diff
            schritt += 1

        #Erstellen einer Liste mit den tatsächlich benötigten Bild-Dateien
        if verbose:
            time_start = time.time()

        self.required_images = self.get_required_images(self.content)

        if verbose:
            time_end = time.time()
            time_diff = time_end - time_start
            print("Schritt " + str(schritt) + ": " + str(time_diff) + "s")
            print("(Erstellen einer Liste aller tatsächlich benötigter Bilder im Inhaltsbereich)\n")
            total_time += time_diff
            schritt += 1

        #Pfade im Inhalt müssen der Verzeichnisstruktur angepasst werden
        if verbose:
            time_start = time.time()

        if not hasattr(self.options, "nolinkcorrection"): self.options.nolinkcorrection = 0
        if self.options.nolinkcorrection == 0:
            self.correct_path_to_linked_files(self.content)
        else:
            self.sys.message(self.sys.VERBOSEINFO, "tex2x link correction not requested by options")

        if verbose:
            time_end = time.time()
            time_diff = time_end - time_start
            print("Schritt " + str(schritt) + ": " + str(time_diff) + "s")
            print("(Korrektur von Bild- und Interaktionspfaden)\n")
            total_time += time_diff
            schritt += 1

        #Quelldaten auf Vollständigkeit prüfen
        #Das sollte von den Plugins selbst gemacht werden, da nicht klar ist, was noch alles benötigt wird
        #und ob so ein Check gewollt ist
        """
        if verbose:
            time_start = time.time()

        self.verify_existence_of_required_files()

        if verbose:
            time_end = time.time()
            time_diff = time_end - time_start
            print("Schritt " + str(schritt) + ": " + str(time_diff) + "s")
            print("(Quelldaten auf ihre Vollständigkeit hin prüfen)\n")
            total_time += time_diff
            schritt += 1
        """

        #Plugins starten

        if verbose:
            time_start = time.time()

        self.start_plugins(plugin_name);

        if verbose:
            time_end = time.time()
            time_diff = time_end - time_start
            print("Schritt " + str(schritt) + ": " + str(time_diff) + "s")
            print("Plugins ausführen\n")
            total_time += time_diff
            schritt += 1


        if verbose:
            print("Total time: " + str(total_time))

        # stop program execution and return proper error level as return value
        self.sys.finish_program()


    def create_toc_and_disect_content(self):
        """
        Extrahiert aus dem XML-Baum die Struktur des Inhaltsverzeichnisses (Inhalts-Struktur-Tags werden in den Optionen definiert)
        Da sie Struktur extrem flexibel sein soll,
        wird das Inhaltsverzeichnis als XML-Baum erstellt.

        Gleichzeitig werden die Inhalte entsprechend geteilt und in einer Liste abgelegt,
        deren Elemente folgende Struktur haben: [toc_node, content_node].
        So ist jeder Schnippsel einem Knoten im Inhaltsverzeichnis zugeordnet.

        Zusätzlich werden beim Zerschneiden zwei zusätzliche Modulteile erstellt: Visualisierungen und Info (vgl. Module der VEMINT-CD).
        """

        #Kopie, um Schreibweise zu verkürzen
        contentStructure = self.options.ContentStructure

        root = self.xmltree_raw
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
                if node.get("class") != None and self.options.ModuleStructureClass in node.get("class") and node.get("class").index(self.options.ModuleStructureClass) == 0:
                    #Jetzt sehen wir uns die Zahl an, die in der Klasse mit angegeben wird
                    number = ""
                    if (len(node.get("class")) > len(self.options.ModuleStructureClass)):
                        try:
                            int(node.get("class")[len(self.options.ModuleStructureClass):])#Test auf Integer
                            number = node.get("class")[len(self.options.ModuleStructureClass):]#wir benutzen die Nummer anschließend als String weiter
                        except:
                            print("Fehler beim Parsen der xcontent-Nummer")
                    else:
                        self.sys.message(self.sys.CLIENTWARN, "Dissection found class " + self.options.ModuleStructureClass + ", but without a number")



                    content_node = deepcopy(node)

                    content.append([toc_node, content_node])
                    continue


            #letzten level merken, um oben zu wissen, wie viele Ebenen gewechselt werden
            if (level != -1):
                previous_level = level
                previous_node = toc_node

        #Objetkvariable setzen
        self.tocxml = toc
        self.content = content


    def get_required_images(self, content):
        """
        :param content: zu analysierende content-Liste
        :returns: image-Liste -- Liste der benötigten Bilddateien im Format [toc_node, Dateiname]

        Ermittelt alle benötigten Bilddateien. Anhand dieser Informationen können Plugins entscheiden, welche
        Dateien kopiert werden müssen. Zusätzlich kann so die Vollständigkeit der Quelldateien geprüft werden.

        Die Auflistung ist Modulweise, damit z.B. das Scorm-Plugin pro Paket nur die im Modul benötigten
        Bilddateien zuordnet und kopiert.
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

    def start_plugins(self, plugin_name):
        """
        :param target: Plugin mit dessen Hilfe die Ausgabe erzeugt werden soll

        Lädt alle Plugins im Pluginverzeichnis und startet diese.
        """

        self.data['content'] = self.content
        self.data['tocxml'] = self.tocxml
        self.data['required_images'] = self.required_images

        #Daten hier "löschen"
        self.content = None
        self.tocxml = None
        self.required_images = None


        #Preprocessing aus den Plugins aktivieren
        for op in self.interface['output_plugins']:
            op.create_output()

        #Temporäre Dateien aufräumen
        if self.options.cleanup == 1:
            self.clean_up();


    def replace_html_entities(self, text):
        """
        :param text: String -- Text, in welchem die HTML-Entitäten bearbeitet werden sollen
        :returns: String -- Text mit bereinigten Entitäten

        Diese Funktion entfernt alle alten HTML-Entitäten und ersetzt diese
        durch HTML5 konforme Entitäten.
        """
        #print(text)
        #text = text.decode()

        #Liste Lesen und verarbeiten
        fobj = open(os.path.join(self.options.currentDir,"src", "entity_list.txt"), "r")
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

        fobj.close();
        #Bearbeiteten Text zurückgeben
        return text








    def correct_path_to_linked_files(self, content):
        """
        :param content: content-Liste -- content-Liste der Inhalte deren Pfade korrigiert werden sollen.

        Bilder und Interaktionen liegen in einem gemeinsamen Verzeichnis auf einer
        höheren Ebene als die html/xml Dateien. Das kann auf der tex-Ebene noch nicht berücksichtigt werden und wird
        an dieser Stelle korrigiert.
        """
        """
        TODO: Derzeit handelt es sich konstant um 2 Ebenen. Das sollte jedeoch anhand der Position der zugehörigen toc_node
        im Inhaltsverzeichnis dynamisch korrigiert werden.
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


    def verify_existence_of_required_files(self):
        """
        Überprüft, ob die als benötigt ermittelten Dateien im Dateisystem vorhanden sind.

        .. note::
            Pluginspezifische Dateien werden hier noch nicht erfasst!
            (z.B. das imsmanifest.xml-Template des VEMINT.SCORM-Plugins)
        """
        #Grafiken checken
        for tupel in self.required_images:
            for image in tupel[1]:
                if not os.path.exists(os.path.join(self.options.sourceCommonFiles, "images", image)):
                    print("Achtung: Die Datei " + os.path.join(self.options.sourceCommonFiles, "images", image) + " wurde im Quellverzeichnis nicht gefunden. Wird jedoch im Modul " + tupel[0].get("name") + " verwendet.")




    def start_ttm(self):
        """
        Ruft den ttm per Kommandozeile auf und erzeugt so eine xml-Datei aus den Tex-Sourcen.

        .. note::
            Achtung:  ein externes Programm wird hier aufgerufen, das lässt sich
            theoretisch bösartig ausnutzen, wenn man den ttm ersetzt.
        """
        #Wenn der ttm nicht als ausführbar markiert wurde, kann es zu Problemen kommen
        #also checken wir das vorher
        if not os.access(os.path.join(self.options.ttmPath, "ttm"), os.X_OK):
            self.sys.message(self.sys.FATALERROR, "ttm program file is not marked as executable, aborting")

        #Sicherstellen, dass Outputdirecotry existiert
        if not os.path.exists(self.options.targetpath):
            os.makedirs(self.options.targetpath)
        
        #ttm starten

        ttm_parser = TTMParser()
        ttm_parser.parse(sys=self.sys)


    def prepare_xml_file(self):
        """
        Stellt sicher, dass die benötigte xml-Datei im Outputverzeichnis liegt. Sonst wird diese vom ttm erzeugt.
        """
        if (os.path.exists(self.options.sourceTEXStartFile)):
            self.sys.copyFile(self.options.sourceTEXStartFile, self.options.ttmFile, "")
        else:
            print("Es konnte keine XML-Datei als Vorgabe gefunden werden, daher wird nun (trotz gegenteiliger Angabe in den Optionen) der ttm ausgeführt.")
            self.start_ttm()









    def optimize_mathml(self, xmltext):
        """
        Optimiert MathML nachträglich weiter, nachdem der ttm es erzeugt hat.
        """

        pattern = r"<mn>(?P<a>[0-9]*)</mn><mo>,</mo><mn>(?P<b>[0-9]*)</mn>"
        replace = r"<mn>\g<a>,\g<b></mn>"
        xmltext = re.sub(pattern, replace, xmltext)

        #xmltext = "<mn>1</mn><mo>,</mo><msup><mrow><mn>001</mn></mrow><mrow><mn>2</mn></mrow></msup>"

        pattern = r"<mn>(?P<a>[0-9]*)<\/mn><mo>,</mo>[\n|\r]*<msup><mrow><mn>(?P<b>[0-9]*)</mn></mrow><mrow><mn>(?P<c>[0-9])</mn></mrow>[\n|\r]*</msup>"
        replace = r"<msup><mrow><mn>\g<a>,\g<b></mn></mrow><mrow><mn>\g<c></mn></mrow>\n</msup>"
        xmltext = re.sub(pattern, replace, xmltext)

        #s/<mtable([^>]+)>/<mtable>/g;
        pattern = r"<mtable[^>]+>"
        replace = r"<mtable>"
        xmltext = re.sub(pattern, replace, xmltext)



        if not hasattr(self.options, "keepequationtables"): self.options.keepequationtables = 0
        if self.options.keepequationtables == 0:
            pattern = r"<table width=\"100%\"><tr><td align=\"center\">(?P<a>\s*(<math(.|\n)*?</math>)\s*)</td></tr></table>"
            replace = r"<center>\g<a></center>"
            xmltext = re.sub(pattern, replace, xmltext)

        """Kein Effekt
        #Das Zeichen \subsetneq kennt ttm nicht
        pattern = r"\\subsetneq"
        replace = r"<mtext>&#8842;</mtext>"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]
        """

        """Kein Effekt
        #mathbb-Zeichen (Reals, Integers, usw)
        pattern = r"\\mathbb<mi>(?P<a>[A-Za-z])</mi>"
        replace = r"<mo>&\g<a>1opf;</mo>"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]
        """

        #Ab hier werden übertrieben große Abstände verringert
        """Kein Effekt
        pattern = r"<mi>&emsp;</mi>"
        replace = r"<mi>&nbsp;</mi>"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]
        """
        """Kein Effekt
        pattern = r"<mi>&emsp;&emsp;</mi>"
        replace = r"<mi>&nbsp;&nbsp;</mi>"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]
        """

        pattern = r"<mi>&emsp;&emsp;&emsp;</mi>"
        replace = r"<mi>&nbsp;&nbsp;&nbsp;</mi>"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]

        pattern = r"<mi>&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;</mi>"
        replace = r"<mi>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</mi>"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]

        #\empty ist kein Integer, sondern Text
        pattern = r"<mi>&empty;</mi>"
        replace = r"<mtext>&empty;</mtext>"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]

        """replacetd()-Fkt gibt es nicht.. vielleicht ist das hier auch inzwischen überflüssig. FF geht auch so, IE wird noch getestet
        #Bei Tabellen mit Rahmen sollen auch die Zellen Rahmen haben
        pattern = r"<table border=\"1\">((.|\s)*?)</table>"
        replace = r""#"r"replacetd($1)"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]
        """

        #Probleme mit dem nicht-Teilbarkeitszeichen beheben
        pattern = r"&nmid;"
        replace = r"<mo>∤</mo>"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]


        #Probleme mit dem nicht-Orthogonalitätszeichen beheben
        pattern = r"</mi>\s*&nparallel;\s*<mi>"
        replace = r" ∦ "
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]

        #Probleme mit vertikalen Punkten beheben
        pattern = r"<mrow>:</mrow>"
        replace = r"<mo>&#8942;</mo>"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]

        #umgehe tex fehler in 5.2.1_grenzwertefunktionen.tex
        #TODO: Tex-Quelle reparieren
        pattern = r"<mstyle fontweight=\"bold\">h</mstyle>"
        replace = r"h"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]



        #Probleme Ableitungen 2. Grades beheben
        pattern = r"</mi>\"<mo stretchy"
        replace = r"</mi><mo>'</mo><mo>'</mo><mo stretchy"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]


        #Probleme Ableitungen 3. Grades beheben
        pattern = r"</mi>\"<mo>'</mo><mo stretchy"
        replace = r"</mi><mo>'</mo><mo>'</mo><mo>'</mo><mo stretchy"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]

        #Problem mit Ableitung 2. Grades ohne Klammern - wichtig darf erst nach der Behebung des Problems mit 3. Ableitung erfolgen
        pattern = r"<mi>f</mi>\""
        replace = r"<mi>f</mi><mo>'</mo><mo>'</mo>"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]

        #Problem mit Ableitung 2. Grades ohne Klammern - wichtig darf erst nach der Behebung des Problems mit 3. Ableitung erfolgen
        pattern = r"<mi>g</mi>\""
        replace = r"<mi>g</mi><mo>'</mo><mo>'</mo>"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]

        #4.2.1 Hinführung: Kästen werden nicht richtig dargestellt
        pattern = r"&square;"
        replace = r"<mo>□</mo>"
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]

        #4.3.6 Hinführung: a''
        pattern = r"<mrow>\"</mrow>"
        replace = r'<mrow><mi>"</mi></mrow>'
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]

        #5.4.2-24 ä wird vom ttm als Operator interpretiert
        pattern = r"</mi>&#228;<mi fontstyle=\"italic\">"
        replace = r'&#228;'
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]

        #5.4.2-24 ö wird vom ttm als Operator interpretiert
        pattern = r"</mi>&#246;<mi fontstyle=\"italic\">"
        replace = r'&#246;'
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]

        #7.1.2 - ∦ wird nicht als "Operator" erkannt
        """
        pattern = r"∦"
        replace = r'<mo>∦</mo>'
        t = re.subn(pattern, replace, xmltext)
        xmltext = t[0]
        """
        #Diese Zeile kann nach dem Ersetzen genutzt werden, um mitgeteilt zu bekommen, wie viele Ersetzungen stattfanden
        #print("##########zahl: " + str(t[1]))


        return xmltext;


    def save_parsed_content_to_file(self):
        #TODO: prüfen, ob tmp Verzeichnis existiert, falls ja warnen

        #Tempverzeichnis leeren (Reste stören sonst den Ladevorgang der Plugins
        if os.path.exists(self.options.targetpathTemp):
            self.sys.removeTree(self.options.targetpathTemp)
        self.sys.makePath(self.options.targetpathTemp)#Verzeichnis anlegen, existierte nicht oder wir haben es gerade gelöscht


        #tocxml in Datei ablegen
        tocxml_tmp_filename = os.path.join(self.options.targetpathTemp, "tocxml.xml")
        print(tocxml_tmp_filename)
        with open(tocxml_tmp_filename,"wb+") as f:
            f.write(etree.tostring(self.tocxml))

        #Ordner-Struktur im tmp-Verzeichnis anlegen
        for node in self.tocxml.iter():
            if (not node.get("name") == None) and (not os.path.exists(os.path.join(self.options.targetpathTemp, node.get("name")))):
                self.sys.makePath(os.path.join(self.options.targetpathTemp, node.get("name")))

        for tupel in self.content:
            i = 0
            for xmltree in tupel[1:]:
                xmltree.tail = ""
                with open(os.path.join(self.options.targetpathTemp, tupel[0].get("name"),
                                       tupel[1].get("class") + "_" + str(i) + ".xml"),"wb+") as f:
                    f.write(etree.tostring(xmltree))


        with open(os.path.join(self.options.targetpathTemp, "test.json"),"w+") as f:
            json.dump(self.data, f)

    def clean_up(self):
        """
        Wir räumen wieder auf. Insbesondere das temporäre Input-Verzeichnis wird wieder gelöscht.
        """
        print("Räume auf: " + os.path.abspath(self.options.sourcepath))
        self.sys.removeTree(self.options.sourcepath)


    def _checkContentStructure(self, node, tag):
        # check if node tag belongs to the content structure from options AND if it is structure tag generated by ttm
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
