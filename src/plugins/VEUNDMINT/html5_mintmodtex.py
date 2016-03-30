"""    
    VEUNDMINT plugin package
    Copyright (C) 2016  VE&MINT-Projekt - http://www.ve-und-mint.de

    The VEUNDMINT plugin package is free software; you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation; either version 3 of the License, or (at your
    option) any later version.

    The VEUNDMINT plugin package is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
    License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with the VEUNDMINT plugin package. If not, see http://www.gnu.org/licenses/.
"""


"""
    This is html5 output plugin object associated to the mintmod macro package, 
    Version P0.1.0, needs to be consistent with mintmod.tex and the preprocessor plugin
"""

import os
from lxml import etree
from lxml import html
from copy import deepcopy
from plugins.exceptions import PluginException
from lxml.html import html5parser
import fnmatch

from plugins.basePlugin import Plugin as basePlugin

class Plugin(basePlugin):

    def __init__(self, interface):
        
        # copy interface member references
        self.sys = interface['system']
        self.data = interface['data']
        self.options = interface['options']
        self.name = "HTML5_MINTMODTEX"
        self.version ="P0.1.0"
        self.outputextension = "html"
        self.sys.message(self.sys.VERBOSEINFO, "Output plugin " + self.name + " of version " + self.version + " constructed")

    def _prepareData(self):
        # checks if needed data members are present or empty
        if 'content' in self.data:
            self.content = self.data['content']
        else:
            self.sys.message(self.sys.CLIENTERROR, "tex2x did not provide content in data structure")
            self.content = ""
            
        if 'tocxml' in self.data:
            self.tocxml = self.data['tocxml']
        else:
            self.sys.message(self.sys.CLIENTERROR, "tex2x did not provide tocxml in data structure")
            self.content = ""

        for dat in ['DirectRoulettes', 'macrotex', 'modmacrotex', 'DirectHTML', 'directexercises', 'autolabels', 'copyrightcollection', 'htmltikz']:
            if not dat in self.data:
                self.sys.message(self.sys.CLIENTERROR, "Preprocessors did not provide " + dat)


     
    def create_output(self):
        self._prepareData()
        if self.options.forceyes == 0: self.check_if_dir_preexists(self.options.targetpath)
        self.sys.emptyTree(self.options.targetpath)
        self.sys.copyFiletree(self.options.converterCommonFiles, self.options.targetpath, ".")
        self.sys.timestamp("Common HTML5 tree files copied")
        
        self.create_html_files()


    def create_html_files(self):
        templatefile = open(os.path.join(self.options.converterTemplates, "template_" + self.name + ".html"), "rb")
        parser = html.HTMLParser()
        template = etree.parse(templatefile, parser).getroot()
        templatefile.close()
        head = template.find(".//head")
        title = template.find(".//title")
        content = template.find(".//div[@id='content']")
        
        path = os.path.join(self.options.targetpath, self.outputextension)
        self.sys.writeTextFile(os.path.join(path, "test.html"), etree.tostring(template, pretty_print = True).decode(), self.options.stdencoding)
        
        self.write_html_files()
        
        
    def write_html_files(self):
        count_moduls = 0
        moduls = list()# Liste bestehend aus den Übersichts-Seiten
        count_subsections = dict();
        for tupel in self.content:
            if (tupel[1].get("class") == (self.options.ModuleStructureClass + "0")):
                count_moduls += 1
                moduls.append(tupel)
                count_subsections = dict();
        
        for tupel in self.content:
            target_dir = os.path.join(os.path.join(self.options.targetpath, self.outputextension), tupel[0].get("name"))
            self.sys.ensureTree(target_dir)
                
            #Okay, jetzt kann die zugehörige XML-Datei gespeichert werden
            if (not tupel[0].get("name") in count_subsections):#Eintrag bei Bedarf anlegen
                count_subsections[tupel[0].get("name")] = dict()
            if(not tupel[1].get("class") in count_subsections[tupel[0].get("name")]):#Eintrag bei Bedarf anlegen
                count_subsections[tupel[0].get("name")][tupel[1].get("class")] = 0
            
            filename = os.path.join(target_dir, tupel[1].get("class") + "_" + str(count_subsections[tupel[0].get("name")][tupel[1].get("class")]) + "." + self.outputextension)
            txt = etree.tostring(tupel[1], pretty_print = True, encoding = "unicode")
            self.sys.writeTextFile(filename, txt, "utf-8")
            count_subsections[tupel[0].get("name")][tupel[1].get("class")] += 1 # counter für bereich erhöhen
        
        
      
    
            
    def create_modstart_files(self):
        """
        Legt alle Modstart-Dateien zu den Modulen in den entsprechenden Verzeichnissen an.
        """
        
        #Wir zählen die Bereiche in den Dateien
        blocks = dict()
         
        for tupel in self.content:
            if not tupel[0] in blocks:
                blocks[tupel[0]] = dict()
                
            count = 1
            for span in tupel[1].findall(".//span[@id='lo_status']"):
                count += 1
            
            blocks[tupel[0]][tupel[1].get("class")] = count
                
        
        #Notwendig, um Informationen über die vorhandenen bereiche abzulegen
        script_tag = etree.Element("script")
        script_tag.set("type", "text/javascript")
        head.append(script_tag)
        
        #Inhaltsverzeichnis am linken Rand 
        main_toc = etree.Element("ul")
        main_toc.set("class", "level1")
        main_toc.set("id", "navstart")
        
        
        for toc_node in self.tocxml.iterchildren():
            self.create_main_toc(1, main_toc, toc_node, self.options.targetpath)#ist rekursiv
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
                for mod_struct in self.options.ModuleStructure:              
                    
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
                        
          
                
            
            