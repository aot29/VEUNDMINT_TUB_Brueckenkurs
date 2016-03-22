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
Python bietet derzeit keine Möglichkeit abstrakte Klassen oder Interfaces direkt zu implementieren
daher werden hier die Methoden definiert und mit einer Exception versehen,
sodass jede Benutzung unmöglich ist, solange diese nicht in erbenden Klassen überschrieben werden.
"""

from lxml import etree
from lxml import html
from copy import deepcopy
import os
from tex2xStruct import System
from plugins import exceptions
import json

class Plugin(object):
    '''
    Enthält eine Sammlung von Methoden dessen Aufruf beim Erstellen eines Plugins empfohlen wird. Für die erfolgreiche
    Zusammenarbeit mit dem Structure-Objekt reicht es jedoch :func:`create_output` zu implementieren.
    '''
    
    #Name des Plugins (für die Ausgabe auf der Konsole wichtig)
    name = None
    content = None
    options = None
    tocxml = None
    
    required_images = list()
    required_swf_files = list();
    required_interactions = list();
    required_video_files = list()
    

    def __init__(self):
        pass
     
    def create_output(self):
        """
        :param structure: Structure-Objekt -- Enthält alle benötigten Informationen zum Erzeugen der Ausgabe
        :param options: Option-Objekt -- Enthält gewünschte Einstellungen und Konfigurationen
        
        Nachdem das Structure-Objekt die Eingabe aufbereitet hat, ruft es auf den Plugins diese Funktion auf, damit
        die gewünschte Ausgabe erzeugt werden kann.
        
        .. note::
            Bisher wird es vermieden mit Gettern und tiefen Kopien zu arbeiten. Eine Veränderung von Variablen des
            Structure-Objekts hat also auch Folgen für danach aufgerufene Plugins. Insbesondere auch die Manipulation
            von (l)xml-Bäumen.
        """
        def processEvent(self, event):
            raise NotImplementedError
     
        

     
    def check_if_dir_preexists(self, targetpath):
        """
        :param targetpath: Pfad -- Zu prüfender Pfad
        
        Es wird geprüft, ob der angegebene Pfad bereits existiert, um vor möglichem Datenverlust durch das Überschreiben
        von Dateien zu warnen. Andererseits kann das Verzeichnis auch Dateien enthalten, welche nicht mit dem Output des Plugins
        zusammen herausgegeben werden sollen. Wird ein existierendes Verzeichnis entdeckt, warnt die Funktion und verlangt
        eine Eingabe, ob die Ausführung des Plugins fortgesetzt werden soll.
        """
         
        #Falls das Verzeichnis existiert, fragen wir lieb nach, ob wir es benutzen dürfen
        if os.path.exists(targetpath):
            if len(os.listdir(targetpath)):
                print("Achtung das Zielverzeichnis " + targetpath + " für die Ausgabe des " + self.name + "-Plugins ist nicht leer. Es ist möglich, dass dies zu Datenverlust und/oder nicht erwünschten Dateien im Ausgabeverzeichnis führt.")
                answer = ""
                while (answer != "j" and answer != "n"):
                    answer = input("Fortfahren? (j/n)")
                if answer == "n":
                    raise exceptions.PluginException("Das " + self.name + "-Plugin bricht seine Ausführung nach Userintervention ab.")
    
    def __append_all_filenames_in_dir_to_list(self, filename_list, path, subpath):
        """
        :param filename_list: filename-Liste -- (Nicht notwendigerweise leer) hier werden weitere im Verzeichnis gefundene Dateien (inkl. relativem Pfad) angehängt
        :param path: Pfad - Verzeichnis, das nach Datei für die Liste (ursprünglich) durchsucht werden soll
        :param subpath: Pfad - Für den rekursiven Durchlauf womöglich vorhandener Unterverzeichnisse 
        
        Diese Funktion sollte mit einer leeren Liste, einem Pfad und einem leeren String
        aufgerufen werden.
        
        Daraufhin wird das Angegebene Verzeichnis rekursiv nach allen Dateinamen durchsucht
        welche an die zu Beginn übergebene Liste angehängt werden.
        """
        files = os.listdir(os.path.join(path, subpath));
        for file in files:
            #file ist ein Verzeichnis: Rekursiver Aufruf der Methode
            if (os.path.isdir(os.path.join(path, subpath, file))):
                self.__append_all_filenames_in_dir_to_list(filename_list, path, os.path.join(subpath, file))
            else:#file ist eine Datei, also mit Pfad an die Liste anhängen (Rekursionsabbruch)
                filename_list.append(os.path.join(subpath, file))
                
    def get_list_of_all_filenames_in_dir(self, path, subpath = ""):
        """
        :param path: Pfad -- Pfad dessen Dateien aufgelistet werden sollen.
        :param subpath: Pfad -- Teil des zu durchsuchenden Pfades, der vor die einzelnen Listenelemente gestellt wird.
        :returns: filename-Liste -- Liste aller Dateien im Verzeichnis **path**.
        
        Listet alle Dateien in einem Verzeichnis in einer Liste auf und gibt diese anschließend aus.
        
        .. note::
            Falls in **path** Unterverzeichnisse vorhanden sind, enthalten die Listeneinträge einen relativen Pfad bezogen auf **path**.
        """
        filename_list = list()
        self.__append_all_filenames_in_dir_to_list(filename_list, path, subpath)
        return filename_list
    
    def create_xml_files(self, targetPath=None, only_for_toc_node = None):
        """
        :param targetPath: Pfad - Zielpfad für die Dateigenerierung
        :param only_for_toc_node: node -- Wenn ein Knoten angegeben wird, werden nur die dazu zugehörigen xml-Dateien mit den Inhalten erzeugt.
        
        Diese Funktion legt die xml-Dateien an, welche die eigentlichen Inhalte enthalten.  
        """
        if(targetPath==None):
            targetPath = Plugin.options.targetpath
        
        
        #Anzahl der Module zählen
        count_moduls = 0
        moduls = list()# Liste bestehend aus den Übersichts-Seiten
        count_subsections = dict();
        for tupel in Plugin.content:
            if (tupel[1].get("class") == (Plugin.options.ModuleStructureClass + "1")):
                count_moduls += 1
                moduls.append(tupel)
                count_subsections = dict();
        
        for tupel in Plugin.content:
            #Wenn die XML-Struktur nur für einen bestimmten Inhaltsknoten erzeugt werden soll
            #machen wir nichts, falls wir einen anderen Inhaltsknoten finden
            if not (only_for_toc_node is None) and tupel[0] != only_for_toc_node:
                continue
            
            #Als erstes dafür sorgen, dass das Ziel-Verzeichnis existiert
            target_dir = os.path.join(os.path.join(targetPath, "xml"), tupel[0].get("name"))
            if not os.path.exists(target_dir):
                os.makedirs(target_dir)
                
            #Okay, jetzt kann die zugehörige XML-Datei gespeichert werden
            if (not tupel[0].get("name") in count_subsections):#Eintrag bei Bedarf anlegen
                count_subsections[tupel[0].get("name")] = dict()
            if(not tupel[1].get("class") in count_subsections[tupel[0].get("name")]):#Eintrag bei Bedarf anlegen
                count_subsections[tupel[0].get("name")][tupel[1].get("class")] = 0
            fobj = open(os.path.join(target_dir, tupel[1].get("class") + "_" + str(count_subsections[tupel[0].get("name")][tupel[1].get("class")]) + ".xml"), "w")
            output_string = etree.tostring(tupel[1], pretty_print = True, encoding = "unicode")
            fobj.write(output_string)
            #fobj.write(html.tostring(tupel[1], pretty_print = True).decode())
            fobj.close()
            count_subsections[tupel[0].get("name")][tupel[1].get("class")] += 1 # counter für bereich erhöhen
            
            #Eventuell angehaengte Lösungen in Dateien speichern
            i = 2
            while i < len(tupel):
                fobj = open(os.path.join(target_dir, tupel[1].get("class")  + "_" + str(count_subsections[tupel[0].get("name")][tupel[1].get("class")]-1) + "_" + str(i-1) + ".xml"), "w")
                output_string = etree.tostring(tupel[i], pretty_print = True, encoding = "unicode")
                fobj.write(output_string)
                fobj.close()
                i += 1
            
    #Zur rekursiven Verwendung, da das Inhaltsverzeichnis möglichst variabel sein soll
    def create_main_toc(self, level, main_toc, toc, targetpath):
        """
        Rekursive Methode, die aus dem toc-Baum das Inhaltsverzeichnis auf HTML-Basis erstellt. Die erstelle Inhaltsstruktur
        ist nach der Ausführung an den Knoten **main_toc** angehängt. 
        
        :param level: int -- Aktuelle Rekursionstiefe zur Orientierung in der Struktur (sollte beim ersten Aufruf 0 sein)
        :param main_toc: node -- An diesen Knoten wird das erzeugte Inhaltsverzeichnis angehängt (in Rekursionsschritten dann des Unterverzeichnisse)
        :param toc: toc_node -- Startknoten des Inhaltsverzeichnisses (bzw. in der Rekursion aktuell betrachteter Knoten es Verzeichnisses) 
        """
        li = etree.Element("li")
        li.set("class", "level" + str(level))
        
        if (len(toc)>0):
            #switch-image zum auf/zuklappen des Menüs
            switch = etree.Element("img")
            switch.set("id", "button_" + toc.get("name").replace(".", "_"))#jquery kommt nicht so gut mit Punkten klar
            switch.set("src", "../../images/plus.png")
            switch.set("class", "switch")
            li.append(switch)
        
        a = etree.Element("a")
        a.text = toc.text
        #existiert ein entsprechender Ordner?
        if os.path.exists(os.path.join(targetpath, "xml/" + toc.get("name"))):
            #dann setzten wir den Link!
            a.set("href", "../" + toc.get("name") + "/modstart.xhtml")
            
        li.append(a)
        main_toc.append(li)
        ul = None
        for child in toc.getchildren():
            ul = etree.Element("ul")
            ul.set("class", "level" + str(level+1))
            li.append(ul)
            self.create_main_toc(level + 1, ul, child, targetpath)
        
            #Falls wir den Link noch nicht setzen konnten, linken wir einfach auf den nächsten bekannten Link
            #aus einer höheren Ebene
            if a.get("href") == None:
                #die kleine Unterscheidung hier stammt daher, dass die Blätter des Inhaltsverzeichnisses
                #keine switch-icons mehr vorgestellt haben
                if ( not ul[0][0].get("href") is None):
                    a.set("href", ul[0][0].get("href"))
                else:
                    if len(ul[0]) >1:
                        a.set("href", ul[0][1].get("href"))
                    else:
                        pass#TODO: Warum kann dieser Fall auftreten?
                
    def load_toc_and_content_from_temp(self):
        path_to_temp = self.options.targetpathTemp
        
        #tocxml - Inhaltsverzeichnis laden
        with open(os.path.join(path_to_temp, "tocxml.xml"),'r') as f:
            self.tocxml=etree.parse(f).getroot();
            
            
        #content Array aus Dateiverzeichnis wieder herstellen
        self.content = list()
        
        for node in self.tocxml.iter():
            if (node.get("name") != None):
                files_in_directory = System.showFilesInPath(os.path.join(path_to_temp, node.get("name")))
                for file in files_in_directory:
                    with open(os.path.join(path_to_temp, node.get("name"), file),'r') as f:
                        file_xml = etree.parse(f).getroot();
                    self.content.append([node, file_xml])
            
        #Gesammelte Daten wieder laden
        with open(os.path.join(self.options.targetpathTemp, "test.json"),"r") as f:
            Plugin.data = json.load(f)
            self.required_images = Plugin.data["required_images"]
                 
        