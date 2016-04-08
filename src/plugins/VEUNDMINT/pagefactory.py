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
    This is html5 output plugin PageFactory object
    Version P0.1.0, needs to be consistent with mintmod.tex and the preprocessor plugin
"""

import re
import os
import subprocess
from lxml import etree
from lxml import html
from copy import deepcopy
from plugins.exceptions import PluginException
from lxml.html import HTMLParser
from lxml.html import fragment_fromstring as frag_fromstring # must be this one: html5parser.HTMLParser does not accept JS
from lxml.html import fromstring as hp_fromstring
from lxml.html.html5parser import HTMLParser as HTML5Parser
from lxml.html.html5parser import fromstring as h5_fromstring
from lxml import etree
import fnmatch

class PageFactory(object):

    def __init__(self, interface, outputplugin):
        self.sys = interface['system']
        self.data = interface['data']
        self.options = interface['options']
        self.outputplugin = outputplugin
        self._load_templates()
        
    def _load_templates(self):
        if self.options.doscorm == 0:
            self.sys.message(self.sys.CLIENTINFO, "Using HTML5 MINTMODTEX template")
            self.template_html5 = self.sys.readTextFile(self.options.template_html5, self.options.stdencoding)
        else:
            self.sys.message(self.sys.FATALERROR, "SCORM interface not supported yet")
            
        # fixed template texts will be inserted automaticall at div ids identical to the option name starting with template_
        
        self.template_javascriptheader = self.sys.readTextFile(self.options.template_javascriptheader, self.options.stdencoding)
        self.template_javascriptfooter = self.sys.readTextFile(self.options.template_javascriptfooter, self.options.stdencoding)

        self.template_mathjax_settings = self.sys.readTextFile(self.options.template_mathjax_settings, self.options.stdencoding)
        if self.options.localjax == 1:
            self.sys.message(self.sys.CLIENTINFO, "MathJax will be used locally")
            self.template_mathjax_include = self.sys.readTextFile(self.options.template_mathjax_local, self.options.stdencoding)
        else:            
            self.sys.message(self.sys.CLIENTINFO, "MathJax will be included from MathJax CDN")
            self.template_mathjax_include = self.sys.readTextFile(self.options.template_mathjax_cdn, self.options.stdencoding)
            
            
    def _substitute_string(self, html, cstr, insertion):
        # carefull: parser turns <div ....></div> into <div ... /> but not if a whitespace is inside
        (html, n) = re.subn(r"\<div (.*?)class=\"" + re.escape(cstr) + r"\"(.*?)\>(.+?)\</div\>", "<div \\1class=\"" + cstr + "\"\\2>" + insertion + "</div>", html, 0, re.S)
        if n <= 0:
            self.sys.message(self.sys.CLIENTERROR, "div replacement (class=\"" + cstr + "\") happened " + str(n) + " times")
        return html
            

    def _append_string(self, html, cstr, append):
        # carefull: parser turns <div ....></div> into <div ... />
        (html, n) = re.subn(r"\<div (.*?)class=\"" + re.escape(cstr) + r"\"(.*?)\>(.+?)\</div\>", "<div \\1class=\"" + cstr + "\"\\2></div>" + append, html, 0, re.S)
        if n <= 0:
            self.sys.message(self.sys.CLIENTERROR, "div append (class=\"" + cstr + "\") happened " + str(n) + " times")
        return html
            
    # generates a html page as a string using loaded templates and the given TContent object
    def generate_html(self, tc):
        if (tc.display == False):
            tc.html = "<html>NODISPLAY</html>"
            return

        template = etree.fromstring(self.template_html5)
        #template = h5_fromstring(self.template_html5)
        
        # do substitutions supported by lxml parsers and etree
        
        template.find(".//title").text = tc.title
        template.find(".//meta[@id='meta-charset']").attrib['content'] = "text/html; charset=" + self.options.outputencoding

        # do pure string substitutions, link updates to match tc location in the tree will be done later

        tc.html = etree.tostring(template, pretty_print = True, encoding = "unicode") # will always be unicode, output encoding for written files will be determined later

        # solve some problems arising from standard html parsers
        tc.html = self._correcthtml5(tc.html)

        cs_text = ""
        for cs in self.options.stylesheets:
            cs_text += "<link rel=\"stylesheet\" type=\"text/css\" href=\"" + cs + "\"/>\n"
        js_text = ""     
        for js in self.options.scriptheaders:
            js_text += "<script src=\"" + js + "\" type=\"text/javascript\"></script>\n"

        tc.html = self._substitute_string(tc.html, "mathjax-header", self.template_mathjax_settings + self.template_mathjax_include)
        tc.html = self._substitute_string(tc.html, "javascript-header", cs_text)
        tc.html = self._substitute_string(tc.html, "javascript-body-header", js_text + self.template_javascriptheader)
        tc.html = self._substitute_string(tc.html, "javascript-body-footer", self.template_javascriptfooter)

        tc.html = self._append_string(tc.html, "toccaption", self.gettoccaption(tc))
        tc.html = self._substitute_string(tc.html, "navi", self.getnavi(tc))
        tc.html = self._substitute_string(tc.html, "footerright", self.options.footer_right)
        tc.html = self._substitute_string(tc.html, "footermiddle", self.options.footer_middle)
        tc.html = self._substitute_string(tc.html, "content", tc.content)

        tc.html = self.postprocessing(tc.html, tc)


        # compute number of chapters and section numbers
        pp = tc
        idstr = ""
        ssn = -1
        while pp.level != (self.options.contentlevel - 4):
            if pp.level == (self.options.contentlevel - 2):
                ssn = pp.nr
            if (idstr == ""):
                idstr = str(pp.pos)
            else:
                idstr = str(pp.pos) + "." + idstr
            pp = pp.parent
            
        
        # provide tc attributes as JS variables inside the html
        js = ""
        js += "var SITE_ID = \"" + idstr + "\";\n" \
           +  "var SITE_UXID = \"" + tc.uxid + "\";\n" \
           +  "var SECTION_ID = " + ssn + ";\n" \
           +  "var docName = \"" + tc.docname + "\";\n" \
           +  "var fullName = \"" + self.outputplugin.outputextension + "/" + tc.link + "." + self.outputplugin.outputextension + "\";\n" \
           +  "var linkPath = \"" + tc.backpath + "\";\n"
       
        tc.html = tc.html.replace("// <JSCRIPTPRELOADTAG>", js + "// <JSCRIPTPRELOADTAG>")

        
        tc.html = self.update_links(tc.html, tc.backpath)

        
        
    def gettoccaption(self, tc):
        c = ""
        # Nummer des gerade aktuellen Fachbereichs ermitteln
        pp = tc
        fsubi = -1
        while (pp.level != (self.options.contentlevel - 3)):
            if pp.level == (self.options.contentlevel - 2):
                fsubi = pp.myid
            pp = pp.parent
        
        attr = ""
        root = tc.root
        
        pages1 = root.children
        n1 = len(pages1)

        c += "<tocnavsymb><ul>"
        c += "<li><a class=\"MINTERLINK\" href=\"" + self.outputplugin.siteredirects['chapter'][0] + "\" target=\"_new\"><div class=\"tocmintitle\">" + self.options.strings['module_content'] + "</div></a>"
        c += "<div><ul>\n"
   
        i1 = 0; # eigentlich for-schleife, aber hier nur Kursinhalt
        p1 = pages1[i1]
        if (p1.myid  == tc.myid):
            attr = " class=\"selected\""
        else:
            attr = " class=\"notselected\""
  
        attr = ""
        ff = i1 + 1

        # Fachbereiche ohne Nummern anzeigen
        ti = re.sub(r"([12345] )(.*)", "\\2", p1.title, 1, re.S)
        c += "<li" + attr + "><a class=\"MINTERLINK\" href=\"" + p1.fullname  + "\">" + ti + "</a>\n" 

        pages2 = p1.children
        n2 = len(pages2)
        if (n2 > 0):
            for i2 in range(n2):
                p2 = pages2[i2]
                ti = i2;
                selected = 0
                # pruefen ob Knoten oder oberknoten der aktuell auszugeben Seite ($site) das $p2 ist
                test = tc;
                while not test.parent is None:
                    if p2.myid == test.myid: selected = 1
                    test = test.parent
                # Stil der tocminbuttons wird in intersite.js gesetzt
                c += "  <li><a class=\"MINTERLINK\" href=\"" + p2.fullname + "\"><div class =\"tocminbutton\">" \
                  +  self.options.strings['chapter'] + " " + str(ti + 1) + "</div></a>\n"
                if fsubi != -1: 
                    # Untereintraege immer einfuegen im neuen Stil
                    pages3 = p2.children
                    n3 = len(pages3)
                    if n3 > 0:
                        c += "    <div><ul>\n"
                        for i3 in range(n3):
                            p3 = pages3[i3]
                            if (selected == 1):
                                tsec = str(p3.nr) + p3.title
                                tsec = re.sub(r"([0123456789]+?)\.([0123456789]+)(.*)", "<div class=\"xsymb\">\\1.\\2</div></a>&nbsp;", tsec, 1, re.S)
                                pages4 = p3.children
                                for a in range(len(pages4)):
                                       p4 = pages4[a]
                                       tsec += "<a class=\"MINTERLINK\" href=\"" + p4.fullname + "\"><div class=\"xsymb " + p4.tocsymb + "\"></div></a>\n"
                                       
                                c += "    <li><a class=\"MINTERLINK\" href=\"" + p3.fullname + "\">" + tsec + "</li>\n"
                        c += "    </ul></div>\n"
                c += "  </li>\n"
        c += "\n" \
          +  "</ul></div>" \
          +  "</li>" \
          +  "</ul></tocnavsymb>" \
          +  "<br /><br />"
  
        return c
    
    
    # adds prefix to links in html code
    def update_links(self, html, prefix):
        if prefix != "":
            # expand tex-Makro MMaterial to localmaterial macro inside HTML code
            html = html.replace("\\MMaterial", ":localmaterial:")
            # add prefix in front of filenames used by local links (but not in weblinks or escaped links)
            html = re.sub(r"(src|href)=(\"|')(?!#|https://|http://|ftp://|mailto:|:localmaterial:|:directmaterial:)", "\\1=\\2" + prefix, html, 0, re.S)
            html = re.sub(r"(\<param name=[\"\']movie[\"\'] value=[\"\'])(?!http|https|ftp)", "\\1" + prefix, html, 0, re.S)

            if re.search(r",(\"|\')(?!(\#|\'|\"|http://|https://|ftp://|mailto:|:localmaterial:|:directmaterial:))", html, re.S): 
                self.sys.message(self.sys.VERBOSEINFO, "Undesired combination marker and protocol prefix found in html code")

            # Lokale Dateien befinden sich im gleichen Ordner ohne Prefix
            html = html.replace(":localmaterial:", ".")
            html = html.replace(":directmaterial:", "")
        
        else:
            self.sys.message(self.sys.CLIENTWARN, "update_links called without a proper link prefix")
            
        return html

        
    def getnavi(self, tc):
        navi = ""

        p = tc.navleft()
        icon = "nprev"
        if (tc.level == self.options.contentlevel) and (p is None):
            if not tc.xleft is None:
                p = tc.xleft
            
        if (not p is None) and (tc.level == self.options.contentlevel):
            anchor = "<a class=\"MINTERLINK\" href=\"" + p.fullname +  "\"></a>"
        else:
            anchor = ""
            
        navi += "<div class=\"" + icon + "\">" + anchor + "</div>\n"
        
        # link to next page
        p = tc.navright()
        icon = "nnext"
        if ((tc.level == self.options.contentlevel) and (p is None)):
            if (not tc.xright is None):
                p = tc.xright

        if ((tc.level == (self.options.contentlevel - 2)) and (not tc.xright is None)):
            # click on "next" from module main page moves to first content page
            p = tc.xright
        if ((tc.level == (self.options.contentlevel - 3)) and (not tc.xright is None)):
            # click on "next" from chapter main page moves to first modul page
            p = tc.xright

        if ((not p is None) and ((tc.level == self.options.contentlevel) or (tc.level == (self.options.contentlevel - 2)) or (tc.level == (self.options.contentlevel - 3)))):
            anchor = "<a class=\"MINTERLINK\" href=\"" + p.fullname + "\"></a>"
        else:
            anchor = ""
        navi += "<div class=\"" + icon + "\">" + anchor + "</div>\n"

        # display links to subsubsections in the same tree
        navi += "<ul>\n"

        if (tc.level != self.options.contentlevel):
            # higher level: set links to module start
            pp = tc
            if (pp.level != self.options.contentlevel):
                sp = pp.children
                pp = sp[0]
            navi += "  <li class=\"xsectbutton\"><a class=\"MINTERLINK\" href=\"" + pp.fullname + "\">"
            if (not pp.helpsite):
                 navi + self.options.strings['module_starttext']
            else:
                 navi + self.options.strings['module_moreinfo']
            navi += "</a></li>\n"
        
        parent = tc.parent
        if not parent is None:
            pages = parent.children
            for i in range(len(pages)):
                p = pages[i]
                icon = "xsectbutton"
                cap = p.caption
                if (p.display and (tc.level == self.options.contentlevel)):
                    # normal display button
                    navi += "  <li class=\"" + icon + "\"><a class=\"MINTERLINK\" href=\"" + p.fullname + "\">" + cap + "</a></li>\n"
                else:
                    if (not p.display):
                        # blocked site, greyed button
                        navi += "  <li class=\"" + icon + "\">" + cap + "</li>\n"

        navi += "</ul>\n"

        return navi
    
    
    # correct specific problems arising from parsing HTML5 with an HTML parser
    def _correcthtml5(self, html):
        # parser gobbles doctype
        html = "<!DOCTYPE html>\n" + html
        # parser shortens void divs do <div .... /> which is invalid (resp. just a starting tag) in HTML5
        html = re.sub(r"\<div (.*?)/\>", "<div \\1></div>", html, 0, re.S)
        return html
    
    
    def postprocessing(self, html, tc):
        # orgpage = tc
      
        # read unique ids
        m = re.search(r"\<!-- mdeclaresiteuxidpost;;(.+?);; //--\>", html, re.S)
        if m:
            tc.uxid = m.group(1)
            self.sys.message(self.sys.VERBOSEINFO, tc.title + " -> " + tc.uxid + " (siteuxidpost)")
        else:
            tc.uxid = "UNKNOWNUXID"
            self.sys.message(self.sys.CLIENTWARN, "Site hat keine uxid: " + tc.title);
            
            
        # activate pull sites and adapt JS variables
        if "<!-- pullsite //-->" in html:
            html = html.replace("// <JSCRIPTPRELOADTAG>", "SITE_PULL = 1;\n" + "// <JSCRIPTPRELOADTAG>")
            self.sys.message(self.sys.CLIENTINFO, "User-Pull on Site: " + tc.title)
        else:
            html = html.replace("// <JSCRIPTPRELOADTAG>", "SITE_PULL = 0;\n" + "// <JSCRIPTPRELOADTAG>")
            
        # remove br tags which destabilize tabulars, is remains unknown why ttm places br there anyway,
        # we are detecting the combination <!--hbox--><br clear="all" /> followed by a table tag
        (html, n) = re.subn(r"\<!--hbox--\>\<br clear=\"all\" /\> *\<table", "<!--hbox--> <table", html, 0, re.S)
        if n > 0: self.sys.message(self.sys.VERBOSEINFO, "Postprocessing eliminated " + str(n) + " br tags in front of tables")
        
        # MStartJustify, MEndJustify  
        if "<!-- startalign;;" in html:
            self.sys.message(self.sys.CLIENTERROR, "Justify, JTabular, JustifiedImages are not supported yet")
            

        # find registered files and copy them to an appropriate position inside the HTML tree
        self.sys.message(self.sys.VERBOSEINFO, "Copying local files, outputfolder=" + tc.fullpath + ", outputfile=" + tc.fullname)
        
        nf = 0
      
        fileregs = re.findall(r"\<!-- registerfile;;(.+?);;(.+?);;(.+?); //--\>", html, re.S)
        for reg in fileregs:
            
            nf += 1
            fname = reg[0]
            includedir = reg[1]
            fileid = reg[2]
            fnameorg = fname
            self.sys.message(self.sys.VERBOSEINFO, "Processing includedir=" + includedir + ", fname=" + fname + ", id=" + fileid)
            
            # file extension given?
            dobase64 = 0
            fext = ""
            em = re.search(r"\.(.+)", fname, re.S)
            if em:
                fext = "." + em.group(1)
                fname = re.sub(re.escape(fext), "" , fname, 1)
                self.sys.message(self.sys.VERBOSEINFO, "File extension is " + fext)
                if (fext == ".png"):
                    dobase64 = 1
                else:
                    dobase64 = 0
                    self.sys.message(self.sys.VERBOSEINFO, "   not a png but " + fext)
                    if (fext == ".PNG"):
                        self.sys.message(self.sys.CLIENTERROR, "Found png file of extension PNG, please change them to lower case")
            else:
                # simulating DeclareGraphicsExtension{png,jpg,gif} from LaTeX
                self.sys.message(self.sys.VERBOSEINFO, "No file extension given, guessing graphics extensions")
                filerump = "tex/" + includedir + "/" + fname
                p = subprocess.Popen(["ls", "-l", filerump + ".*"], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
                (filelist, err) = p.communicate()
                if p.returncode == 0:
                    self.sys.message(self.sys.VERBOSEINFO, "  filelist=" + filelist)
                    filerump2 = re.escape(filerump)
                    fm = re.search(filerump2 + r"\.(png)", filelist, re.S)
                    if fm:
                        fext = "." + fm.group(1)
                        dobase64 = 1
                    else:
                        fm = re.search(filerump2 + r"\.(jpg)", filelist, re.S)
                        if fm:
                            fext = "." + fm.group(1)
                            self.sys.message(self.sys.VERBOSEINFO, "  ...found a jpg (png is preferred)")
                        else:
                            fm = re.search(filerump2 + r"\.(gif)", filelist, re.S)
                            if fm:
                                fext = "." + fm.group(1)
                                self.sys.message(self.sys.VERBOSEINFO, "  ...found a gif (not recommended)");
                            else:
                                self.sys.message(self.sys.CLIENTERROR, "Could not find suitable graphics extension for " + fname + ", rump is " + filerump + " rump2 is " + filerump2 + ", filelist is\n" + filelist + "\n")
                                fext = "*"
                                fnameorg2 = re.escape(fnameorg)
                                (html, n) = re.sub(r"\<!-- registerfile;;" + fnameorg2 + ";;" + includedir + ";;" + fileid + "; //--\>", "" , html ,0, re.S)
                                if (n != 1):
                                    self.sys.message(self.sys.CLIENTERROR, "Register tag with id " + fileid + " found " + str(n) + " times in html content without graphics extension")
                else:
                    self.sys.message(self.sys.FATALERROR, "Command ls does not seem to work, error code is " + str(p.returncode))
                
            dobase64 = 0 # should be enabled later
            if (fext != "*"):
                fname = fname + fext
                fm = re.search(r"(.*)/(.*?" + re.escape(fext) + ")", fname, re.S)
                if fm:
                    fnamepath = fm.group(1)
                    fnamename = fm.group(2)
                else:
                    self.sys.message(self.sys.CLIENTERROR, "Could not determine full path of fname element " + fname)
                    fnamepath = ""
                    fnamename = fname
                
                fnamepath = fnamepath + "."
                html = html.replace("<!-- mfileref;;" + fileid + " //-->" , fname)
                self.sys.message(self.sys.VERBOSEINFO, "fileid " + fileid + " expanded to " + fname + " in directory + " + tc.fullpath)

                # remove register tag from the code
                fnameorg2 = re.escape(fnameorg)
                (html, n) = re.subn(r"\<!-- registerfile;;" + fnameorg2 + ";;" + includedir + ";;" + fileid + "; //--\>", "" , html ,0, re.S)
                if (n != 1):
                    self.sys.message(self.sys.CLIENTERROR, "Register tag with id " + fileid + " found " + str(n) + " times in html content")
                
                # remove top directory level from fname because include directories inside sourceTEX are not being reproduced in HTML
                if (includedir != "."): fname = fname.replace(includedir, "")
                fi = "tex/" + includedir + "/" + fname
                if (dobase64 == 1):
                    self.sys.message(self.sys.CLIENTERROR, " dobase64 not supported yet")
                fi2 = tc.fullpath + "/" + fname
                self.sys.message(self.sys.VERBOSEINFO, "     Copying " + fi + " to " + fi2)
                dm = re.search(r"(.*)/[^/]*?$/", fi2, re.S)
                if dm:
                    os.mkpath(m.group(1))
                    p = subprocess.Popen(["cp", "-rf", fi, m.group(1) + "/."], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
                    (output, err) = p.communicate()
                    if p.returncode != 0:
                        self.sys.message(self.sys.FATALERROR, "cp refused to work on fi=" + fi + ", target=" + m.group(1) + "/.")
                    
        
            # end of regfile for

        if (nf > 0):
            self.sys.message(self.sys.VERBOSEINFO, str(nf) + " local files copied")
            
        
        """
  if ($config{parameter}{stdmathfont} == "1") {
    # MathML korrigieren: mtext, normalstyles und boldstyles um den Zeichensatz ergaenzen, damit es keine Serifen hat
    html =~ s/fontstyle=\"normal\"/fontfamily=\"Verdana, Arial, Helvetica , sans-serif\" fontstyle=\"normal\"/ig;
    html =~ s/fontweight=\"bold\"/fontfamily=\"Verdana, Arial, Helvetica , sans-serif\" fontstyle=\"normal\" fontweight=\"bold\"/ig;

    # Diese Zeilen verwenden fuer HTML, in dem die "m:"-Ersetzung in printpages vorgenommen wurde
    # html =~ s/<m:mtext>/<m:mtext fontfamily=\"Verdana, Arial, Helvetica , sans-serif\" fontstyle=\"normal\">/ig;
    # MathML korrigieren: mtext/mstyle-Schachtelung umkehren, sonst wird es von den meisten Browsern nicht akzeptiert
    # html =~ s/<m:mtext(.*)>(.*)<m:mstyle(.*)>(.+)<\/m:mstyle(.*)>\n*(.*)<\/m:mtext(.*)>/<m:mstyle$3><m:mtext$1>$4<\/m:mtext$7><\/m:mstyle$5>/gi;

    # Diese Zeile verwenden fuer HTML, in dem die "m:"-Ersetzung in printpages NICHT vorgenommen wurde
    html =~ s/<mtext>/<mtext fontfamily=\"Verdana, Arial, Helvetica , sans-serif\" fontstyle=\"normal\">/ig;
    html =~ s/<mtext(.*?)>(.*?)<mstyle(.*?)>(.+?)<\/mstyle(.*?)>\n*(.*?)<\/mtext(.*?)>/<mstyle$3><mtext$1>$4<\/mtext$7><\/mstyle$5>/gi;
  }

  # Falls es eine Pruefungsseite ist, Kennvariablen fuer die Aufgabenpunkte erzeugen
  if (tc.TESTSITE} eq 1) {
    html =~ s/\/\/ <JSCRIPTPRELOADTAG>/isTest = true;\nvar nMaxPoints = 0;\nvar nPoints = 0;\n\/\/ <JSCRIPTPRELOADTAG>/s ;
  }

  # Preload-Abschnitte in den Onload-Event verschieben
  while (html =~ m/<!-- onloadstart \/\/-->(.*?)<!-- onloadstop \/\/-->/s ) {
    html =~ s/<!-- onloadstart \/\/-->(.*?)<!-- onloadstop \/\/-->//s;
    my $prel = $1;
    html =~ s/\/\/ <JSCRIPTPRELOADTAG>/$prel\n\/\/ <JSCRIPTPRELOADTAG>/s ;
  }
  
  # Viewmodel-Eintraege in die Viewmodel-Deklaration verschieben
  while (html =~ m/<!-- viewmodelstart \/\/-->(.*?)<!-- viewmodelstop \/\/-->/s ) {
    html =~ s/<!-- viewmodelstart \/\/-->(.*?)<!-- viewmodelstop \/\/-->//s;
    my $prel = $1;
    html =~ s/\/\/ <JSCRIPTVIEWMODEL>/$prel\n\/\/ <JSCRIPTVIEWMODEL>/s ;
  }

  # postmodel-Eintraege hinter die Viewmodel-Deklaration verschieben
  while (html =~ m/<!-- postmodelstart \/\/-->(.*?)<!-- postmodelstop \/\/-->/s ) {
    html =~ s/<!-- postmodelstart \/\/-->(.*?)<!-- postmodelstop \/\/-->//s;
    my $prel = $1;
    html =~ s/\/\/ <JSCRIPTPOSTMODEL>/$prel\n\/\/ <JSCRIPTPOSTMODEL>/s ;
  }

  # SVGStyles einsetzen
  while (html =~ m/<!-- svgstyle;(.+?) \/\/-->/s ) {
    my $tname = $1;
    if (exists $tikzpng{$tname}) {
      my $style = $tikzpng{$tname};
      self.sys.message(self.sys.VERBOSEINFO, "Found style info for svg on $tname: $style");
      html =~ s/<!-- svgstyle;$tname \/\/-->/$style/g ; 
      delete $tikzpng{$tname};
    } else {
      self.sys.message(self.sys.CLIENTERROR, "Could not find image information for $tname");
      html =~ s/<!-- svgstyle;$tname \/\/-->//g ; 
    }
  }
 
  
  # mfeedbackbutton ersetzen
  my $j = 0;
  while (html =~ m/<!-- mfeedbackbutton;(.+?);(.*?);(.*?); \/\/-->/s ) {
    my $type = $1;
    my $testsite = $2;
    my $exid = $3;
    my $ibt = "\n<br />";

    my $bid = "FEEDBACK$j\_$exid";
    my $tip = "Feedback zu " . $type . " " . $exid . ":<br /><b>Meldung abschicken</b>";
    $ibt .= "<button type=\"button\" style=\"background-color: #E0C0C0; border: 2px\" ttip=\"1\" tiptitle=\"$tip\" name=\"Name_FEEDBACK$j\_$exid\" id=\"$bid\" type=\"button\" onclick=\"internal_feedback(\'$exid\',\'$bid\',\'$type $exid\');\">";
    $ibt .= "Meldung abschicken";
    $ibt .= "</button><br />\n";
    
    # Feedbackbuttons nur, (ehemals falls keine Testumgebung und) falls nicht global abgeschaltet
    if ($config{parameter}{do_feedback} eq "1") {
      html =~ s/<!-- mfeedbackbutton;$type;$testsite;$exid; \/\/-->/$ibt/s ;
    } else {
      html =~ s/<!-- mfeedbackbutton;$type;$testsite;$exid; \/\/-->//s ;
    }
  }

  # DirectHTML-Statements einsetzen
  while (html =~ m/<!-- directhtml;;(.*?); \/\/-->/s ) {
    my $pos = $1;
    my $rep = $DirectHTML[$pos];
    html =~ s/<!-- directhtml;;$pos; \/\/-->/$rep/s ;
  }
  
  # qexports erfassen
  # Beachte: qpos = Eindeutiger Exportindex pro tex-Datei (wird im PreParsing erstellt, unabhängig von section oder xcontent)
  # pos = Eindeutiger Exportindex pro page bzw. html-Datei (wird im Postprocessing erstellt), Dateiname des exports ist pagename plus pos plus extension
  while (html =~ m/<!-- qexportstart;(.*?); \/\/-->(.*?)<!-- qexportend;(.*?); \/\/-->/s ) {
    my $pos = 0;
    my $qpos = $1;
    my $expt = $2;
    if ($qpos == $3) {
      my $rep = "";
      if ($config{parameter}{do_export} eq "1") {
        my $exprefix = "\% Export Nr. $qpos aus " . tc.TITLE . "\n";
        $exprefix .= "\% Dieser Quellcode steht unter CCL BY-SA, entnommen aus dem VE\&MINT-Kurs " . $config{parameter}{signature_CID} . ",\n";
        $exprefix .= "\% Inhalte und Quellcode des Kurses dürfen gemäß den Bestimmungen der Creative Common Lincense frei weiterverwendet werden.\n";
        $exprefix .= "\% Für den Einsatz dieses Codes wird das Makropaket $macrofile benötigt.\n";
        $pos = 0 + @{tc.EXPORTS}};
        push @{tc.EXPORTS}}, ["export$pos.tex","$exprefix$expt",$qpos];
        $rep = "<br />";
        $rep .= "<button style=\"background-color: #FFFFFF; border: 0px\" ttip=\"1\" tiptitle=\"Quellcode dieser Aufgabe im LaTeX-Format\" name=\"Name_EXPORTT$pos\" id=\"EXPORTT$pos\" type=\"button\" onclick=\"export_button($pos,1);\">";
        $rep .= "<img alt=\"Exportbutton$pos\" style=\"width:36px\" src=\"" . $orgpage->linkpath() . "../images/exportlatex.png\">";
        $rep .= "</button>";
        $rep .= "<button style=\"background-color: #FFFFFF; border: 0px\" ttip=\"1\" tiptitle=\"Quellcode dieser Aufgabe im Word-Format\" name=\"Name_EXPORTD$pos\" id=\"EXPORTD$pos\" type=\"button\" onclick=\"export_button($pos,2);\">";
        $rep .= "<img alt=\"Exportbutton$pos\" style=\"width:36px\" src=\"" . $orgpage->linkpath() . "../images/exportdoc.png\">";
        $rep .= "</button><br />";
      }
      
      html =~ s/<!-- qexportstart;$qpos; \/\/-->(.*?)<!-- qexportend;$qpos; \/\/-->/$rep/s ;
    } else {
      self.sys.message(self.sys.CLIENTERROR, "Inkongruentes qexportpaar gefunden: $qpos (im Seitenarray an Position $pos$)");
    }
  }
 
  # exercisecollections erfassen
  if ($config{docollections} eq 1) {
    my $collc = 0; my $colla = 0;
    while (html =~ m/<!-- mexercisecollectionstart;;(.+?);;(.+?);; \/\/-->(.*?)<!-- mexercisecollectionstop \/\/-->/s ) {
      my $ecid1 = $1;
      my $ecopt = $2;
      my $ectext = $3;
      my $mark = generatecollectionmark($ecid1, $ecopt);
      html =~ s/<!-- mexercisecollectionstart;;$ecid1;;$ecopt;; \/\/-->(.*?)<!-- mexercisecollectionstop \/\/-->/$mark/s ;
      
      my $arraystring = "[";
      my $ast = 0;
      
      # Aus der collection die Aufgaben extrahieren
      while ($ectext =~ m/<!-- mexercisetextstart;;(.+?);; \/\/-->(.*?)<!-- mexercisetextstop \/\/-->/s ) {
        self.sys.message(self.sys.VERBOSEINFO, "    Aufgabe extrahiert");
        my $exid = $1;
        my $extext = $2;
        $ectext =~ s/<!-- mexercisetextstart;;$exid;; \/\/-->(.*?)<!-- mexercisetextstop \/\/-->//s ;
         
        if ($ast eq 1) { $arraystring .= ","; } else { $ast = 1; }
        my $ctext = encode_base64($extext);
        $ctext =~ s/\n/\\n/gs;

        my $l;
        
        $arraystring .= "{\"id\": \"$ecid1" . "_" . "$exid\", \"content\": \"$ctext\"}";
     
        $colla++;
      }
      
      $arraystring .= "]";
      
      $collc++;
      push @colexports, ["$ecid1", "$ecopt" , $arraystring];
    }
    if ($collc > 0) { self.sys.message(self.sys.VERBOSEINFO, "$collc collections mit insgesamt $colla Aufgaben exportiert"); }
  }

  
  # DirectRoulette-divs einrichten
  while (html =~ m/<!-- rouletteexc-start;(.+?);(.+?); \/\/-->(.+?)<!-- rouletteexc-stop;(.+?);(.+?); \/\/-->/s ) {
    my $rid = $1;
    my $id = $2;
    
    my $maxid = 0;
    
    if (exists $DirectRoulettes{$rid}) {
      $maxid = $DirectRoulettes{$rid};
    } else {
      self.sys.message(self.sys.CLIENTERROR, "Could not find roulette id $rid");
    }
    my $vis = ($id eq "0") ? "block" : "none";
    
    my $bt = "<div class=\"rouletteselector\"><button type=\"button\" class=\"roulettebutton\" onclick=\"rouletteClick(\'$rid\',$id,$maxid);\">Neue Aufgabe</button><br />";
    
    html =~ s/<!-- rouletteexc-start;$rid;$id; \/\/-->(.+?)<!-- rouletteexc-stop;$rid;$id; \/\/-->/<div style=\"display:$vis\" id=\"DROULETTE$rid\.$id\">$bt$1<\/div><\/div>/s ;
    self.sys.message(self.sys.VERBOSEINFO, "Roulette $rid.$id done");
  }
  
  return html;
}
        """
        return html
        