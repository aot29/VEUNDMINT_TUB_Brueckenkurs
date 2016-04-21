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
from distutils.dir_util import mkpath
import subprocess
from lxml import etree
from lxml import html
from plugins.exceptions import PluginException
from lxml.html import HTMLParser
from lxml.html import fragment_fromstring as frag_fromstring # must be this one: html5parser.HTMLParser does not accept JS
from lxml.html import fromstring as hp_fromstring
from lxml.html.html5parser import HTMLParser as HTML5Parser
from lxml.html.html5parser import fromstring as h5_fromstring
from lxml import etree

class PageFactory(object):

    def __init__(self, interface, outputplugin):
        self.sys = interface['system']
        self.data = interface['data']
        self.options = interface['options']
        self.outputplugin = outputplugin
        self._load_templates()
        
        if hasattr(self.options, "tocadd"):
            self.tocadd = self.options.tocadd
        else:
            self.sys.message(self.sys.CLIENTWARN, "Options do not provide toc addition template, will be omitted")
            self.tocadd = ""

        
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
            
        self.template_settings = self.sys.readTextFile(self.options.template_settings, self.options.stdencoding)
            
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
        tc.html = self._append_string(tc.html, "javascript-header", cs_text)
        tc.html = self._substitute_string(tc.html, "javascript-body-header", js_text + self.template_javascriptheader)
        tc.html = self._substitute_string(tc.html, "javascript-body-footer", self.template_javascriptfooter)

        tc.html = self._append_string(tc.html, "toccaption", self.gettoccaption(tc))
        tc.html = self._substitute_string(tc.html, "navi", self.getnavi(tc))
        tc.html = self._substitute_string(tc.html, "footerright", self.options.footer_right)
        tc.html = self._substitute_string(tc.html, "footerleft", self.options.footer_left)
        tc.html = self._substitute_string(tc.html, "footermiddle", self.options.footer_middle)
        tc.html = self._substitute_string(tc.html, "content", tc.content)
        tc.html = self._substitute_string(tc.html, "settings", self.template_settings)

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
        fsubi = tc.chapter
        
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

        # display chapters only if required by options
        if self.options.tocchapters == 1:
            self.sys.message(self.sys.VERBOSEINFO, "Adding chapter link to toc")
            ti = re.sub(r"([12345] )(.*)", "\\2", p1.title, 1, re.S)
            c += "<li" + attr + "><a class=\"MINTERLINK\" href=\"" + p1.fullname  + "\">" + ti + "</a>\n" 
        else:
            self.sys.message(self.sys.VERBOSEINFO, "Omitting chapter link in toc")
    
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
                                tsec = re.sub(r"([0123456789]+?)\.([0123456789]+)(.*)", "<div class=\"xsymb selected\">\\1.\\2</div></a>&nbsp;", tsec, 1, re.S)
                                pages4 = p3.children
                                for a in range(len(pages4)):
                                       p4 = pages4[a]
                                       if p4 is tc:
                                           cl = " selected"
                                       else:
                                           cl = ""
                                       divid = "idxsymb_tc" + str(p4.myid)
                                       tsec += "<a class=\"MINTERLINK\" href=\"" + p4.fullname + "\"><div uxid=\"" + p4.uxid + "\" id=\"" + divid + "\" class=\"xsymb " + p4.tocsymb + cl + "\"></div></a>\n"
                                       
                                c += "    <li><a class=\"MINTERLINK\" href=\"" + pages4[0].fullname + "\">" + tsec + "</li>\n"
                        c += "    </ul></div>\n"
                c += "  </li>\n"
        c += "\n" \
          +  "</ul></div>" \
          +  "</li>" \
          +  "</ul>" \
          +  self.tocadd \
          + "</tocnavsymb>" \
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

        # link to previous page
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
            while (pp.level != self.options.contentlevel):
                pp = pp.children[0]
            # higher level link: is always alone and therefore selected
            navi += "  <li class=\"xsectbutton\"><a class=\"MINTERLINK naviselected\" href=\"" + pp.fullname + "\">"
            if pp.helpsite:
                 navi += self.options.strings['module_moreinfo']
            else:
                 navi += self.options.strings['module_starttext'] + tc.title
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
                    if p is tc:
                        sl = " naviselected"
                    else:
                        sl = ""
                    navi += "  <li class=\"" + icon + "\"><a uxid=\"" + p.uxid + "\" class=\"MINTERLINK" + sl + "\" href=\"" + p.fullname + "\">" + cap + "</a></li>\n"
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
            if tc.uxid != m.group(1):
                self.sys.message(self.sys.CLIENTERROR, "Element tc.title has uxid " + tc.uxid + ", but postdeclare is " + m.group(1))
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
        
        # solve problem with MathML: <mi>AB</mi> is not displayed as italic, but substitute only if contained in a single mrow to keep \sin, \cos, etc. non-italic
        def mireplace(m):
            if m.group(1) in self.options.knownmathcommands:
                return m.group(0) # don't change anything
            else:
                # replace string by single mi elements
                k = 0
                s = ""
                while k < len(m.group(1)):
                    s += "<mi>" + m.group(1)[k] + "</mi>"
                    k = k + 1
                self.sys.message(self.sys.VERBOSEINFO, "ttm <mi>-correction: " + m.group(0) + "  ->  " + s)
                return s
            
        html = re.sub(r"\<mi\>([^\W\d_]{2,})\</mi\>", mireplace, html, 0, re.S)
        
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
            em = re.match(r".*\.([^\.]*)", fname, re.S)
            if em:
                if em.group(1) == "":
                    self.sys.message(self.sys.CLIENTWARN, "File " + fname + " has empty extension")
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
                    # not an error, as path of file may be empty
                    fnamepath = ""
                    fnamename = fname
                
                fnamepath = fnamepath + "."
                (html, n) = re.subn(r"\[\[!-- mfileref;;" + re.escape(fileid) + "; //--\]\]" , fname, html , 0, re.S)
                if n > 0:
                    self.sys.message(self.sys.VERBOSEINFO, "fileid " + fileid + " expanded to " + fname + " in directory " + tc.fullpath)
                else:
                    self.sys.message(self.sys.CLIENTWARN, "fileid " + fileid + " was not expanded to " + fname + " in directory " + tc.fullpath + " because it is not used")

                # remove register tag from the code
                fnameorg2 = re.escape(fnameorg)
                (html, n) = re.subn(r"\<!-- registerfile;;" + fnameorg2 + ";;" + includedir + ";;" + fileid + "; //--\>", "" , html ,0, re.S)
                if (n != 1):
                    self.sys.message(self.sys.CLIENTERROR, "Register tag with id " + fileid + " found " + str(n) + " times in html content")
                
                # remove top directory level from fname because include directories inside sourceTEX are not being reproduced in HTML
                if (includedir != "."):
                    # carefull: only 1 replacement allowed because pathname is prefix of mtikzauto-filenames
                    fname = re.sub(re.escape(includedir) + r"/", "", fname, 1)
                fi = "tex/" + includedir + "/" + fname
                if (dobase64 == 1):
                    self.sys.message(self.sys.CLIENTERROR, "dobase64 not supported yet")
                fi2 = tc.fullpath + "/" + fname
                self.sys.message(self.sys.VERBOSEINFO, "Copying " + fi + " to " + fi2)
                dm = re.match(r"(.*)/[^/]*?", fi2, re.S)
                if dm:
                    targetp = os.path.join(self.options.targetpath, dm.group(1))
                    sourcep= os.path.join(self.options.sourcepath, fi)
                    mkpath(targetp)
                    # use cp -r because registered file might be a directory
                    targetp = targetp + "/"
                    p = subprocess.Popen(["cp", "-rf", sourcep, targetp], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
                    (output, err) = p.communicate()
                    if p.returncode != 0:
                        self.sys.message(self.sys.FATALERROR, "cp refused to work on source=" + sourcep + ", target=" + targetp)
                else:
                    self.sys.message(self.sys.CLIENTERROR, "Could not extract file details for fi2=" + fi2)
                    
        
            # end of regfile for

        if (nf > 0):
            self.sys.message(self.sys.VERBOSEINFO, str(nf) + " local files copied")
            
        
        if self.options.stdmathfont == "1":
            # add font to mtext, normalstyles and boldstyles (without serif)
            html = html.replace("fontstyle=\"normal\"", "fontfamily=\'" + self.options.fonts['STDMATHFONTFAMILY'] + "\' fontstyle=\"normal\"")
            html = html.replace("fontweight=\"bold\"", "fontfamily=\'" + self.options.fonts['STDMATHFONTFAMILY'] + "\' fontstyle=\"normal\" fontweight=\"bold\"")
            html = html.replace("<mtext>", "<mtext fontfamily=\'" + self.options.fonts['STDMATHFONTFAMILY'] + "\' fontstyle=\"normal\">")
            html = re.sub(r"\<mtext(.*?)\>(.*?)\<mstyle(.*?)\>(.+?)\</mstyle(.*?)\>\n*(.*?)\</mtext(.*?)\>", "<mstyle\\3><mtext\\1>\\4</mtext\\7></mstyle\\5>", html, 0, re.S)
            
        # generate variables used by testsites if needed
        if tc.testsite:
            html = html.replace("// <JSCRIPTPRELOADTAG>", "isTest = true;\nvar nMaxPoints = 0;\nvar nPoints = 0;\n// <JSCRIPTPRELOADTAG>")
            
        # move JS blocks from tcontents into appropriate head/body segments
        jsblocks = ""
        def loadmove(m):
            nonlocal jsblocks
            jsblocks += m.group(1) + "\n"
            return ""

        for tag in [("onload", "// <JSCRIPTPRELOADTAG>"),
                    ("viewmodel", "// <JSCRIPTVIEWMODEL>"),
                    ("postmodel", "// <JSCRIPTPOSTMODEL>")]:
            jsblocks = "// " + tag[0] + " blocks start\n"
            html = re.sub(r"\<!-- " + re.escape(tag[0]) + "start //--\>(.*?)\<!-- " + re.escape(tag[0]) + "stop //--\>", loadmove, html, 0, re.S)
            jsblocks += "// " + tag[0] + " blocks stop\n"
            html = html.replace(tag[1], jsblocks + tag[1])

        # process SVGStyles
        def svgstyle(m):
            tname = m.group(1)
            if tname in self.data['htmltikz']:
                style = self.data['htmltikz'][tname]
                self.sys.message(self.sys.VERBOSEINFO, "Found style info for svg on " + tname + ": " + style)
                del self.data['htmltikz'][tname]
                return style
            else:
                self.sys.message(self.sys.CLIENTERROR, "Could not find image information for " + tname)
                return ""
        
        html= re.sub(r"\[\[!-- svgstyle;(.+?) //--\]\]", svgstyle, html, 0, re.S)
        

        # prepare feedback buttons
        j = 0 # is always zero up to now
        def bfeed(m):
            nonlocal j
            ftype = m.group(1)
            testsite = m.group(2)
            exid = m.group(3)
            ibt = "\n<br />"
            bid = "FEEDBACK" + str(j) + "_" + exid
            tip = "Feedback zu " + ftype + " " + exid + ":<br /><b>" + self.options.strings['feedback_sendit'] + "</b>"
            ibt += "<button type=\"button\" style=\"background-color: #E0C0C0; border: 2px\" ttip=\"1\" tiptitle=\"" + tip + "\" name=\"Name_FEEDBACK" + str(j) + "_" + exid + "\" id=\"" + bid + "\" type=\"button\" onclick=\"internal_feedback(\'" + exid + "\',\'" + bid + "\',\'" + ftype + " " + exid + "\');\">"
            ibt += self.options.strings['feedback_sendit']
            ibt += "</button><br />\n"
            
            # display feedback buttons if (not a test version) and not globally deactivated
            if self.options.do_feedback == "1":
                return ibt
            else:
                return ""
        html = re.sub(r"\<!-- mfeedbackbutton;(.+?);(.*?);(.*?); //--\>", bfeed, html, 0, re.S)
  
        def dhtml(m):
            pos = int(m.group(1))
            self.sys.message(self.sys.VERBOSEINFO, "DirectHTML " + m.group(1) + " set")
            return self.data['DirectHTML'][pos]
        html = re.sub(r"\<!-- directhtml;;(.+?); //--\>", dhtml, html, 0, re.S)

        if "<!-- qexportstart" in html:
            self.sys.message(self.sys.CLIENTERROR, "qexports not implemented yet")
            
        
        # process qexports:
        # qpos = unique export index per tex file (index generated by preparsing, not affectd by section or xcontent numbers)
        # pos = unique export index per page (html file) generated by postprocessing, filename of exports is pagename plus pos plus extension

        def qexp(m):
            pos = 0
            qpos = int(m.group(1))
            expt = m.group(2)
            rep = ""
            if self.options.do_export == "1":
                exprefix = "\% Export nr. " + str(qpos) + " from " + tc.title + "\n" \
                         + "\% License: CCL BY-SA, taken from the VE&MINT math online course " + self.data['signature_CID'] + ",\n" \
                         + "Usage of this code requires the macro package " + self.options.macrofile + " from the VEUNDMINT converter package"
                pos = len(tc.exports)
                tc.exports.append(["export" + str(pos) + ".tex", exprefix + expt, qpos])
                rep = "<br />"
                rep += "<button style=\"background-color: #FFFFFF; border: 0px\" ttip=\"1\" tiptitle=\"" + self.options.strings['qexport_download_tex'] + "\""
                rep += " name=\"Name_EXPORTT" + str(pos) + "\" id=\"EXPORTT" + str(pos) + "\" type=\"button\" onclick=\"export_button(" + str(pos) + ",1);\">"
                rep += "<img alt=\"Exportbutton" + str(pos) + "\" style=\"width:36px\" src=\"" + tc.backpath + "../images/exportlatex.png\"></button>"
                rep += "<button style=\"background-color: #FFFFFF; border: 0px\" ttip=\"1\" tiptitle=\"" + self.options.strings['qexport_download_doc'] + "\""
                rep += " name=\"Name_EXPORTD" + str(pos) + "\" id=\"EXPORTD" + str(pos) + "\" type=\"button\" onclick=\"export_button(" + str(pos) + ",2);\">"
                rep += "<img alt=\"Exportbutton" + str(pos) + "\" style=\"width:36px\" src=\"" + tc.backpath + "../images/exportdoc.png\"></button>"
                rep += "<br />"
                return rep
            else:
                # exports disabled: remove export tag entirely
                return ""
        
        html = re.sub(r"\<!-- qexportstart;(.*?); //--\>(.*?)\<!-- qexportend;\1; //--\>", qexp, html, 0, re.S)
        
        
        # process exercise collections
        if self.options.docollections == 1:
            self.sys.message(self.sys.CLIENTERROR, "Collection export not implemented yet")
            collc = 0
            colla = 0
            
        """
            
            
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

        """


        
        # prepare DirectRoulette divs
        def droul(m):
            rid = m.group(1)
            myid = int(m.group(2))
            maxid = 0
            if rid in self.data['DirectRoulettes']:
                maxid = self.data['DirectRoulettes'][rid]
            else:
                self.sys.message(self.sys.CLIENTERROR, "Could not find roulette id " + rid)
            if myid == "0":
                vis = "block"
            else:
                vis = "none"
            bt = "<div class=\"rouletteselector\"><button type=\"button\" class=\"roulettebutton\" onclick=\"rouletteClick(\'" + rid + "\'," + str(myid) + "," + str(maxid) + ");\">Neue Aufgabe</button><br />"
            self.sys.message(self.sys.VERBOSEINFO, "Roulette " + rid + "." + str(myid) + " done")
            return "<div style=\"display:" + vis + "\" id=\"DROULETTE" + rid + "." + str(myid) + "\">" + bt + m.group(3) + "</div></div>"
  
        html = re.sub(r"\<!-- rouletteexc-start;(.+?);(.+?); //--\>(.+?)\<!-- rouletteexc-stop;\1;\2; //--\>", droul, html, 0, re.S)
  
        return html
    
    # end postprocessing
