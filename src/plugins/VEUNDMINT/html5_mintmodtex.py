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
import subprocess
from lxml import etree
from lxml import html
from copy import deepcopy
from plugins.exceptions import PluginException
from lxml.html import html5parser

from plugins.basePlugin import Plugin as basePlugin

from plugins.VEUNDMINT.tcontent import TContent
from plugins.VEUNDMINT.pagefactory import PageFactory

class Plugin(basePlugin):

    def __init__(self, interface):
        # initialize data which is global for each conversion
        # copy interface member references
        self.sys = interface['system']
        self.data = interface['data']
        self.options = interface['options']
        self.name = "HTML5_MINTMODTEX"
        self.version ="P0.1.0"
        self.outputextension = "html"
        self.pagefactory = PageFactory(interface)
        self.sys.message(self.sys.VERBOSEINFO, "Output plugin " + self.name + " of version " + self.version + " constructed")

    def _prepareData(self):
        # initialize data which should be cleaned for each conversion
        self.startfile = "" # will be written once starttag is found
        self.entryfile = ""
        
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
            self.tocxml = ""

        if 'rawxml' in self.data:
            self.rawxml = self.data['rawxml']
        else:
            self.sys.message(self.sys.CLIENTERROR, "tex2x did not provide rawxml in data structure")
            self.rawxml = ""

        for dat in ['DirectRoulettes', 'macrotex', 'modmacrotex', 'DirectHTML', 'directexercises', 'autolabels', 'copyrightcollection', 'htmltikz']:
            if not dat in self.data:
                self.sys.message(self.sys.CLIENTERROR, "Preprocessors did not provide " + dat)

        self.ctree = TContent()
        if 'coursetree' in self.data:
            self.sys.message(self.sys.CLIENTWARN, "Another plugin created a content tree, it will be overwritten now")
            self.data['coursetree'] = self.ctree
        else:
            self.data['coursetree'] = self.ctree
            
        for dat in ['sitepoints', 'expoints', 'testpoints', 'sections']:
            if dat in self.data:
                self.sys.message(self.sys.CLIENTWARN, "Data element " + dat + " was created by another plugin, appending data to it and hoping it works out")
            else:
                self.data[dat] = dict()
                
        if 'uxids' in self.data:
            self.sys.message(self.sys.CLIENTWARN, "uxid lists exists from another plugin, appending data to it and hoping it works out")
        else:
            self.data['uxids'] = [] # contains tuplets 
            
        if 'siteuxids' in self.data:
            self.sys.message(self.sys.CLIENTWARN, "siteuxid lists exists from another plugin, appending data to it and hoping it works out")
        else:
            self.data['siteuxids'] = [] # contains tuplets
        
        if (self.options.feedback_service != ""):
            self.sys.message(self.sys.CLIENTINFO, "Feedback server declared: " + self.options.feedback_service)
        else:
            self.sys.message(self.sys.CLIENTERROR, "No feedback server declared in options, feedback send will not be possible")

        if (self.options.data_server != ""):
            self.sys.message(self.sys.CLIENTINFO, "Data server declared: " + self.options.data_server + " (" + self.options.data_server_description + ")")
        else:
            self.sys.message(self.sys.CLIENTERROR, "No data server declared in options")
            
        if (self.options.exercise_server != ""):
            self.sys.message(self.sys.CLIENTINFO, "Exercise server declared: " + self.options.exercise_server)
        else:
            self.sys.message(self.sys.CLIENTERROR, "No exercise server declared in options")
        
        self.template_redirect_basic = self.sys.readTextFile(self.options.template_redirect_basic, self.options.stdencoding)
        self.template_redirect_scorm = self.sys.readTextFile(self.options.template_redirect_scorm, self.options.stdencoding)


     
    def create_output(self):
        self.sys.timestamp("create_output start")
        self._prepareData()
        
        self.generate_directory()
        self.generate_css()
        
        self.setup_contenttree()
        self.analyze_html() # analyzation done on raw text
        self.analyze_nodes(self.ctree) # analyzation done inside nodes
        
        for i in self.data['sections']:
            self.sys.message(self.sys.VERBOSEINFO, "Points in section " + i + " (" + self.data['sections'][i] + "): " + str(self.data['expoints'][i]) + ", of which " + str(self.data['testpoints'][i]) + " are in tests")
            self.sys.message(self.sys.VERBOSEINFO, "Sites in section " + i + ": " +  str(self.data['sitepoints'][i]))
        
        self.generate_html(self.ctree)

        self.filecount = 0
        self.write_htmlfiles(self.ctree)
        self.write_miscfiles()
        
        
  
        self.sys.message(self.sys.CLIENTINFO, str(self.filecount) + " files written to directory " + self.outputextension)
        
        
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
            q.root = root
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
            parent.children.append(q)

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
                p.display = True
                p.content = text
                p.docname = "sectionx" + str(sec) + "." + str(ssec)
                lastcontent = None
                pos = 1
                
                # move labels appearing in front into the next xcontent (should be done by preprocessor on latex level!), or labels are added before this parsing??
                # mdeclaresection too!
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
                    p.root = root
                    lev3parent.children.append(p)
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
                    p.backpath = p.parent.backpath + "../" # level 4 xcontents are located in html/X.Y.Z/.
                    p.menuitem = 0
                    p.nr = "" # actually used?
                    p.level = p.parent.level + 1
                    if p.level != self.options.contentlevel:
                        self.sys.message(self.sys.CLIENTWARN, "xcontent did not get level " + str(self.options.contentlevel) + " as required by options")
                    
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
                    
                    
                    secprefix = ""
                    q = p.parent
                    while (not q is None):
                        if (q.level > 0) and (q.title != ""):
                            ti = q.title
                            ti = re.sub(r"(.*?) (.*)", r"\1", ti, 0, re.S) # remove module number prefix from title
                            if (secprefix != ""):
                                secprefix = ti + "  - " + secprefix
                            else:
                                secprefix = ti
                        q = q.parent
                    
                    pref = ""
                    if printnr == 1: pref = sid + " "
                    (p.content, n) = re.subn(r"<h4>(.*?)</h4><!-- sectioninfo;;" + str(sec) + ";;" + str(ssec) + ";;" + str(sssec) + ";;" + str(printnr) + ";;" + str(testpage) + r"; //-->", "<h4>" + secprefix + "</h4><br /><h4>" + pref + r"\1</h4>", p.content, 0, re.S)
                    if (n != 1):
                        self.sys.message(self.sys.CLIENTERROR, "Could not substitute sectioninfo in xcontent " + p.title + ", n = " + n)
                                        
                    
                    # add numbers to MSubsubsections in MXContent
                    p.content = re.sub(r"<h4>(.+?)</h4><!-- sectioninfo;;(\w+?);;(\w+?);;(\w+?);;1;;([01]); //-->" ,r"<h4>\2.\3.\4 \1</h4>", p.content, 0, re.S)
                    
                    p.next = None
                    pos = pos + 1
                    
                    lastcontent = p
                    
                else:
                    self.sys.message(self.sys.CLIENTERROR, "xcontent element of level 4 contains no xcontent information tags, cannot parse it")
                
        self.sys.message(self.sys.VERBOSEINFO, "Tree buildup: \n" + str(root))


    # scan raw html for course scope relevant information tags
    def analyze_html(self):
        
        # output user debug messages
        def cmessage(m):
            self.sys.message(self.sys.DEBUGINFO, m.group(1))
            return "<!-- debug;;" + m.group(1) + "; //-->"
        self.rawxml = re.sub(r"\<!-- debugprint;;(.+?); //--\>", cmessage, self.rawxml, 0, re.S)
        
        # write section names to dict indexed by section numbers minus one (like an array but with strings)
        def dsect(m):
            if m.group(1) == "1": #  = chapter = lev1 node position, >1 => not part of course modules
                i = str(int(m.group(2)) - 1)
                self.data['sections'][i] = m.group(3)
                self.sys.message(self.sys.VERBOSEINFO, "Created section element " + i + ": " + m.group(3))
            return "" # remove the tag
        self.rawxml = re.sub(r"\<!-- mdeclaresection;;(.+?);;(.+?);;(.+?);; //--\>", dsect, self.rawxml, 0, re.S) 

        m = re.search(r"\<!-- mlocation;;(.+?);;(.+?);;(.+?);; //--\>", self.rawxml, re.S)
        if m:
            self.data['locationicon'] = m.group(1)
            self.data['locationlong'] = m.group(2)
            self.data['locationshort'] = m.group(3)
            self.data['locationsite'] = "location.html"
            self.sys.message(self.sys.CLIENTINFO, "Using location declaration: " + self.data['locationlong']);
        else:
            self.sys.message(self.sys.CLIENTINFO, "Location declaration not found, no location button will be generated")
        

    # scan tree content elements for course scope relevant information tags
    def analyze_nodes(self, tc):
        for c in tc.children:
            self.analyze_nodes(c)
            
        # add points of exercises to global counters
        def dpoint(m):
            if m.group(5) == "1": #  = chapter = lev1 node position, >1 => not part of course modules
                i = str(int(m.group(1)) - 1)
                if i in self.data['expoints']:
                    self.data['expoints'][i] += int(m.group(3))
                else:
                    self.data['expoints'][i] = int(m.group(3))
                if m.group(4) == "1":
                    if i in self.data['testpoints']:
                        self.data['testpoints'][i] += int(m.group(3))
                    else:
                        self.data['testpoints'][i] = int(m.group(3))
                # self.sys.message(self.sys.VERBOSEINFO, "POINTS: Module " + m.group(1) + ", id " + m.group(2) + ", points " + m.group(3) + ", intest " + m.group(4) + ", chapter " + m.group(5))
            return "" # remove the tag
        tc.content = re.sub(r"\<!-- mdeclarepoints;;(.+?);;(.+?);;(.+?);;(.+?);;(.+?);; //--\>", dpoint, tc.content, 0, re.S)

        # write uxids to content elements, save used uxids in global list and check for duplicates
        def duxid(m):
            for u in self.data['uxids']:
                if (u[0] != "UXAUTOGENERATED") and (u[0] == m.group(1)): # autouxes will never appear in point giving exercises (hopefully)
                    self.sys.message(self.sys.CLIENTERROR, "Duplicate UXID " + u[0] + " mit id1 = " + u[2] + ", id2 = " + m.group(3))
                    return ""
            self.data['uxids'].append([m.group(1), m.group(2), m.group(3)])
            return "" # remove the tag
        tc.content = re.sub(r"\<!-- mdeclareuxid;;(.+?);;(.+?);;(.+?);; //--\>", duxid, tc.content, 0, re.S)
        
        # write siteuxids to content elements, save used siteuxids in global list and check for duplicates
        def dsuxid(m):
            s = "<!-- mdeclaresiteuxidpost;;" + m.group(1) + ";; //-->"
            if m.group(2) == "1":
                i = str(int(m.group(3)) - 1)
                if i in self.data['sitepoints']:
                    self.data['sitepoints'][i] += 1
                else:
                    self.data['sitepoints'][i] = 1
            for u in self.data['siteuxids']:
                if u[0] == m.group(1):
                    self.sys.message(self.sys.CLIENTERROR, "SITEUXID " + u[0] + " mit id1 = " + u[2] + ", id2 = " + m.group(3))
                    return s
            self.data['siteuxids'].append([m.group(1), m.group(2), m.group(3)])
            return s
        tc.content = re.sub(r"\<!-- mdeclaresiteuxid;;(.+?);;(.+?);;(.+?);; //--\>", dsuxid, tc.content, 0, re.S)
        # siteuxidpost will be grabbed by postprocessing and fill uxid property of tcontent object


    # generates html file content using the page factory object for the entire tree (given by its root node)
    def generate_html(self, tc):
        for c in tc.children:
            self.generate_html(c)
        self.pagefactory.generate_html(tc)
        
        
    def write_htmlfiles(self, tc):
        for c in tc.children:
            self.write_htmlfiles(c)
        if tc.display:
            f = os.path.join(self.options.targetpath, self.outputextension, tc.link + "." + self.outputextension)
            self.sys.writeTextFile(f, tc.html, self.options.outputencoding)
            self.filecount += 1
            if "<!-- mglobalstarttag -->" in tc.html:
                self.sys.message(self.sys.CLIENTINFO, "Global starttag found in file " + f + ", locally " + tc.link)
                self.startfile = tc.link + self.outputextension
                self.entryfile = "entry_" + tc.docname + self.outputextension
  
            """
        if ($htmlzeile =~ m/<!-- mglobalchaptertag -->/ ) {
          logMessage($VERBOSEINFO, "--- Chaptertag found in file $hfilename");
          $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
          $chapterfile = "mpl/" . $2 . ".html";
        }
        if ($htmlzeile =~ m/<!-- mglobalconftag -->/ ) {
          logMessage($VERBOSEINFO, "--- Configtag found in file $hfilename");
          $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
          $configfile = "mpl/" . $2 . ".html";
        }
        if ($htmlzeile =~ m/<!-- mglobaldatatag -->/ ) {
          logMessage($VERBOSEINFO, "--- Datatag found in file $hfilename");
          $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
          $datafile = "mpl/" . $2 . ".html";
        }
        if ($htmlzeile =~ m/<!-- mglobalfavotag -->/ ) {
          print "--- Favoritestag found in file $hfilename\n";
          $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
          $favofile = "mpl/" . $2 . ".html";
        }
        if ($htmlzeile =~ m/<!-- mgloballocationtag -->/ ) {
          logMessage($VERBOSEINFO, "--- Locationtag found in file $hfilename");
          $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
          $locationfile = "mpl/" . $2 . ".html";
        }
        if ($htmlzeile =~ m/<!-- mglobalsearchtag -->/ ) {
          logMessage($VERBOSEINFO, "--- Searchtag found in file $hfilename");
          $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
          $searchfile = "mpl/" . $2 . ".html";
        }
        if ($htmlzeile =~ m/<!-- mglobalstesttag -->/ ) {
          logMessage($VERBOSEINFO, "--- STesttag found in file $hfilename");
          $hfilename =~ m/(.+)\/mpl\/(.+?).html/ ;
          $stestfile = "mpl/" . $2 . ".html";
        }
      }
            """        
            
    def write_miscfiles(self):
        if self.startfile == "":
            self.sys.message(self.sys.FATALERROR, "No startfile found")
        else:
            self.createRedirect("index.html", self.startfile, False)
            self.sys.message(self.sys.CLIENTINFO, "HTML Tree entry chain created")
            self.sys.message(self.sys.CLIENTINFO, "  index.html -> " + self.startfile)
            if (self.options.doscorm == 1):
                self.createRedirect(self.entryfile, self.startfile, True)
                self.sys.message(self.sys.CLIENTINFO, "  SCORM -> " + self.entryfile + " -> " + self.startfile)


        
        """  
  if ($chapterfile ne "") { createRedirect("chapters.html", $chapterfile,0); } else { logMessage($CLIENTINFO, "No Chapter-file defined"); }
  if ($configfile ne "") { createRedirect("config.html", $configfile,0); } else { logMessage($CLIENTINFO, "No Config-file defined"); }
  if ($datafile ne "") { createRedirect("cdata.html", $datafile,0); } else { logMessage($CLIENTINFO, "Keine Data-Datei definiert"); }
  if ($searchfile ne "") { createRedirect("search.html", $searchfile,0); } else { logMessage($CLIENTINFO, "Keine Search-Datei definiert"); }
  if ($favofile ne "") { createRedirect("favor.html", $favofile,0); } else { logMessage($CLIENTINFO, "Keine Favoriten-Datei definiert"); }
  if ($locationfile ne "") { createRedirect("location.html", $locationfile,0); } else { logMessage($CLIENTINFO, "Keine Location-Datei definiert"); }
  if ($stestfile ne "") { createRedirect("stest.html", $stestfile,0); } else { logMessage($CLIENTINFO, "Keine Starttest-Datei definiert"); }
        """

        if self.options.doscorm == 1:
            pass
        


    # generate css and js style files
    def generate_css(self):
        
        path = os.path.join(self.options.sourcepath, self.options.template_precss)
        self.sys.copyFiletree(self.options.converterDir, self.options.sourcepath, self.options.template_precss)
        self.sys.pushdir()
        os.chdir(path)
        
        p = subprocess.Popen(["php", "-n", "grundlagen.php"], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
        (css, err) = p.communicate()
            
        if p.returncode != 0:
            css = ""
            self.sys.message(self.sys.CLIENTERROR, "php reported an error on grundlagen.php:\n" + str(css) + "\n" + str(err))

        jcss = ""
        ocss = ""
        
        # parse color values (given as strings without # prefix)
        jcss += "var COLORS = new Object();\n"
        for ckey in self.options.colors:
            jcss += "COLORS." + ckey + " = \"" + self.options.colors[ckey] + "\";\n"
   
        # parse fonts
        jcss += "var FONTS = new Object();\n"
        for ckey in self.options.fonts:
            jcss += "FONTS." + ckey + " = \"" + re.escape(self.options.fonts[ckey]) + "\";\n"
        
        # parse sizes
        jcss += "var SIZES = new Object();\n"
        for ckey in self.options.sizes:
            jcss += "SIZES." + ckey + " = " + str(self.options.sizes[ckey]) + "\n"
  

        # substitute colors, fonts and sizes in css files, but generate a original css file as JS without substitutions
        jcss += "var DYNAMICCSS = \"\"\n"
        def drow(m):
            nonlocal ocss
            nonlocal jcss
            row = m.group(1)
            ocss += row + "\n"
            row = self.sys.injectEscapes(row)
            jcss += " + \"" + row + "\"\n"
        re.sub(r"([^\n]+)", drow, css, 0, re.S)
        
        jcss += " + \"\";"
         
        self.sys.writeTextFile(os.path.join(self.options.targetpath, "css", "grundlagen.css"), ocss, self.options.outputencoding)
        self.sys.writeTextFile(os.path.join(self.options.targetpath, "dynamiccss.js"), jcss, self.options.outputencoding)
        self.sys.popdir()
        self.sys.message(self.sys.VERBOSEINFO, "Stylefiles created")


    def generate_directory(self):
        if self.options.forceyes == 0:
            self.check_if_dir_preexists(self.options.targetpath)
        self.sys.emptyTree(self.options.targetpath)
        self.sys.copyFiletree(self.options.converterCommonFiles, self.options.targetpath, ".")
        if self.options.localjax == 1:
            mpath = os.path.join(self.options.targetpath, "MathJax")
            self.sys.emptyTree(mpath)
            p = subprocess.Popen(["tar", "-xvzf", os.path.join(self.options.converterDir, self.options.mathjaxtgz), "--directory=" + mpath],
                                 stdout = subprocess.PIPE, shell = False, universal_newlines = True)
            (tar, err) = p.communicate()
            if p.returncode != 0:
                self.sys.message(self.sys.CLIENTERROR, "Could not unpack local MathJax folder:\n" + tar + "\n" + str(err))
            else:
                self.sys.message(self.sys.CLIENTINFO, "Local MathJax installed (from " + self.options.mathjaxtgz + ") in path " + mpath)
            

    def createRedirect(self, filename, redirect, scorm):
        # redirects always reside in target directory top level
        if scorm:
            s = self.template_redirect_scorm
        else:
            s = self.template_redirect_basic
        s = re.sub(r"\$url", redirect, s, 0, re.S)
        self.sys.writeTextFile(os.path.join(self.options.targetpath, filename), s, self.options.outputencoding)
        self.sys.message(self.sys.CLIENTINFO, "Redirect created from " + filename + " to " + redirect)
