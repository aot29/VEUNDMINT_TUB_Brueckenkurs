#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  wiki_get_article_3.py
#  
#  Copyright 2016 Stefan Born <born@math.tu-berlin.de>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  
#  

#  




from urllib.request import urlopen
from bs4 import BeautifulSoup
import datetime
import random
import re
import requests 
import sys
import webbrowser
import os
import subprocess
import time




def get_article(search_pattern, base_adress_secure="https://de.wikipedia.org", base_adress="http://de.wikipedia.org"):
    '''searches a relevant article, in case of disambiguation with a mathematical content.
    returns: a dictionary of wiki-pages {language_1:url_1, language_2:url_2} '''
    
    search_pattern=search_pattern.strip()
    params={"search":search_pattern}
    html = requests.post(base_adress_secure+"/w/index.php",data=params)
    url=html.url
    if url.find(search_pattern[:-2])==-1:
        return None
    bsObj = BeautifulSoup(html.text,"lxml")
    try:
        for spec in ["_(Mathematik)", "_(Geometrie)", "_(Analysis)", "_(Arithmetik)"]:
            betterlink = bsObj.find_all("a",{"href":"/wiki/"+search_pattern+spec})
            print ("Better: ", betterlink)
            if len(betterlink)>0:
                print ("Link: ", betterlink[0]["href"])
                url= base_adress+(betterlink[0]["href"])
                
    except:
        pass
   
    
    url={ "de": url}
    html = BeautifulSoup(urlopen(url["de"]), "lxml")
    lang_version = { "ar": "interlanguage-link interwiki-ar", "en": "interlanguage-link interwiki-en", "fr":"interlanguage-link interwiki-fr"}
    for lang in lang_version:
        try:
            url[lang] = html.find("li", {"class": lang_version[lang]}).a["href"] 
        except:
            pass
    
    return url


# -------------------------------------------------------------------------------------

# The words in the .tex-Files that are not among the 1000 most frequent 
# German words will be searched in Wikipedia.



with open("top1000de.txt","r",encoding="latin-1") as f:
    top1000=set(f.read().split())

# Hier das Verzeichnis eintragen, in dem sich die deutschen
# Brückenkurs-Quellen befinden.
    
BASE_DIR_MBK = "/home/stefan/projekte/VEUNDMINT_TUB_Brueckenkurs/module_veundmint"

remember_links={}

for root,dirs,files in os.walk(BASE_DIR_MBK):
    if root.find("VBKM")>-1:
        print (root)
        for fn in files:
            if fn.endswith('.tex') and fn.find('eng')==-1:
                print(os.path.join(root,fn))
                subprocess.Popen("/usr/bin/detex "+os.path.join(root,fn)+ " > intermediary.txt", shell=True)
                time.sleep(1)
                with open("intermediary.txt", "r", encoding="latin-1") as f:
                    text=f.read().replace(',',' ').replace('.',' ').replace(';',' ').replace('!',' ').replace('?',' ').split()
                    for word in text:
                        if re.search("[0-9]",word):
                            continue
                        if len(word)<3:
                            continue
                        if word[1]==word[1].upper():
                            continue
                        print(word)
                        if word[0]==word[0].upper() and word not in top1000 and word not in remember_links:
                            url=get_article(word)
                            if url:
                                
                                remember_links[word]=get_article(word)
                                time.sleep(1)
                                print (word, remember_links[word])


# Dump the whole information as json.

import json
with open("remember_links.json", "w", encoding="utf8") as f:
    json.dump(remember_links, f, ensure_ascii=False)
    
     
