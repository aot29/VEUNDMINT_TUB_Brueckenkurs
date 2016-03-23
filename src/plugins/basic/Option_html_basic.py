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

import os.path

class Option(object):
    """
    Tex2x lässt sich vielfältig konfigurieren. Da eine Konfiguration über Kommandozeilen-Parameter den Rahmen
    bei Weitem sprengen würde, ist die Options-Klasse angelegt worden, um die Optionen vor dem Start bequem in
    einem Texteditor nach den eigenen Bedürfnissen anpassbar zu machen. Grob schlüsseln sich die verfügbaren Optionen
    wie folgt auf
    
    * Debug Ausgabe ein-/ausschalten
    
    * Quellordner angeben
    
    * Inhaltsstruktur der Quelle festlegen
    
    * Zu erstellende Module benennen
    
    * Copyright konfiguration
    
    * Auswahl der zu erstellenden Module (Alles, selektiv, Sektionen)
    
    * Detailleinstellungen zu unterstützten Plugins
    
    """
    
    def __init__(self, currentDir):
        
        
        #Debugging
        self.DEBUG = True

        #parser
        self.parserName="lxml" #Später könnten hier mehrere unterstützt werden
        
        # sources
        self.currentDir = currentDir
        self.sourcepath = os.path.join(currentDir,"input")
        self.sourceTEX=os.path.join(self.sourcepath,"tex")
        self.sourceTEXStartFile=os.path.join(self.sourcepath,"tex/vorkursxml.tex")
        self.sourceInteractiveExercises=os.path.join(self.sourcepath,"aufgabenentwurf")
        self.sourceCommonFiles=os.path.join(self.sourcepath,"files")
        self.sourcePlugin=os.path.join(self.sourcepath,"basic-HTML")
        self.sourceModuleSkeletonFile=os.path.basename("modstart.xhtml")
        
        # targets
        self.targetpath = os.path.join(currentDir, "..", "output", "basic-HTML")
        
        
        # ModuleStructure
        self.ModuleStructure=[]
        # div-id, nav-id ,link, Beschriftung nav, Bereichstitel
        self.ModuleStructure.append(["xcontent1","start","#moduebersicht","Übersicht","Übersicht"])
        self.ModuleStructure.append(["xcontent2","genetisch","#modgenetisch","Hinführung","Genetische Hinführung"])
        self.ModuleStructure.append(["xcontent3","beweis","#modbeweis","Erklärung","Begründung/Interpretation/Herleitung"])
        self.ModuleStructure.append(["xcontent4","anwdg","#modanwendungen","Anwend.","Anwendung"])
        self.ModuleStructure.append(["xcontent5","fehler","#modfehler","Fehler","Fehler"])
        self.ModuleStructure.append(["xcontent6","aufgb","#modaufgaben","Aufgaben","Aufgaben"])
        self.ModuleStructure.append(["xcontent7","info","#modinfo","Info","Info"])
        self.ModuleStructure.append(["xcontent8","visual","#modvisual","Visual.","Visualisierungen - Übersicht"])
        self.ModuleStructure.append(["xcontent9","weiterfhrg","#modergaenzungen","Ergänz.","Ergänzungen"])
        self.ModuleHome=["home", "../../index.html", "Home"]
        self.ModuleNext=["prev","javascript:zurueck();","Zurück"]
        self.ModulePrev=["next","javascript:weiter();","Weiter"]
        
        #nach dieser klasse wird gesucht, um Modulbereiche zu identifizieren. (Dann jeweils mit einer Nummer dahinter)
        self.ModuleStructureClass = "xcontent"
        
        # IDs for Content and Navigation-Structures in Skeleton File
        self.SkeletonFileNav = "navigation"
        self.SkeletonFileContent = "inhalt"
        
        # Solution Parameter
        # old div-class, new Link class, Link target, Linktext 
        self.SolutionLink=["loesung", "loesung_zeigen", "#", "Lösung anzeigen"]
        # Solution-title, Back-Class, Back-Text
        self.SolutionPage=["Lösung", "loesung_verbergen", "#", "Zurück zur Aufgabe"]
        
        # Struktur für besondere Dateiarten sowie dem, was kopiert werden muss!
        
        #Copyright Optionen
        self.appendCopyrightInformation = True
        self.holderOfCopyright = "VEMINT 2014"
        
        #Konfiguration der Ausgabemodi
        #Das Skript läuft wesentlich schneller, wenn bereits dem ttm nur die gewünschten
        #Module angegeben werden (derzeit geschieht dies in V30.tex).
        self.ALL = "all"
        self.SELECTED = "selected"
        self.SECTIONS = "sections"
        self.outputMode = self.ALL
        
        #self.outputSelected = ["2.1.1", "1.1.1"]
        self.outputSelected = ["4.2.2"]
        #self.outputSection = ["2.2"]
        self.outputSection = ["2.2"]
        
        #use these Plugins (plugin path must be listed below within the plugin settings!)
        self.usePlugins = ["VEMINThtml5", "VEMINTscorm"]
        
        
        #Individual Settings for some of the
        #mod pages
        
        #The modvisual-page displays all interactions and provides a link back directly into
        #the context where they came from. This determines how it's labled
        self.modvisualLinkToContextName = "Gehe dorthin!"
        

        #Settings for supported plugins

