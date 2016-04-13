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
from tidylib import tidy_document
from copy import deepcopy
import locale

from plugins.exceptions import PluginException
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
        self.pagefactory = PageFactory(interface, self)
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

        for dat in ['uxids', 'siteuxids', 'wordindexlist', 'labels']:
            if dat in self.data:
                self.sys.message(self.sys.CLIENTWARN, dat + " list exists from another plugin, appending data to it and hoping it works out")
            else:
                self.data[dat] = []
        
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

        self.siteredirects = dict() # consists of pairs [ redirectfilename, redirectarget ]
        for t in self.options.sitetaglist:
            self.siteredirects[t] = [ t + "." + self.outputextension, "" ]

     
    def create_output(self):
        self.sys.timestamp("create_output start")
        self._prepareData()
        
        self.generate_directory()
        self.generate_css()
        
        self.setup_contenttree()
        self.analyze_html() # analyzation done on raw text
        self.analyze_nodes_stage1(self.ctree) # analyzation done inside nodes
        self.prepare_index()
        self.analyze_nodes_stage2(self.ctree) # analyzation parts using information from stage1 and the index
        
        for i in self.data['sections']:
            self.sys.message(self.sys.VERBOSEINFO, "Points in section " + i + " (" + self.data['sections'][i] + "): " + str(self.data['expoints'][i]) + ", of which " + str(self.data['testpoints'][i]) + " are in tests")
            self.sys.message(self.sys.VERBOSEINFO, "Sites in section " + i + ": " +  str(self.data['sitepoints'][i]))
        
        self.generate_html(self.ctree)
        self.generate_pdf()

        self.filecount = 0
        self.write_htmlfiles(self.ctree)
        self.write_miscfiles()
        
        self.finishing()
        
        
  
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
            q.fullpath = self.outputextension
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
            
            q.fullname = self.outputextension + "/" + q.link
            
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
                p.ismodul = True
                p.display = True
                p.content = text
                p.docname = "sectionx" + str(sec) + "." + str(ssec)
                p.link = p.docname
                p.fullname = self.outputextension + "/" + p.link + "." + self.outputextension
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
                    p.fullname = self.outputextension + "/" + p.link + "." + self.outputextension
                    m = re.search(r"(.*)/(.*?)\." + self.outputextension, p.fullname, re.S)
                    if m:
                        p.fullpath = m.group(1)
                    else:
                        self.sys.message(self.sys.CLIENTERROR, "Could not determine full path of tc element " + tc.title)
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


    # scan raw html for course scope relevant information tags, note that rawxml is not used in further computations
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
    def analyze_nodes_stage1(self, tc):
        # extract word index information (must be extracted before stage1 label management)
        def windex(m):
            idx = len(self.data['wordindexlist'])
            li = "ELI_SW" + str(idx)
            
            (w, n) = re.subn(r"\<math xmlns=\"(.*?)\"\>[\n ]*\<mrow\>\<mi\>(.+?)\</mi\>\</mrow\>\</math\>", "\\2", m.group(1), 0, re.S)
            if n > 0:
                self.sys.message(self.sys.VERBOSEINFO, "Removed MathML environments from index word: " + m.group(1) + " -> " + w)
            
            (w, n) = re.subn(r"\<math xmlns=\"(.*?)\"\>[\n ]*\<mrow\>\<mo\>(.+?)\</mo\>\</mrow\>\</math\>", "\\2", w, 0, re.S)
            if n > 0:
                self.sys.message(self.sys.VERBOSEINFO, "Removed MathML environments from index word containing symbols: " + m.group(1) + " -> " + w)

            if "<math" in w:
                self.sys.message(self.sys.CLIENTERROR, "Cannot remove MathML tag in index word: " + m.group(1))
            else:
                w = html.fromstring(w).text # decodes HTML tags to umlauts
                if w is None:
                    self.sys.message(self.sys.CLIENTERROR, "fromstring returned none (perhaps because of malformed MathML) for word " + m.group(1))
                else:
                    self.data['wordindexlist'].append((m.group(1), li, w))
                    self.sys.message(self.sys.VERBOSEINFO, "Found index: " + m.group(1) + ", index is " + str(idx) + ", whole group is " + m.group(0))
                
            return "<!-- mindexentry;;" + m.group(1) + "; //--><a class=\"label\" name=\"" + li + "\"></a><!-- mmlabel;;" + li + ";;" \
                   + m.group(2) + ";;" + m.group(3) + ";;" + m.group(4) + ";;" + m.group(5) + ";;13; //-->"

        # carefull with regex, last letter of m.group(1) could be a ; because of math symbol HTML tags, on the other hand expressions have to be greedy to prevent overlaps
        tc.content = re.sub(r"\<!-- mpreindexentry;;(.+?);;([^;]+?);;([^;]+?);;([^;]+?);;([^;]+?); //--\>", windex, tc.content, 0, re.S)
        

        # extract labels defined by the macro package: <!-- mmlabel;;LABELBEZEICHNER;;SUBJECTAREA;;SECTION;;SUBSECTION;;OBJEKTTYP;;ANCHORTAG; //-->
        def elabel(m):
            # labels defined inside math environments have data elements wrapped in an <mn>-tag
            lab = re.sub(r"\</?mn\>", "", m.group(1), 0, re.S)
            sub = re.sub(r"\</?mn\>", "", m.group(2), 0, re.S)
            sec = re.sub(r"\</?mn\>", "", m.group(3), 0, re.S)
            ssec = re.sub(r"\</?mn\>", "", m.group(4), 0, re.S)
            sssec =  re.sub(r"\</?mn\>", "", m.group(5), 0, re.S)
            ltype =  re.sub(r"\</?mn\>", "", m.group(6), 0, re.S)

            pl = tc.fullname + "#" + lab
            self.data['labels'].append((lab, sub, sec, ssec, sssec, ltype, pl))
            self.sys.message(self.sys.VERBOSEINFO, "Added label " + lab  + " in chapter " + sub + " with number " + sec + "." + ssec + "." + sssec + "  and type " + ltype + ", pagelink = " + pl)
            return "" # remoce the label tag entirely

        tc.content = re.sub(r"\<!-- mmlabel;;(.+?);;(.+?);;(.+?);;(.+?);;(.+?);;(.+?); //--\>", elabel, tc.content, 0, re.S)
        
        # check if it is a helpsite or a child of one
        if (not tc.parent is None) and tc.parent.helpsite:
            tc.helpsite = True
        else:
            m = re.search(r"(.*)HELPSECTION(.*)", tc.title, re.S)
            if m:
                self.sys.message(self.sys.CLIENTINFO, "Helpsection is being set")
                tc.title = m.group(1) + self.options.strings['module_helpsitetitle'] + m.group(2)
                tc.helpsite = True
            else:
                tc.helpsite = False
            
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

        # recursively analyze children
        for c in tc.children:
            self.analyze_nodes_stage1(c)


    # analyze node content, after stage1 has been executed on the whole tree
    def analyze_nodes_stage2(self, tc):

        # prevent line breaks after h4 tags (MSubsubsectionx)
        tc.content = re.sub(r"\</h4\>([ \n]*)\<div class=\"p\"\>\<!----\>\</div\>", "</h4>\n", tc.content, 0, re.S)
        
        # eliminate duplicate line breaks
        tc.content = re.sub(r"\<div class=\"p\"\>\<!----\>\</div\>([ \n]*)\<div class=\"p\"\>\<!---->\</div\>", "<div class=\"p\"><!----></div>", tc.content, 0, re.S)
        
        # expand potential line breaks
        tc.content = re.sub(r"\<div class=\"p\"\>\<!----\>\</div\>", "<br clear=\"all\"/><br clear=\"all\"/>", tc.content, 0, re.S)

        # insert searchtable if found
        tc.content = re.sub(r"\<!-- msearchtable //--\>", self.searchtable, tc.content, 0, re.S)
        
        # label management: expand reference tags using labels collected in stage1
        def refexpand(m):
            self.sys.message(self.sys.VERBOSEINFO, "Expanding link " + m.group(1))
            lab = m.group(1) # Labelstring
            prefi = int(m.group(2)) # 0 -> Number only, 1 ->  Prefix (i.e.. "Picture 3") present
            href = ""
            objtype = 0
            found = False
            for sl in self.data['labels']:
                if (sl[0] == lab):
                    found = True
                    href = sl[6] # without tc.backpath, which will be added by the link update function
                    self.sys.message(self.sys.VERBOSEINFO, "  href = " + href)
                    fb = int(sl[1])
                    sec = sl[2]
                    ssec = sl[3]
                    refindex = sl[4]
                    objtype = int(sl[5])

            if not found:
                self.sys.message(self.sys.CLIENTERROR, "Label " + lab + " has not been found by stage1, label list contains " + str(len(self.data['labels'])) + " items")
                objtype = 0
                return self.options.strings['brokenlabel']

            # label types must be consistent with macro file definition !

            ptext = ""
            reftext = ""
            
            # oh no, Python has no switch
            if objtype == 1:
                # sections are module numbers, displayed as a pure number without subsection numbers, index is irrelevant
                reftext = sec
                ptext = self.options.strings['module_labelprefix']

            elif objtype == 2:
                # subsections are MSubsections in modules, represented as SECTION.SUBSECTION, index is irrelevant
                reftext = sec + "." + ssec
                ptext = self.options.strings['subsection_labelprefix']

            elif objtype == 3:
                # subsubsections are prepresented as number triplet
                reftext = sec + "." + ssec + "." + refindex
                ptext = self.options.strings['subsubsection_labelprefix']

            elif objtype == 4:
                # a info box, given by a number triplet
                ptext = "Infobox"
                if ((fb == 1) or (fb == 2)):
                    reftext = sec + "." + ssec + "."  + refindex
                else:
                    reftext = ""
                    self.sys.message(self.sys.CLIENTWARN, "Reference " + lab + " to an info box given chapter index " + str(fb) + " without info box number")

            elif objtype == 5:
                # an exercise, represented by a number triplet
                ptext = self.options.strings['exercise_labelprefix']
                reftext = sec + "." + ssec + "." + refindex
                
            elif objtype == 6:
                # an example, represented by a number triplet
                ptext = self.options.strings['example_labelprefix']
                reftext = sec + "." + ssec + "." + refindex

            elif objtype == 7:
                # an experiment
                ptext = self.options.strings['experiment_labelprefix']
                reftext = sec + "." + ssec + "." + refindex
                
            elif objtype == 8:
                # an image, is referenced by a single number
                ptext = self.options.strings['image_labelprefix']
                if (((fb == 1) or (fb == 2) or (fb == 4)) and (prefi == 0)):
                    reftext = refindex
                else:
                    self.sys.message(self.sys.CLIENTWARN, "Reference " + lab + " to an image using chemistry settings not implemented yet")
                    reftext = refindex

            elif objtype == 9:
                # a table, is referenced by a single number
                ptext = self.options.strings['table_labelprefix']
                if (((fb == 1) or (fb == 2) or (fb == 4)) and (prefi == 0)):
                    reftext = refindex
                else:
                    self.sys.message(self.sys.CLIENTWARN, "Reference " + lab + " to a table using chemistry settings not implemented yet")
                    reftext = refindex
                    
            elif objtype == 10:
                # a equation, represented by a number triplet with braces
                # equation numbers force MLastIndex to be set to "equation" in TeX conversion
                ptext = self.options.strings['equation_labelprefix']
                reftext = "(" + sec + "." + ssec + "." + refindex + ")"

            elif objtype == 11:
                # a theorem or theoremx, represented by a number triplet
                ptext = self.options.strings['theorem_labelprefix']
                if (((fb == 1) or (fb == 2) or (fb == 4)) and (prefi == 0)):
                    reftext = sec + "." + ssec + "." + refindex
                else:
                    self.sys.message(self.sys.CLIENTWARN, "Reference " + lab + " to a theorem using chemistry settings not implemented yet")
                    reftext = sec + "." + ssec + "." + refindex

            elif objtype == 12:
                # a video, represented by a single number
                ptext = self.options.strings['video_labelprefix']
                if (((fb == 1) or (fb == 2) or (fb == 4)) and (prefi == 0)):
                    reftext = sec + "." + ssec + "." + refindex
                else:
                    self.sys.message(self.sys.CLIENTWARN, "Reference " + lab + " to a video using chemistry settings not implemented yet")
                    reftext = sec + "." + ssec + "." + refindex

            elif objtype == 13:
                # index entries in modules, only position S.SS.SSS is known
                reftext = sec + "." + ssec
                ptext = self.options.strings['subsection_labelprefix']

            else:
               self.sys.message(self.sys.CLIENTWARN, "An MRef reference of type " + str(objtype) + " from label " + lab + " has unknown type")
               reftext = ""

            if reftext != "":
                if (prefi == 1):
                    reftext = ptext + " " + reftext
                return "<a class=\"MINTERLINK\" href=\"" + href + "\">" + reftext + "</a>"

            self.sys.message(self.sys.CLIENTERROR, "Label " + lab + " could not be resolved")
            return self.options.strings['brokenlabel']
                
            # end refexpand
        tc.content = re.sub(r"\<!-- mmref;;(.+?);;(.+?); //--\>", refexpand, tc.content, 0, re.S)
        
        # label management: expand MSRef tags
        def srefexpand(m):
            self.sys.message(self.sys.VERBOSEINFO, "Expanding MSRef link " + m.group(1) + " of title " + m.group(2))
            lab = m.group(1)
            txt = m.group(2)
            href = ""
            for sl in self.data['labels']:
                if (sl[0] == lab):
                    href = sl[6]  # without tc.backpath, which will be added by the link update function
                    self.sys.message(self.sys.VERBOSEINFO, "  href = " + href)
  
            if href != "":
                return "<a class=\"MINTERLINK\" href=\"" + href + "\">" + txt + "</a>"
            else:
                self.sys.message(self.sys.CLIENTERROR, "Could not resolve MSRef on label " + lab + " with text " + txt)
                return self.options.strings['brokenlabel']

        tc.content = re.sub(r"\<!-- msref;;(.+?);;(.+?); //--\>", srefexpand, tc.content, 0, re.S)

       
        # recursively analyze children
        for c in tc.children:
            self.analyze_nodes_stage2(c)
            

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
            if not self.releaseCheck(tc.html, f):
                self.sys.message(self.sys.CLIENTWARN, "File " + f + " did not pass post release check")
                if self.options.dorelease == 1:
                    self.sys.message(self.sys.FATALERROR, "Refusing to create a release version due to check errors")
            self.sys.writeTextFile(f, tc.html, self.options.outputencoding)
            self.filecount += 1
            if "<!-- mglobalstarttag -->" in tc.html:
                self.sys.message(self.sys.CLIENTINFO, "Global starttag found in file " + f + ", locally " + tc.link)
                self.startfile = self.outputextension + "/" + tc.link + "." + self.outputextension
                self.entryfile = "entry_" + tc.docname + "." + self.outputextension
                
            # search for other tags and create redirects if found
            for s in self.options.sitetaglist:
                if "<!-- mglobal" + s + "tag -->" in tc.html:
                    self.sys.message(self.sys.CLIENTINFO, "Global " + s + "tag found in file " + f + ", locally " + tc.link)
                    self.siteredirects[s][1] = self.outputextension + "/" + tc.link + "." + self.outputextension
                    
            
    def write_miscfiles(self):
        # write redirects
        if self.startfile == "":
            self.sys.message(self.sys.FATALERROR, "No startfile found")
        else:
            self.createRedirect("index.html", self.startfile, False)
            self.sys.message(self.sys.CLIENTINFO, "HTML Tree entry chain created")
            self.sys.message(self.sys.CLIENTINFO, "  index.html -> " + self.startfile)
            if (self.options.doscorm == 1):
                self.createRedirect(self.entryfile, self.startfile, True)
                self.sys.message(self.sys.CLIENTINFO, "  SCORM -> " + self.entryfile + " -> " + self.startfile)

        for s in self.options.sitetaglist:
            if self.siteredirects[s][1] != "":
                self.createRedirect(self.siteredirects[s][0], self.siteredirects[s][1], False)

        # write SCORM manifest if needed
        if self.options.doscorm == 1:
            pass
        
        # write variables in conversion info file
        self.data['signature'] = self.sys.get_conversion_signature()
        # generate a course id which is unique (given course and version)
        self.data['signature']['CID'] = "(" + self.options.signature_main + ";;" + self.options.signature_version + ";;" + self.options.signature_localization + ")"
        self.sys.message(self.sys.CLIENTINFO, "Generating Course Signature:")
        self.sys.message(self.sys.CLIENTINFO, "     main: " + self.options.signature_main)
        self.sys.message(self.sys.CLIENTINFO, "  version: " + self.options.signature_version)
        self.sys.message(self.sys.CLIENTINFO, "   locale: " + self.options.signature_localization)
        self.sys.message(self.sys.CLIENTINFO, "timestamp: " + self.data['signature']['timestamp'])
        self.sys.message(self.sys.CLIENTINFO, "conv-user: " + self.data['signature']['convuser'])
        self.sys.message(self.sys.CLIENTINFO, "c-machine: " + self.data['signature']['convmachine'])
        self.sys.message(self.sys.CLIENTINFO, "      CID: " + self.data['signature']['CID'])
        self.sys.message(self.sys.CLIENTINFO, "Signature will be available in the HTML tree")

        s = "// Automatically generated by the tex2x VEUNDMINT output plugin\n" \
          + "var scormLogin = " + str(self.options.scormlogin) + ";\n" \
          + "var isRelease = " + str(self.options.dorelease) + ";\n" \
          + "var doCollections = " + str(self.options.docollections) + ";\n" \
          + "var isVerbose = " + str(self.options.doverbose) + ";\n" \
          + "var testOnly = " + str(self.options.testonly) + ";\n" \
          + "var signature_CID = \"" + self.data['signature']['CID'] + "\";\n"

        for vr in ["signature_main", "signature_version", "signature_localization", "do_feedback", "do_export", "reply_mail",
                   "data_server", "exercise_server", "feedback_service", "data_server_description", "data_server_user",
                   "footer_middle", "footer_right", "mainlogo", "stdmathfont"]:
            s += "var " + vr + " = \"" + getattr(self.options, vr) + "\";\n"
            
        
        if self.options.dorelease == 1:
            self.sys.message(self.sys.CLIENTINFO, "RELEASE VERSION will be generated")
        else:
            self.sys.message(self.sys.CLIENTINFO, "Nonrelease will be generated")
            s += "console.log(\"NON RELEASE VERSION\");\n"
            
        if self.options.doverbose == 1:
            self.sys.message(self.sys.CLIENTINFO, "Verboseversion will be generated")
            s += "console.log(\"VERBOSE VERSION\");\n"

        if self.options.do_feedback == 1:
            self.sys.message(self.sys.CLIENTINFO, "Feedbackversion will be generated")

        if self.options.do_export == 1:
            self.sys.message(self.sys.CLIENTINFO, "Exportversion will be generated")
        
        s += "var globalsections = [];\n"
        for i in range(len(self.data["sections"])):
            s += "globalsections[" + str(i) + "] = \"" + str(self.data["sections"][str(i)]) + "\";\n"

        for glb in ['sitepoints', 'expoints', 'testpoints']:
            s += "var global" + glb + " = [];\n"
            for i in range(len(self.data[glb])):
                s += "global" + glb + "[" + str(i) + "] = " + str(self.data[glb][str(i)]) + ";\n"
        

        self.sys.writeTextFile(os.path.join(self.options.targetpath, self.options.convinfofile), s, self.options.outputencoding)


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
        
        # parse color values (given as strings without # prefix), sorting them is just to beautify git diff results
        jcss += "var COLORS = new Object();\n"
        c = sorted(self.options.colors.items(), key = lambda x: x[0])
        for p in c:
            jcss += "COLORS." + p[0] + " = \"" + p[1] + "\";\n"
   
        # parse fonts
        jcss += "var FONTS = new Object();\n"
        c = sorted(self.options.fonts.items(), key = lambda x: x[0])
        for p in c:
            jcss += "FONTS." + p[0] + " = \"" + p[1] + "\";\n"
        
        # parse sizes
        jcss += "var SIZES = new Object();\n"
        c = sorted(self.options.sizes.items(), key = lambda x: x[0])
        for p in c:
            jcss += "SIZES." + p[0] + " = " + str(p[1]) + ";\n"
  

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
        # filename (containing the redirect) and target are given relative to top level directory
        if scorm:
            s = self.template_redirect_scorm
        else:
            s = self.template_redirect_basic
        s = re.sub(r"\$url", redirect, s, 0, re.S)
        self.sys.writeTextFile(os.path.join(self.options.targetpath, filename), s, self.options.outputencoding)
        self.sys.message(self.sys.CLIENTINFO, "Redirect created from " + filename + " to " + redirect)


    def finishing(self):
        # set linux usage flags for all files
        
        # perform borkification if requested
        if self.options.borkify == 1:
            self.sys.message(self.sys.CLIENTERROR, "Borkification procedures not implemented yet")
            # self.borkifyHTML()
            # self.minimizeJS()
        
        # set access rights
        p = subprocess.Popen(["chmod", "-R", self.options.accessflags, self.options.targetpath], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
        (chmod, err) = p.communicate()
        if p.returncode != 0:
            self.sys.message(self.sys.CLIENTERROR, "Could not set access flags on output folder " + self.options.targetpath)
        
        # final check for unwanted files in target
        for xt in [ "py", "pyc", "sty", "tex", "png~", "js~", "tex~", self.outputextension + "~"]:
            fl = self.sys.listFiles(os.path.join(self.options.targetpath, "*." + xt))
            if len(fl) > 0:
                self.sys.message(self.sys.CLIENTWARN, str(len(fl)) + " unwanted files with extension " + xt + " found in target directory")
                if self.options.dorelease == 1:
                    self.sys.message(self.sys.FATALERROR, "Aborting release because target directory is unclean")
                    
                    
        if self.options.dopdf == 1:
            pd = " and pdf (" + ",".join(doct for doct in self.options.generate_pdf) + ")"
        else:
            pd = ""
        self.sys.message(self.sys.CLIENTINFO, "FINISHED tree containing " + self.outputextension + pd)
            
        if self.options.dozip == 1:
            self.sys.pushdir()
            os.chdir(self.options.targetpath)
            zipfile = "tree.zip"
            p = subprocess.Popen(["zip", "-r", zipfile, os.path.join(self.options.targetpath, "*")], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
            (output, err) = p.communicate()
            self.sys.popdir()
            if p.returncode == 0:
                self.sys.message(self.sys.CLIENTINFO, "Added zip file " + zipfile)
            else:
                self.sys.message(self.sys.FATALERROR, "zip command error, last lines:" + output)
                    

    # prepares the searchword index by using the wordlist generated by the tcontent node iteration
    def prepare_index(self):
        # sort the list using the modified strings according to locale (for umlauts)
        self.data['wordindexlist'] = sorted(self.data['wordindexlist'], key = lambda entry: locale.strxfrm(entry[2]))
        self.sys.message(self.sys.CLIENTINFO, "Found " + str(len(self.data['wordindexlist'])) + " index entries")
        # create search table in html
        self.searchtable = "<div class='searchtable'>\n"
        for ki in range(len(self.data['wordindexlist'])):
            pr = 0
            if ki == 0:
                pr = 1
            else:
                if (self.data['wordindexlist'][ki][0] == self.data['wordindexlist'][ki - 1][0]):
                    pr = 0;
                else:
                    pr = 1
            if pr == 1:
                self.searchtable += "<br />" + self.data['wordindexlist'][ki][0] + ": "
            else:
                self.searchtable += " , "
            self.searchtable +=  "<!-- mmref;;" +  self.data['wordindexlist'][ki][1] + ";;1; //-->"
            
        self.searchtable += "</div>\n"
        

    def generate_pdf(self):
        if self.options.dopdf != 1:
            self.sys.message(self.sys.VERBOSEINFO, "PDF generation not activated in options")
            return
        
        self.sys.pushdir()
        os.chdir(self.options.sourceTEX)
        pdfok = True
        for doct in self.options.generate_pdf:
            tfile = doct
            docdesc = self.options.generate_pdf[doct]
            if tfile[-4:] != ".tex": 
                tfile = doct + ".tex"
            else:
                self.sys.message(self.sys.CLIENTWARN, "pdf texfile + " + doct + " should be without extension in options")
                pdfok = False
       
            self.sys.timestamp("Generating PDF file " + tfile + " (" + docdesc + ")")
            
            for cl in [ ["pdflatex", "-halt-on-error", "-interaction=errorstopmode", tfile], \
                        ["pdflatex", "-halt-on-error", "-interaction=errorstopmode", tfile], \
                        ["makeindex", "-q", doct], \
                        ["pdflatex", "-halt-on-error", "-interaction=errorstopmode", tfile]]:
                if pdfok:
                    p = subprocess.Popen(cl, stdout = subprocess.PIPE, shell = False, universal_newlines = True)
                    (output, err) = p.communicate()
                    if p.returncode < 0:
                        self.sys.message(self.sys.FATALERROR, "Call to " + cl[0] + " for file " + tfile + " was terminated by a signal (POSIX return code " + p.returncode + ")")
                        pdfok = False
                    else:
                        if p.returncode > 0:
                            self.sys.message(self.sys.CLIENTERROR, cl[0] + " could not process file " + tfile + ", error lines have been written to logfile")
                            s = output[-256:]
                            s = s.replace("\n",", ")
                            self.sys.message(self.sys.VERBOSEINFO, "Last " + cl[0] + " lines: " + s)
                            pdfok = False
                        else:
                            self.sys.timestamp(cl[0] + " finished successfully")
                    
                else:
                    self.sys.message(self.sys.CLIENTWARN, "Skipping system call to " + cl[0] + " on " + tfile + " due to previous tex errors")
                
  
            if pdfok:
                self.sys.timestamp("Generation of PDF files for " + tfile + " (" + docdesc + ") successfull")
                self.sys.copyFile("." , self.options.targetpath, doct + ".pdf")
                self.sys.message(self.sys.CLIENTINFO, "Generated " + doct + ".pdf in top level directory")
            else:
                self.sys.timestamp("PDF generation aborted for " + tfile)
  
        self.sys.popdir()
        

    # performs some basic checks if html code can be released to the public
    def releaseCheck(self, html, fname):
        reply = True
        # check for broken labels from internal label management
        if self.options.strings['brokenlabel'] in html:
            reply = False
            self.sys.message(self.sys.VERBOSEINFO, "Broken internal label found in html file " + fname)
            
        # check some basic unwanted substrings
        for tag in [['TODO',        'TODO line found'],
                    ['ToDo',        'ToDo line found'],
                    ['Todo',        'Todo line found'],
                    ['special',     'Word \"special\" found, some \\special command from TeX got through'],
                    ['XXX',         'Marker \"XXX\" found, something should be polished']
                   ]:
            if tag[0] in html:
                reply = False
                self.sys.message(self.sys.VERBOSEINFO, tag[1] + " in file " + fname)

        # check uxid processing
        uc = 0
        def ucount(m):
            nonlocal uc, reply
            uc += 1
            if (uc > 1):
                reply = False
                self.sys.message(self.sys.CLIENTWARN, "Found more then one site UXID in file " + fname + ": " + m.group(0))
        re.sub(re.escape("<!-- mdeclaresiteuxidpost;;") + r"(.+?)" + re.escape(";; //-->"), ucount, html, 0, re.S)
                    
        # check for proper HTML syntax
        (document, tidylines) = tidy_document(html)

        # tidy error messages are of the following form:
        # line 213 column 35 - Error: <tocnavsymb> is not recognized!
        # line 213 column 35 - Warning: discarding unexpected <tocnavsymb>

        wrn = 0
        inf = 0
        def tidyerrline(m):
            nonlocal reply, fname, wrn, inf
            if m.group(3) == "Error":
                ok = False
                for tag in self.options.specialtags:
                    if m.group(4) == "<" + tag + "> is not recognized!":
                        ok = True
                if not ok:
                    self.sys.message(self.sys.CLIENTWARN, "libtidy found error in " + fname + ": " + m.group(0))
                    reply = False
            elif m.group(3) == "Warning":
                wrn += 1
            elif m.group(3) == "Info":
                inf += 1
            else:
                self.sys.message(self.sys.CLIENTERROR, "libtidy line could not be parsed: " + m.group(0))
            
        re.sub(r"line (\d*) column (\d*) - ([^\:]+): ([^\n]*)(?=\n)", tidyerrline, tidylines, 0, re.S)
        if wrn > 0:
            self.sys.message(self.sys.VERBOSEINFO, "libtidy found " + str(wrn) + " warnings and " + str(inf) + " infos in file " + fname)
        else:
            self.sys.message(self.sys.CLIENTWARN, "libtidy found no errors (or its output was somehow not parsed correctly) for file " + fname)
            
                 
        return reply
                
            
            
    