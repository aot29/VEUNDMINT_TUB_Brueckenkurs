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

import re
import os
from lxml import etree
from lxml import html
from copy import deepcopy
from plugins.exceptions import PluginException
from lxml.html import html5parser
import fnmatch

from plugins.basePlugin import Plugin as basePlugin

from plugins.VEUNDMINT.tcontent import TContent

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

        self.ctree = TContent()
        if 'coursetree' in self.data:
            self.sys.message(self.sys.CLIENTWARN, "Another plugin created a content tree, it will be overwritten now")
            self.data['coursetree'] = self.ctree
        else:
            self.data['coursetree'] = self.ctree

     
    def create_output(self):
        self._prepareData()
        if self.options.forceyes == 0: self.check_if_dir_preexists(self.options.targetpath)
        self.sys.emptyTree(self.options.targetpath)
        self.sys.copyFiletree(self.options.converterCommonFiles, self.options.targetpath, ".")
        self.sys.timestamp("Common HTML5 tree files copied")
        
        self.setup_template()
        self.setup_contenttree()


        self.write_html_files()


    def setup_template(self):
        templatefile = open(os.path.join(self.options.converterTemplates, "template_" + self.name + ".html"), "rb")
        parser = html.HTMLParser()
        template = etree.parse(templatefile, parser).getroot()
        templatefile.close()
        head = template.find(".//head")
        title = template.find(".//title")
        content = template.find(".//div[@id='content']")
        
        path = os.path.join(self.options.targetpath, self.outputextension)
        self.sys.writeTextFile(os.path.join(path, "test.html"), etree.tostring(template, pretty_print = True).decode(), self.options.stdencoding)
        

        
    def setup_contenttree(self):
        
        # we need a real object tree instead of a XML tree which can have only text fields as attribute values and no code
        # copy tree structure from tocxml up to level 3, fill in level 4 and detailed infos from content
        
        maxlevel = 3
        root = self.ctree # the ROOT node of level 0
        nid = root.myid + 1
        
        # iterative traversal of the tree up to maxlevel 
        eparent = self.tocxml
        parent = root
        lev = 1
        pos = 1 # position = local section number = 1 + index in parent array
        node = eparent[pos-1]
        
        while(not node is None):
            q = TContent()
            q.myid = nid
            q.pos = pos
            nid += 1
            q.xmlelement = node # link object tree to xml tree
            node.attrib['objid'] = str(q.myid)
            q.level = lev
            if hasattr(node, "name"): q.nr = node.name
            q.title = node.text
            
            # optimizations to make tree identical to one from the old converter
            # remove chapter prefix from ttm and add a space for level 1
            if lev == 1: q.title = re.sub(r"Chapter (.)(.+)", r"\1 \2", q.title, 1, re.S)
            # remove the two utf8 characters where a space should be for level 2, what the hell is ttm doing there?
            if lev == 2: q.title = re.sub(r"(\d+\.\d+)..(.*)", r"\1 \2", q.title, 1, re.S)
            # add a space, don't know why it works
            if lev == 3: q.title = " " + q.title
                
            q.parent = parent
            parent.subcontents.append(q)

            if lev == 1:
                q.link = str(pos)
            else:
                q.link = q.parent.link + "." + str(pos)
            
            # process first child next if present
            if (lev < maxlevel) and (len(node) > 0):
                eparent = node
                parent = q
                node = node[0]
                lev += 1
                pos = 1
                continue
            
            # no child, process right neighbour if present
            if (pos < len(eparent)):
                pos += 1
                node = eparent[pos - 1]
                continue
            
            # no child and no right neighbour, move on level up if possible (probably several times)
            
            # python STILL supports no do loops
            while (not parent is None) and  (not eparent.getparent() is None) and (parent.pos >= len(eparent.getparent())):
                if (node is self.content):
                    node = None
                    break
                else:
                    eparent = eparent.getparent()
                    pos = parent.pos
                    parent = parent.parent
                    lev -= 1
                            
               
            if (not node is None) and (not eparent.getparent() is None):
                pos = parent.pos + 1
                parent = parent.parent
                node = eparent.getparent()[pos - 1]
                eparent = eparent.getparent()
                lev -= 1
            else:
                node = None

        # parse content to fill in information for level 3 and nodes for level 4
        
        lastcontent = None
        lev3parent = None
        
        # elements will appear according traversing of the tree
        for tupel in self.content:
            
            tocelement = tupel[0]
            contentelement = tupel[1]
            text = etree.tostring(contentelement, pretty_print = True, encoding = "unicode")
            
            if re.search(r"<!-- scontent;-", text, re.S):
                self.sys.message(self.sys.CLIENTERROR, "scontent environments no longer supported, consider turning them into xcontents")

            # extract section information from <!-- sectioninfo;;section;;subsection;;subsubsection;;nr_ausgeben;;testseite; //-->
            ms = re.search(r"<!-- sectioninfo;;(\w+?);;(\w+?);;(\w+?);;([01]);;([01]); //-->", text, re.S)
            sid = ""
            if ms:
                sec = int(ms.group(1))
                ssec = int(ms.group(2))
                sssec = int(ms.group(3))
                sid = str(sec) + "." + str(ssec) + "." + str(sssec)
                printnr = int(ms.group(4))
                testpage = int(ms.group(5))
            else:
                self.sys.message(self.sys.CLIENTERROR, "content element without sectioninfo found, cannot be processed")
                break
            
            if (ssec == 0):
                # level 2 content coming from an MSectionStart environment, will be attached to existing level 2 object
                p = root.elementByID(int(tocelement.attrib['objid']))
                if p is None:
                    self.sys.message(self.sys.CLIENTERROR, "Could not locate level 2 object of id = " + tocelement.attrib['objid'])
                if (p.level != 2):
                    self.sys.message(self.sys.CLIENTERROR, "Object of id = " + tocelement.attrib['objid'] + " is level " + str(p.level) + " instead of 2")
                p.xcontent = True
                p.ismodul = True
                p.display = False
                p.content = text
                p.docname = "sectionx" + str(sec) + "." + str(ssec)
                lastcontent = None
                pos = 1
                
                # move labels appearing in front into the next xcontent (should be done by preprocessor on latex level!), or labels are added before this parsing??
                """
                                my $sslabels = "";
                                if ($self->{LEVEL} eq 3) {
                                  if ($text =~ /(.*)<!-- xcontent;-;0;-;/s ) {
                                    my $pretext = $1;
                                    while ($pretext =~ s/<!-- mmlabel;;(.*?)\/\/-->//s ) { $sslabels = $sslabels . "<!-- mmlabel;;$1\/\/-->"; }
                                    while ($pretext =~ s/<a(.*?)>(.*?)<\/a>//si ) { $sslabels = $sslabels . "<a$1>$2<\/a>"; }
                                    $text =~ s/(.*)<!-- xcontent;-;0;-;/$pretext<!-- xcontent;-;0;-;/s ;
                                  }
                                }
                """
                
                
                
            else:
                # level 4 xcontent coming from MXContent inside a subsection, needs a new node, tocelement points wrongly to toc father node
                lev3parent = root.elementByID(int(tocelement.attrib['objid']))

                m = re.search(r"<!-- xcontent;-;(.*?);-;(.*?);-;(.*?);-;(.*?) //-->(.*?)<!-- endxcontent;;(.*?) //-->", text, re.S)
                if m:
                    i = int(m.group(1))
                    p = TContent()
                    p.parent = lev3parent
                    lev3parent.subcontents.append(p)
                    p.myid = nid
                    nid += 1
                    p.level = p.parent.level + 1
                    p.title = m.group(2)
                    p.ismodul = True
                    if m.group(3) != "":
                        p.caption = m.group(3)
                    else:
                        p.caption = p.title
                    self.sys.message(self.sys.VERBOSEINFO, "Created tcontent, title=" + p.title + ", caption=" + p.caption)
                    if i != int(m.group(6)):
                        self.sys.message(self.sys.CLIENTERROR, "start end end of xcontent " + i + " do not match")
                    
                    p.content = m.group(5)
                    p.icon = m.group(4) # will no longer be used
                    p.xcontent = True
                    p.display = True
                    if i == 0:
                        pos = 1
                        lastcontent = None # it's a modstart
                        p.modulid = "start"
                        p.docname = "modstart"
                        p.left = None
                        if p.parent.parent.xright is None:
                            p.parent.parent.xright = p
                        if p.parent.parent.parent.xright is None:
                            p.parent.parent.parent.xright = p.parent.parent
                    else:
                        p.modulid = "xcontent"
                        p.docname = "xcontent" + str(i)
                        p.left = lastcontent
                        lastcontent.right = p
    
                    p.pos = pos
                    p.link = p.parent.link + "/" + p.docname
                    p.menuitem = 0
                    p.nr = "" # actually used?
                    p.level = p.parent.level + 1
                    if p.level != 4:
                        self.sys.message(self.sys.CLIENTWARN, "xcontent did not get level 4")
                    
                    p.tocsymb = "status1"
                    if re.search(r"<!-- declaretestsymb //-->", p.content, re.S):
                        p.tocsymb = "status3"
                    if re.search(r"<!-- declareexcsymb //-->", p.content, re.S):
                        p.tocsymb = "status2"
                        
                    # create course ranged linking
                    """
                                        $p->{XPREV} = $XIDObj;
                                        if ($XIDObj != -1) {
                                        $XIDObj->{XNEXT} = $p;
                                        }
                                        $p->{XNEXT} = -1;
                                        $XIDObj = $p;
                    """
                    if testpage != 0: p.testsite = True
                    p.nr = sid
                    if i == 0:
                        p.parent.nr = str(sec) + "." + str(ssec)
                        p.parent.parent.nr = str(sec)
    
                    self.sys.message(self.sys.VERBOSEINFO, "xcontent " + p.title + " has number " + p.nr)
                    # expand <title>
                    p.title = self.options.moduleprefix + " Abschnitt " + sid + " " + p.title
                    # care for ttm problem: subsubsection titles appear without number prefix
                    pref = ""
                    if printnr == 1: pref = sid + " "
                    (p.content, n) = re.subn(r"<h4>(.*?)</h4><!-- sectioninfo;;" + str(sec) + ";;" + str(ssec) + ";;" + str(sssec) + ";;" + str(printnr) + ";;" + str(testpage) + r"; //-->", "<h4>{XCONTENTPREFIX}</h4><br \/><h4>" + pref + "\1</h4>", p.content, 0, re.S)
                    if (n != 1):
                        self.sys.message(self.sys.CLIENTERROR, "Could not substitute sectioninfo in xcontent " + p.title + ", n = " + n)
                                        
                    
                    # add numbers to MSubsubsections in MXContent
                    p.content = re.sub(r"<h4>(.+?)</h4><!-- sectioninfo;;(\w+?);;(\w+?);;(\w+?);;1;;([01]); //-->" ,"<h4>\2.\3.\4 \1</h4>", p.content, 0, re.S)
                    
                    p.next = None
                    pos = pos + 1
                    
                    lastcontent = p
                    
                else:
                    self.sys.message(self.sys.CLIENTERROR, "xcontent element of level 4 contains no xcontent information tags, cannot parse it")
                
        self.sys.message(self.sys.VERBOSEINFO, "Tree buildup: \n" + str(root))


                                      
                
                
        
        
        
    def write_html_files(self):
        
        
        # PERL: only dirs of form A.B.C and level 1/2/3 contents directly in mpl
        # tex2x: separate dirs A.B and content in them
        
        m = 0
        n = 0
        count_subsections = dict();
        for tupel in self.content:
            if (tupel[1].get("class") == (self.options.ModuleStructureClass + "0")):
                m = m + 1
                count_subsections = dict();
            n = n + 1
        
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
            n = n + 1
            count_subsections[tupel[0].get("name")][tupel[1].get("class")] += 1 # counter für bereich erhöhen
        
        self.sys.message(self.sys.CLIENTINFO, str(n) + "  " + self.outputextension + "-files have been written in utf8, " + str(m) + " of them have xcontent level zero")
      
    
    
    
# ------------------------------------------------- OLD OSS METHODS ----------------------------------------------------------------------------

            
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
                        

        
                
            
            