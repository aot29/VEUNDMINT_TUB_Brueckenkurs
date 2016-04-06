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
    This is html5 output plugin PageFactoy object
    Version P0.1.0, needs to be consistent with mintmod.tex and the preprocessor plugin
"""

import re
import os
from lxml import etree
from lxml import html
from copy import deepcopy
from plugins.exceptions import PluginException
from lxml.html import HTMLParser
from lxml.html import fragment_fromstring as frag_fromstring # must be this one: html5parser.HTMLParser does not accept JS
from lxml.html import fromstring as hp_fromstring
from lxml.html.html5parser import HTMLParser as HTML5Parser
from lxml import etree
import fnmatch

class PageFactory(object):

    def __init__(self, interface):
        self.sys = interface['system']
        self.data = interface['data']
        self.options = interface['options']
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
            
            
    def _substitute_string(self, html, idstr, insertion):
        # carefull: parser turns <div ....></div> into <div ... />
        (html, n) = re.subn(re.escape('<div id="' + idstr + '"') + r"(.*?)" + re.escape("/>"), '<div id="' + idstr + '"\\1>' + insertion + "</div>", html, 0, re.S)
        if n != 1:
            self.sys.message(self.sys.CLIENTERROR, "div replacement (id=\"" + idstr + "\") happened " + str(n) + " times")
        return html
            
            
    # generates a html page as a string using loaded templates and the given TContent object
    def generate_html(self, tc):
        if (tc.display == False):
            tc.html = "<html>NODISPLAY</html>"
            return

        template = etree.fromstring(self.template_html5)
        
        # do substitutions supported by lxml parsers and etree
        
        template.find(".//meta[@id='meta-charset']").attrib['content'] = "text/html; charset=" + self.options.outputencoding
        template.find(".//title").text = tc.title

        template.find(".//div[@id='itoccaption']").text = self.gettoccaption(tc)

        template.find(".//div[@id='footerright']").text = self.options.footer_right
        template.find(".//div[@id='footermiddle']").text = self.options.footer_middle

        # do pure string substitutions

        tc.html = etree.tostring(template, pretty_print = True, encoding = "unicode") # will always be unicode, output encoding for written files will be determined later

        cs_text = ""
        for cs in self.options.stylesheets:
            cs_text += "<link rel=\"stylesheet\" type=\"text/css\" href=\"" + tc.backpath + cs + "\"/>\n"
        js_text = ""     
        for js in self.options.scriptheaders:
            js_text += "<script src=\"" + tc.backpath + js + "\" type=\"text/javascript\"></script>\n"

        tc.html = self._substitute_string(tc.html, "mathjax-header", self.template_mathjax_settings + self.template_mathjax_include)
        tc.html = self._substitute_string(tc.html, "javascript-header", cs_text)
        tc.html = self._substitute_string(tc.html, "javascript-body-header", js_text + self.template_javascriptheader)
        tc.html = self._substitute_string(tc.html, "javascript-body-footer", self.template_javascriptfooter)
        tc.html = self._substitute_string(tc.html, "content", tc.content)
        
        
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

        c += "<div class=\"toccaption\"></div>\n"; # Neue Version ohne Logo

        c += "<tocnavsymb><ul>"
        c += "<li><a class=\"MINTERLINK\" href=\"" + tc.backpath + "../" + self.options.chaptersite + "\" target=\"_new\"><div class=\"tocmintitle\">" + self.options.strings['module_content'] + "</div></a>"
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
        c += "<li" + attr + "><a class=\"MINTERLINK\" href=\"" + tc.backpath + p1.link + ".{EXT}\">" + ti + "</a>\n" 

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
                c += "  <li><a class=\"MINTERLINK\" href=\"" + tc.backpath + p2.link + ".{EXT}\"><div class =\"tocminbutton\">" \
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
                                tsec = re.sub(r"([0123456789]+?)[\.]([0123456789]+)(.*)", "<div class=\"xsymb\">\\1.\\2</div>&nbsp;", tsec, 1, re.S)
                                pages4 = p3.children
                                for a in range(len(pages4)):
                                       p4 = pages4[a]
                                       tsec += "<a class=\"MINTERLINK\" href=\"" + tc.backpath + p4.link \
                                            +  ".{EXT}\"><div class=\"xsymb " + p4.tocsymb + "\"></div></a>\n"
                                       
                                c += "    <li><a class=\"MINTERLINK\" href=\"" + tc.backpath + p3.link + ".{EXT}\">" + tsec + "</a></li>\n"
                        c += "    </ul></div>\n"
                c += "  </li>\n"
        c += "\n" \
          +  "</ul></div>" \
          +  "</li>" \
          +  "</ul></tocnavsymb>" \
          +  "<br /><br />"
  
        return c
