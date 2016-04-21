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

    
    """
    
    def __init__(self, currentDir):
        
        
        #Debugging
        self.DEBUG = True
        
        # sources
        self.currentDir = os.path.abspath(currentDir)
        self.sourcepath = os.path.join(currentDir,"input")
        self.sourceCommonFiles=os.path.join(self.sourcepath,"files")
        self.sourcePlugin=os.path.join(self.sourcepath,"basic-SCORM")
        self.sourceModuleSkeletonFile=os.path.basename("modstart.xhtml")
        
        # targets
        self.targetpath = os.path.join(currentDir,"../output/SCORM_basic")
        
        # ModuleStructure
        self.ModuleStructure=[]
        # div-id, nav-id ,link, Beschriftung nav, Bereichstitel
        self.ModuleStructure.append(["moduebersicht","start","#moduebersicht","Übersicht","Übersicht"])
        self.ModuleStructure.append(["modgenetisch","genetisch","#modgenetisch","Hinführung","Genetische Hinführung"])
        self.ModuleStructure.append(["modbeweis","beweis","#modbeweis","Erklärung","Begründung/Interpretation/Herleitung"])
        self.ModuleStructure.append(["modanwendungen","anwdg","#modanwendungen","Anwend.","Anwendung"])
        self.ModuleStructure.append(["modfehler","fehler","#modfehler","Fehler","Fehler"])
        self.ModuleStructure.append(["modaufgaben","aufgb","#modaufgaben","Aufgaben","Aufgaben"])
        self.ModuleStructure.append(["modinfo","info","#modinfo","Info","Info"])
        self.ModuleStructure.append(["modvisual","visual","#modvisual","Visual.","Visualisierungen - Übersicht"])
        self.ModuleStructure.append(["modergaenzungen","weiterfhrg","#modergaenzungen","Ergänz.","Ergänzungen"])
        self.ModuleHome=["home","../../index.html","Home"]
        self.ModuleNext=["prev","javascript:zurueck();","Zurück"]
        self.ModulePrev=["next","javascript:weiter();","Weiter"]
        
        #nach dieser klasse wird gesucht, um Modulbereiche zu identifizieren. (Dann jeweils mit einer Nummer dahinter)
        self.ModuleStructureClass = "xcontent"
        
        # IDs for Content and Navigation-Structures in Skeleton File
        self.SkeletonFileNav = "navigation"
        self.SkeletonFileContent = "inhalt"
        