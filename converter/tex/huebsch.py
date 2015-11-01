#!/usr/bin/env python
# encoding: iso-8859-1
import re
import os

#TEX-Umlaute weg , alte VEMINT Version - fuer tex-Verzeichnis
dir=os.listdir(".")
tex_dir=list()

for nr in range(0,len(dir),1):
  if dir[nr].find(".tex")>=0 and dir[nr].find(".tex~")<0:
    tex_dir.append(dir[nr])
    
#alle texdateien bearbeiten!
for nr in range(0,len(tex_dir),1):
  #Latex-Datei einlesen und wiederschliessen
  print(tex_dir[nr])
  source=open(tex_dir[nr],"r")
  latex=source.readlines()
  source.close()
  for i in range(len(latex)):
#    latex[i]=latex[i].replace("="," = ")
#    latex[i]=latex[i].replace("+"," + ")
#    latex[i]=latex[i].replace("-"," - ")
#    latex[i]=latex[i].replace("  "," ")
#	latex[i]=latex[i].replace("= = ","==")
#	latex[i]=latex[i].replace("== = ","===")
#	latex[i]=latex[i].replace("==Anfang","== Anfang")
#	latex[i]=latex[i].replace("==Ende","== Ende")
	latex[i]=latex[i].replace("$ - R","$-R")
	latex[i]=latex[i].replace("$ - A","$-A")
	latex[i]=latex[i].replace("$ - W","$-W")
	latex[i]=latex[i].replace("$ - V","$-V")
  target=open(tex_dir[nr],"w")
  target.writelines(latex)
  target.close()
