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
import subprocess
import re
from distutils.dir_util import copy_tree, mkpath
from distutils.file_util import copy_file
import sys
import time
import getpass
import socket

class System(object):

    # message type constants (strings!) which should be consistent with constants in the JS framework in dlog.js
    CLIENTINFO = "1"    # JS-Client: Sent as feedback to the server as an information, Converter: Displayed both on console and in logfile
    CLIENTERROR = "2"   # JS-Client: Sent as feedback tot the server as an error message, will be sent also if user has disabled USAGE, Converter: Colored error message on the console and in logfile
    CLIENTWARN = "3"    # JS-Client: Sent as feedback tot the server as a warning message, Converter: Colored warning message on the console and in logfile
    DEBUGINFO = "4"     # JS-Client: Will be displayed on the JS console if not on a release version, Converter: will be put to logfile
    VERBOSEINFO = "5"   # JS-Client: Like DEBUGINFO but only if doverbose is active (will always appear in logfile though)
    CLIENTONLY = "6"    # JS-Client: Will ALWAYS be displayed on the browser console, including release versions, without prefix (should be user friendly)
    FATALERROR = "7"    # Converter: Conversion chain is aborted giving the error message

    # bash console color scheme
    BASHCOLORRED = "\033[91m"
    BASHCOLORGREEN = "\033[92m"
    BASHCOLORRESET = "\033[0m"


    def __init__(self, options):
        self.logFilename = os.path.join(options.currentDir, options.logFilename)
        self.doColors = options.consolecolors
        self.doVerbose = options.doverbose
        
        self.startTime = time.time()
        self.checkTime = self.startTime

        with open(self.logFilename, 'w', encoding='utf-8') as log:
            s = "Started logging at absolute time " + time.ctime(self.startTime)
            log.write(s + "\n")
            print(s)

        self.message(self.CLIENTINFO, "Using option object: " + options.description)
        self.message(self.VERBOSEINFO, "Host = " + socket.gethostname() + ", user = " + getpass.getuser())

    def _printMessage(self, color, txt):
        # green verbose messages only in logfile, and on console if verbose is active
        if ((color != self.BASHCOLORGREEN) or (self.doVerbose == 1)):
            if (self.doColors == 1):
                print(color + txt + self.BASHCOLORRESET)
            else:
                print(txt)
       
            
        with open(self.logFilename, 'a', encoding='utf-8') as log:
            log.write(txt + "\n")
            
            
    def message(self, lvl, msg):
        # Conversion is on a "server", not a client, server relevant information is displayed always
        if (lvl == self.CLIENTINFO):
            self._printMessage("", "INFO:    " + msg)
        else: 
            if (lvl == self.CLIENTERROR):
                self._printMessage(self.BASHCOLORRED, "ERROR:   " + msg)
            else:
                if (lvl == self.CLIENTWARN):
                    self._printMessage(self.BASHCOLORRED, "WARNING: " + msg)
                else:
                    if (lvl == self.DEBUGINFO):
                        self._printMessage(self.BASHCOLORGREEN, "DEBUG:   " + msg)
                    else:
                        if (lvl == self.VERBOSEINFO):
                            self._printMessage(self.BASHCOLORGREEN, "VERBOSE: " + msg)
                        else:
                            if (lvl == self.CLIENTONLY):
                                self._printMessage(self.BASHCOLORRED, "ERROR: Wrong error type " + lvl + " on conversion platform, message: " + msg)
                            else:
                                if (lvl == self.FATALERROR):
                                    self._printMessage(self.BASHCOLORRED, "FATAL ERROR: " + msg)
                                    print("Program aborted with error code 1")
                                    sys.exit(1)
                                else:
                                    self._printMessage(self.BASHCOLORRED, "ERROR: Wrong error type " + lvl + ", message: " + msg)
            

    
    def timestamp(self, msg):
        myTime = time.time()
        reltimediff = myTime - self.checkTime
        abstimediff = myTime - self.startTime
        self.checkTime = myTime
        self.message(self.VERBOSEINFO, msg + " (relative time: " + str(reltimediff) + ", absolute time: " + str(abstimediff) + " [seconds])")



    def openFile(self, path, attr):
        """
        :param path: Pfad - Pfad zur Datei
        :param attr: Attribut - Angabe des Modus zur Öffnung, z.B. rb, w, etc
        :returns: Dateihandle - Handle der geöffneten Datei.
        
        Öffnet die in **path** angegebene Datei.
        
        .. note::
            Nicht existierende Dateien und Pfade werden dabei neu angelegt!
        """
        if not os.path.exists(os.path.dirname(path)) and os.path.dirname(path) != "":
            os.makedirs(os.path.dirname(path))
        return open(path,attr)

    def copyFile(self, source, target, filename):
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
    
    def getPathName(self, path):
        while path[0]=="." :
            path=path[3:len(path)]
        return(path)

    def showFilesInPath(self, path):
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
        
        
    def copyFiletree(self, source, target, path):
        copy_tree(os.path.join(source,path),os.path.join(target,path),update=1)
        
        
    def removeTree(self, path):
        if os.path.isdir(path):
            shutil.rmtree(path)
        else:
            self.message(log.CLIENTERROR, "removeTree got " + path + ", but it is not a tree or does not exist")
        
    def removeFile(self, path):
        if os.path.isfile(path):
            os.remove(path)
        else:
            self.message(log.CLIENTERROR, "removeFile got " + path + ", but it is not a file or does not exist")
            
    def makePath(self, path):
        os.makedirs(path)


    # create a new empty tree, delete old one if present without further warning
    def emptyTree(self, path):
        if os.path.isdir(path):
            shutil.rmtree(path)
        self.makePath(path)
    
    # retrieves the input of a text file and checks its encoding, but always converts found encoding to unicode strings
    # Return value is always a Python3 string (in unicode)
    def readTextFile(self, name, enc):
        text = ""
        if (os.path.isfile(name) == False):
            self.message(log.FATALERROR, "File " + name + " not found")
        p = subprocess.Popen(["file", "-i", name], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
        (output, err) = p.communicate()
        m = re.match(r".*?; charset=([^\n ]+)", output, re.S)
        if m:
            if (m.group(1) == "binary"):
                self.message(log.FATALERROR, "File " + name + " appears to be binary, not a text file")
            if ((m.group(1) != enc) and (m.group(1) != "us-ascii")):
                self.message(log.CLIENTWARN, "File " + name + " is encoded in " + m.group(1) + " instead of requested " + enc + " or us-ascii, doing implicit conversion")
            with open(name, "r", encoding = m.group(1)) as file:
                text = file.read()
            self.message(self.VERBOSEINFO, "Read string of length " + str(len(text)) + " from file " + name + " encoded in " + m.group(1) + ", converted to python3 unicode string")
    
        else:
            self.message(self.FATALERROR, "Output of file-command could not be matched (VEUNDMINT System.py, readTextfile function): " + output)
        
        return text
        
    
    # Writes text to a text file (creating or overwriting existing files) in a given encoding given a Python3 unicode string
    # subfolders are created if not already there
    def writeTextFile(self, name, text, enc):
        if ((not os.path.exists(os.path.dirname(name))) and (os.path.dirname(name) != "")):
            os.makedirs(os.path.dirname(name))
    
        with open(name, "w", encoding = enc) as file:
            file.write(text)
            
        self.message(self.VERBOSEINFO, "Written string of length " + str(len(text)) + " to file " + name + " encoded in " + enc)
    
        