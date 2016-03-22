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
    
    Diese Angaben beziehen sich auf die Structure-Klasse. Da eingebundene Plug-ins unter anderen Lizenzen als der GPL veröffentlicht werden können, darf hier kein Austausch stattfinden.
    """
    
    def __init__(self, currentDir):
        
        #Debugging
        self.DEBUG = True
        
        # sources
        self.currentDir = currentDir
        self.sourcepath_original = os.path.join(currentDir,"input")
        self.sourcepath = os.path.join(currentDir, "..", "tmp_input")
        self.sourceTEX = os.path.join(self.sourcepath,"tex")
        self.sourceTEXStartFile = os.path.join(self.sourcepath,"tex/output_xml.tex")
        self.sourceInteractiveExercises = os.path.join("../",self.sourcepath,"aufgabenentwurf")
        self.sourceCommonFiles = os.path.join(self.sourcepath,"files")
        self.sourceModuleSkeletonFile = os.path.basename("modstart.xhtml")
        
        # targets
        self.targetpath = os.path.join(currentDir,"../output")
        self.targetpathTemp = os.path.join(self.targetpath, "tmp")
        
        # ttm-file
        self.ttmPath=os.path.join(currentDir,"src", "ttm")
        self.ttmExecute = True
        self.ttmFile=os.path.join(self.targetpath, "output_xml.xml")
        
        # ContentStructure - Grobe Strukturierung (Chapter, Section, Subsection)
        self.ContentStructure=[]
        self.ContentStructure.append("h1")
        self.ContentStructure.append("h2")
        self.ContentStructure.append("h3")
        
        # ModuleStructure
        self.ModuleStructureClass= "xcontent"#nach dieser klasse wird gesucht, um Modulbereiche zu identifizieren. (Dann jeweils mit einer Nummer dahinter)

        
        #use these Plugins (plugin path must be listed below within the plugin settings!)
        self.usePlugins = ["HTML_basic", "SCORM_basic"]#["VEMINThtml5", "VEMINTscorm"]
        self.pluginPath = os.path.join(self.currentDir, "src", "plugins")#{"VEMINThtml5": "src/plugins/VEMINT/html5.py", "VEMINTscorm": "src/plugins/VEMINT/scorm.py", "HTML_basic": "src/plugins/basic/html_basic.py", "SCORM_basic": "src/plugins/basic/scorm_basic.py"}