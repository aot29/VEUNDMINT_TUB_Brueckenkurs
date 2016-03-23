"""    
    VEUNDMINT System module
    Copyright (C) 2016  VE&MINT-Projekt - http://www.ve-und-mint.de
    This module is a modification of the System module from the tex2x converter by VEMINT 

    The VEUNDMINT System module is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or (at your
    option) any later version.

    The VEUNDMINT System module is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with the VEUNDMINT plugin package. If not, see http://www.gnu.org/licenses/.
"""

import shutil
import os
from distutils.dir_util import copy_tree, mkpath
from distutils.file_util import copy_file

def openFile(path,attr):
    """
    :param path: Pfad - Pfad zur Datei
    :param attr: Attribut - Angabe des Modus zur Öffnung, z.B. rb, w, etc
    :returns: Dateihandle - Handle der geöffneten Datei.
    
    Öffnet die in **path** angegebene Datei.
    
    .. note::
        Nicht existierende Dateien und Pfade werden dabei neu angelegt!
    """
    if not os.path.exists(os.path.dirname(path)) and os.path.dirname(path)!="":
        os.makedirs(os.path.dirname(path))
    return open(path,attr)

def copyFile(source, target, filename):
    """
    :param source: Pfad - Pfad zum Quellverzeichnis
    :param target: Pfad - Pfad zum Zielverzeichnis
    :param filename: Pfad - Dateiname, kann zusätzlich zu **source** bzw. **target** relative Unterverzeichnisse angeben
    
    Kopiert die Datei **filename** vom Verzeichnis **source** in das Verzeichnis **target**.
    
    .. note::
        In **source** und **target** identische Unterordner vor **filename** können auch in den **filename**-Parameter eingetragen werden, um Redundante angaben zu vermeiden. 
    """
    mkpath(target)
    mkpath(os.path.dirname(os.path.join(target, filename)))
    copy_file(os.path.join(source, filename),os.path.join(target, filename), update = 1)

def getPathName(path):
    while path[0]=="." :
        path=path[3:len(path)]
    return(path)

def showFilesInPath(path):
    pathLen=len(path)+1
    fileArray=[]
    for root,dirs,files in os.walk(path):                
        root=root[pathLen:] #i don't like it, but it works
        for name in files:
            if name.count("svn")==0  and root.count("svn")==0:
                fileArray.append(os.path.join(root,name))
        for name in dirs:
            if name.count("svn")!=0:
                continue
    return fileArray
    
#def copyFilesInDir(path):#NOT RECURSIVE    
    
def copyFiletree(source,target,path):
    copy_tree(os.path.join(source,path),os.path.join(target,path),update=1)
    
    
def removeTree(path):
    if os.path.isdir(path):
        shutil.rmtree(path)
    else:
        self.log(self.log.CLIENTERROR, "removeTree got " + path + ", but it is not a tree or does not exist")
    
def removeFile(path):
    if os.path.isfile(path):
        os.remove(path)
    else:
        self.log(self.log.CLIENTERROR, "removeFile got " + path + ", but it is not a file or does not exist")
        
def makePath(path):
    os.makedirs(path)
        

# create a new empty tree, delete old one if present without further warning
def emptyTree(path):
    if os.path.isdir(path):
        shutil.rmtree(path)
    makePath(path)
