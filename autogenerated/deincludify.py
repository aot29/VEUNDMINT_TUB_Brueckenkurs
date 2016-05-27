"""    
    deincludify tool program - Processes tex-files and removes include commands by including the file
    Copyright (C) 2016  VE&MINT-Projekt - http://www.ve-und-mint.de

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


import sys
import os
import re
import subprocess
import argparse

stdencoding = "iso-8859-1"

dellist = list()

def readTextFile(name, enc):
    text = ""
    if (os.path.isfile(name) == False):
        print("File " + name + " not found")
    else:
        print("File " + name + " found")
    p = subprocess.Popen(["file", "-i", name], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
    (output, err) = p.communicate()
    m = re.match(r".*?; charset=([^\n ]+)", output, re.S)
    if m:
        if (m.group(1) == "binary"):
            print("File " + name + " appears to be binary, not a text file")
        if ((m.group(1) != enc) and (m.group(1) != "us-ascii")):
            print("File " + name + " is encoded in " + m.group(1) + " instead of requested " + enc + " or us-ascii, doing implicit conversion")
        enc = m.group(1)
        if enc == "us-ascii":
            # Pythons ascii decoder cannot handle ASCII values >127, presume iso-8859-1 encoding for those
            print("Switched ASCII encoding to latin1")
            enc = "iso-8859-1"
        
        with open(name, "r", encoding = enc) as f:
            text = f.read()
        print("Read string of length " + str(len(text)) + " from file " + name + " encoded in " + m.group(1) + ", converted to python3 unicode string")

    else:
        print("Output of file-command could not be matched (VEUNDMINT System.py, readTextfile function): " + output)
        
    return text


def writeTextFile(name, text, enc):
    if ((not os.path.exists(os.path.dirname(name))) and (os.path.dirname(name) != "")):
        os.makedirs(os.path.dirname(name))
    
    with open(name, "w", encoding = enc) as file:
        file.write(text)
            
    print("Written string of length " + str(len(text)) + " to file " + name + " encoded in " + enc)


parser = argparse.ArgumentParser(description='deincludify')
parser.add_argument("texfile", help="specify the texfile you want to process")

args = parser.parse_args()

if not os.path.isfile(args.texfile):
    print("Cannot find file " + args.texfile)
    sys.exit(1)
else:
    print("Processing " + args.texfile)
    tex = readTextFile(args.texfile, stdencoding)
    
    
    def deinclude(m):
        ifile = m.group(1)
        if "mintmod" in ifile:
            return m.group()
    
        if not "." in ifile:
            ifile += ".tex"
    
        print("--- EXPANDING AND DELETING" + ifile + " -------------")
        s = readTextFile(ifile, stdencoding) + "\n";
        if ifile in dellist:
            print("double usage of " + ifile)
        else:
            dellist.append(ifile)
        return s
    
    (tex, nec) = re.subn(r"%([\w\t ]*)\\include\{(.+?)\}", "% ", tex, 0, re.S)
    (tex, nep) = re.subn(r"%([\w\t ]*)\\input\{(.+?)\}", "% ", tex, 0, re.S)
    (tex, nc) = re.subn(r"\\include\{(.+?)\}", deinclude, tex, 0, re.S)
    (tex, np) = re.subn(r"\\input\{(.+?)\}", deinclude, tex, 0, re.S)

    print("Number of expanded include commands: " + str(nc))
    print("Number of expanded input commands: " + str(np))
    print("Number of deleted comments: " + str(nec + nep))
    
    
    
    writeTextFile(args.texfile, tex, stdencoding)
   
    print("Deleting " + str(len(dellist)) + " files")
    for f in dellist:
        os.remove(f)
   
    
sys.exit(0)
