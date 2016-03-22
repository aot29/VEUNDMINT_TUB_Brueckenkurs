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
from lxml import etree
import shutil
from tex2xStruct import System

def pack(path, modnumber, full_title):
    
    manifest = create_manifestxml(path, modnumber, full_title)
    #manifest_str = etree.tostring(manifest).decode()#TODO: bessere Performance
    manifest_str = etree.tostring(manifest, pretty_print = True).decode()
    
    clean(path)
    
    fobj = open (os.path.join(path, "imsmanifest.xml"), "w")
    fobj.write(manifest_str)
    fobj.close()

    #zipt ein SCORM-Modul
    shutil.make_archive(path, "zip", path)
    
    

def create_manifestxml(path, modnumber, full_title):#modnumber = toc_node.get("name")
    fobj = open(os.path.join(path, "imsmanifest.xml"), "rb")
    manifest = etree.fromstring(fobj.read())
    fobj.close()

    
    entry = manifest.find(".//{http://www.imsglobal.org/xsd/imsmd_rootv1p2p1}entry")
    entry[0].text = "Kapitel " + modnumber
    
    organizations = manifest.find("{http://www.imsproject.org/xsd/imscp_rootv1p1p2}organizations")


    pre_node = organizations[0]
    item = etree.Element("item", identifier = ("ITEM-0"), identifierref = get_id("xml/" + modnumber + "/modstart.xhtml"), isvisible = "true")
        
    title_node = etree.Element("title")
    title_node.text = full_title
        
    item.append(title_node)
    pre_node.append(item)

    #Resources ermitteln und entsprechenden XML-Baum bauen
    resources = manifest.find("{http://www.imsproject.org/xsd/imscp_rootv1p1p2}resources")    
    ADLCP = "{http://www.adlnet.org/xsd/adlcp_rootv1p2}"
    
    #modstart.xhtml eintragen
    resource = etree.Element("resource")
    resource.set(ADLCP + "scormtype", "sco")
    resource.set("href", "xml/" + modnumber + "/modstart.xhtml")
    resource.set("type", "webcontent")
    resource.set("identifier", get_id(resource.get("href")))
    resource.append(etree.Element("file", href = "xml/" + modnumber + "/modstart.xhtml"))
    
    #Alle Inhalte mit der modstart.xhtml als File assoziieren
    create_manifest_append_file_nodes(resource, path, "")

    #Arbeitsergebnis noch an den Baum anhängen
    resources.append(resource)

    return manifest

def get_id(idString):
    """
    :param idString: String -- Aus diesem String wird die ID bzw. der Hash berechnet.
    
    Berechnet zu einem gegebenen String eine ID (Hash) zur Verwendung im Scorm-Manifest.
    
    .. note::
        Diese Funktion könnte falls benötigt echte Hash-Werte berechnen.
        Es scheint aber auszureichen den Pfad selbst als ID zu nutzen,
        sodass die ID Menschen-lesbar bleibt.
    """
    return idString.replace("/", "")
    #return "%d"%hash(str)
        
def create_manifest_append_file_nodes(resource, path, subpath):
    """
    Hilfsfunktion für create_manifest (rekursiv!)
    
    Aufgabe ist es in dem gegebenen resource Knoten alle Dateien einzutragen, die sich im
    Scorm-Paket befinden und von der modstart.xhtml aus geladen werden. 
    """
    
    files = os.listdir(os.path.join(path, subpath))
    for file in files:
        if os.path.isdir(os.path.join(path, subpath, file)):
            create_manifest_append_file_nodes(resource, path, os.path.join(subpath, file))
        else:
            file_element = etree.Element("file")
            file_element.set("href", os.path.join(subpath, file))
            resource.append(file_element)
def clean(path):
    """unbenötigte Dateien löschen"""
    #TODO: implementieren
    pass     
    
