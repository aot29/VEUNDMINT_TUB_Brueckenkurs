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
import json
import subprocess
import locale
from lxml import etree
from lxml import html
from tidylib import tidy_document
from copy import deepcopy
from random import randint

from tex2x.AbstractPlugin import *

from plugins.VEUNDMINT_TUB.tcontent import TContent
from plugins.VEUNDMINT_TUB.renderers.PageFactory import PageFactory

from tex2x.Settings import settings
from tex2x.System import ve_system as sys

class Plugin(AbstractPlugin):

	def __init__(self, data):
		# initialize data which is global for each conversion
		# copy interface member references
		self.data = data
		self.name = "HTML5_MINTMODTEX"
		self.version ="P0.1.0"
		self.outputextension = "html"
		self.outputsubdir = self.outputextension
		self.page = PageFactory( data, self ).getPage()
		self.randcharstr = "0123456789,.;abcxysqrt()/*+-"
		sys.message(sys.VERBOSEINFO, "Output plugin " + self.name + " of version " + self.version + " constructed")

	def _prepareData(self):
		# initialize data which should be cleaned for each conversion
		self.startfile = "" # will be written once starttag is found
		self.entryfile = ""

		# checks if needed data members are present or empty
		if 'content' in self.data:
			self.content = self.data['content']
		else:
			sys.message(sys.CLIENTERROR, "tex2x did not provide content in data structure")
			self.content = ""

		if 'tocxml' in self.data:
			self.tocxml = self.data['tocxml']
		else:
			sys.message(sys.CLIENTERROR, "tex2x did not provide tocxml in data structure")
			self.tocxml = ""

		if 'rawxml' in self.data:
			self.rawxml = self.data['rawxml']
		else:
			sys.message(sys.CLIENTERROR, "tex2x did not provide rawxml in data structure")
			self.rawxml = ""

		for dat in ['DirectRoulettes', 'macrotex', 'modmacrotex', 'DirectHTML', 'directexercises', 'autolabels', 'copyrightcollection', 'htmltikz']:
			if not dat in self.data:
				sys.message(sys.CLIENTERROR, "Preprocessors did not provide " + dat)

		self.ctree = TContent()
		if 'coursetree' in self.data:
			sys.message(sys.CLIENTWARN, "Another plugin created a content tree, it will be overwritten now")
			self.data['coursetree'] = self.ctree
		else:
			self.data['coursetree'] = self.ctree

		for dat in ['sitepoints', 'expoints', 'testpoints', 'sections']:
			if dat in self.data:
				sys.message(sys.CLIENTWARN, "Data element " + dat + " was created by another plugin, appending data to it and hoping it works out")
			else:
				self.data[dat] = dict()

		for dat in ['uxids', 'siteuxids', 'wordindexlist', 'labels', 'slabels']:
			if dat in self.data:
				sys.message(sys.CLIENTWARN, dat + " list exists from another plugin, appending data to it and hoping it works out")
			else:
				self.data[dat] = []

		if (settings.feedback_service != ""):
			sys.message(sys.CLIENTINFO, "Feedback server declared: " + settings.feedback_service)
		else:
			sys.message(sys.CLIENTERROR, "No feedback server declared in options, feedback send will not be possible")

		if (settings.data_server != ""):
			sys.message(sys.CLIENTINFO, "Data server declared: " + settings.data_server + " (" + settings.data_server_description + ")")
		else:
			sys.message(sys.CLIENTERROR, "No data server declared in options")

		if (settings.exercise_server != ""):
			sys.message(sys.CLIENTINFO, "Exercise server declared: " + settings.exercise_server)
		else:
			sys.message(sys.CLIENTERROR, "No exercise server declared in options")


		print(settings.template_redirect_basic)
		self.template_redirect_basic = sys.readTextFile(settings.template_redirect_basic, settings.stdencoding)
		
		#self.template_redirect_multi = sys.readTextFile(settings.template_redirect_multi, settings.stdencoding)
		#self.template_redirect_scorm = sys.readTextFile(settings.template_redirect_scorm, settings.stdencoding)

		self.siteredirects = dict() # consists of pairs [ redirectfilename, redirectarget ]
		for t in settings.sitetaglist:
			sys.message(sys.VERBOSEINFO, "Adding %s to site redirects" % t)
			self.siteredirects[t] = [ t + "." + self.outputextension, "" ]


	def create_output(self):
		sys.timestamp("create_output start")
		self._prepareData()

		self.generate_directory()
		#self.generate_css()

		self.xidobj = None # used by global xcontent linking
		self.analyze_html() # analysis done on raw text
		self.setup_contenttree()
		self.analyze_nodes_stage1(self.ctree) # analysis done inside nodes
		self.prepare_index()
		self.analyze_nodes_stage2(self.ctree) # analyse parts using information from stage1 and the index

		for i in self.data['sections']:
			if i in self.data['expoints'] and i in self.data['sitepoints'] and i in self.data['testpoints']:
				sys.message(sys.VERBOSEINFO, "Points in section " + i + " (" + self.data['sections'][i] + "): " + str(self.data['expoints'][i]) + ", of which " + str(self.data['testpoints'][i]) + " are in tests")
				sys.message(sys.VERBOSEINFO, "Sites in section " + i + ": " +  str(self.data['sitepoints'][i]))
			else:
				sys.message(sys.CLIENTERROR, "Section index " + i + " not found in test data, final test subsection is missing")

		self.generate_html(self.ctree)
		self.generate_pdf()

		self.filecount = 0
		self.write_htmlfiles(self.ctree)
		self.write_miscfiles()

		self.finishing()



		sys.message(sys.CLIENTINFO, str(self.filecount) + " files written to directory " + self.outputsubdir)


	def setup_contenttree(self):

		# we need a real object tree instead of a XML tree which can have only text fields as attribute values and no code
		# copy tree structure from tocxml up to level 3, fill in level 4 and detailed infos from content

		sys.timestamp("setup_contenttree start")

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
			q.fullpath = self.outputsubdir
			nid += 1
			q.xmlelement = node # link object tree to xml tree
			node.attrib['objid'] = str(q.myid)
			q.level = lev
			if hasattr(node, "name"): q.nr = node.name
			q.title = node.text

			# create titles and captions for level 1..3, level 4 nodes appear later
			if lev == 1:
				# remove chapter prefix from ttm and add a space for level 1, extract text title into caption
				q.caption = re.sub(r"Chapter (.)(.+)", r"\2", q.title, 1, re.S)
				q.title = re.sub(r"Chapter (.)(.+)", r"\1 \2", q.title, 1, re.S)
			if lev == 2:
				# remove the two utf8 characters where a space should be for level 2, what the hell is ttm doing there?
				q.caption = re.sub(r"(\d+\.\d+)..(.*)", r"\2", q.title, 1, re.S)
				q.title = re.sub(r"(\d+\.\d+)..(.*)", r"\1 \2", q.title, 1, re.S)
			if lev == 3:
				# add a space, don't know why it works
				q.caption = q.title
				q.title = " " + q.title

			q.parent = parent
			parent.children.append(q)

			if lev == 1:
				q.link = str(pos)
				q.chapter = pos
			else:
				q.link = q.parent.link + "." + str(pos)
				q.chapter = q.parent.chapter

			q.fullname = self.outputsubdir + "/" + q.link

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
			if (len(tupel) >= 3): annotationelement = tupel[2]
			text = etree.tostring(contentelement, pretty_print = True, encoding = "unicode")


			if re.search(r"<!-- scontent;-", text, re.S):
				sys.message(sys.CLIENTERROR, "scontent environments no longer supported, consider turning them into xcontents")

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
				sys.message(sys.CLIENTERROR, "content element without sectioninfo found, cannot be processed")
				break

			if (ssec == 0):
				# level 2 content coming from an MSectionStart environment, will be attached to existing level 2 object
				p = root.elementByID(int(tocelement.attrib['objid']))
				if p is None:
					sys.message(sys.CLIENTERROR, "Could not locate level 2 object of id = " + tocelement.attrib['objid'])
				if (p.level != 2):
					sys.message(sys.CLIENTERROR, "Object of id = " + tocelement.attrib['objid'] + " is level " + str(p.level) + " instead of 2")
				p.ismodul = True
				p.display = True
				p.content = text
				# first label appearing in content becomes contentlabel
				lms = re.search(r"<!-- mmlabel;;(.+?);;(.+?);;(.+?);;(.+?);;(.+?);;(.+?);;(.+?); //-->", text, re.S)
				if lms:
					p.contentlabel = lms.group(1)
					sys.message(sys.VERBOSEINFO, "tc receives contenttitle " + lms.group(1))
				p.docname = "sectionx" + str(p.chapter) + "." + str(sec) + "." + str(ssec)
				p.section = sec
				p.link = p.docname
				p.fullname = self.outputsubdir + "/" + p.link + "." + self.outputextension
				lastcontent = None
				pos = 1

				# grab sectionlabels stored from processing of raw xml
				for l in self.data['slabels']:
					if (l[6] == "1") and (int(l[2]) == p.chapter) and (int(l[3]) == p.section):
						# prepend mmlabel tag and html anchor (which was created by ttm outside the xcontent block)
						p.content = "<a id=\"" + l[0] + "\"></a><!-- mmlabel;;" + l[0] + ";;" + l[1] + ";;" + l[2] + ";;" + l[3] + ";;" + l[4] + ";;" + l[5] + ";;" + l[6] + "; //-->" + p.content

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
					p.chapter = p.parent.chapter
					p.title = m.group(2)
					p.ismodul = True
					if m.group(3) != "":
						p.caption = m.group(3)
					else:
						p.caption = p.title
					sys.message(sys.VERBOSEINFO, "Created tcontent, title=" + p.title + ", caption=" + p.caption)
					if i != int(m.group(6)):
						sys.message(sys.CLIENTERROR, "start end end of xcontent " + i + " do not match")

					p.content = m.group(5)
					p.annotations = annotationelement

					# first label appearing in content becomes contentlabel
					lms = re.search(r"<!-- mmlabel;;(.+?);;(.+?);;(.+?);;(.+?);;(.+?);;(.+?);;(.+?); //-->", text, re.S)
					if lms:
						p.contentlabel = lms.group(1)
						sys.message(sys.VERBOSEINFO, "tc receives contenttitle " + lms.group(1))
					else:
						p.contentlabel = "_UNSETNODELABEL" + str(p.myid)
						sys.message(sys.VERBOSEINFO, "Element " + p.title + " has no contentlabel, not a problem, will be substituted later")
					p.icon = m.group(4) # will no longer be used
					p.display = True
					p.section = sec
					p.subsection = ssec

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
					p.fullname = self.outputsubdir + "/" + p.link + "." + self.outputextension
					m = re.search(r"(.*)/(.*?)\." + self.outputextension, p.fullname, re.S)
					if m:
						p.fullpath = m.group(1)
					else:
						sys.message(sys.CLIENTERROR, "Could not determine full path of tc element " + tc.title)
					p.backpath = p.parent.backpath + "../" # level 4 xcontents are located in html/X.Y.Z/.
					p.menuitem = 0
					p.nr = ""
					p.level = p.parent.level + 1
					if p.level != settings.contentlevel:
						sys.message(sys.CLIENTWARN, "xcontent did not get level " + str(settings.contentlevel) + " as required by options")

					p.tocsymb = "status1"
					if re.search(r"<!-- declaretestsymb //-->", p.content, re.S):
						p.tocsymb = "status3"
					if re.search(r"<!-- declareexcsymb //-->", p.content, re.S):
						p.tocsymb = "status2"

					# create course wide xcontent links
					p.xleft = self.xidobj
					if not self.xidobj is None:
						self.xidobj.xright = p
					p.xright = None
					self.xidobj = p

					if testpage != 0: p.testsite = True
					p.nr = sid
					if i == 0:
						p.parent.nr = str(sec) + "." + str(ssec)
						p.parent.parent.nr = str(sec)

					sys.message(sys.VERBOSEINFO, "xcontent " + p.title + " has number " + p.nr)
					# expand <title>
					p.title = settings.moduleprefix + " Abschnitt " + sid + " " + p.title
					# care for ttm problem: subsubsection titles appear without number prefix


					secprefix = ""
					q = p.parent
					while (not q is None):
						if (q.level > 1) and (q.title != ""):
							ti = q.title
							if q.level == 2:
								# ti is of type CHAPTER.SECTION TITLE
								ti = re.sub(r"(\d*)\.(\d*) (.*)", r"\2 \3", ti, 0, re.S)
								ti = settings.strings['chapter'] + " " + ti
							if q.level == 3:
								# ti contains title only, without number
								ti = settings.strings['subsection'] + " " + str(q.nr) + " " + ti
							if (secprefix != ""):
								secprefix = ti + "  - " + secprefix
							else:
								secprefix = ti
						q = q.parent

					pref = ""
					if printnr == 1: pref = sid + " "
					(p.content, n) = re.subn(r"<h4>(.*?)</h4><!-- sectioninfo;;" + str(sec) + ";;" + str(ssec) + ";;" + str(sssec) + ";;" + str(printnr) + ";;" + str(testpage) + r"; //-->", "<h4>" + secprefix + "</h4><h4>" + pref + r"\1</h4>", p.content, 0, re.S)
					if (n != 1):
						sys.message(sys.CLIENTERROR, "Could not substitute sectioninfo in xcontent " + p.title + ", n = " + str(n))


					# add numbers to MSubsubsections in MXContent
					p.content = re.sub(r"<h4>(.+?)</h4><!-- sectioninfo;;(\w+?);;(\w+?);;(\w+?);;1;;([01]); //-->" ,r"<h4>\2.\3.\4 \1</h4>", p.content, 0, re.S)

					if p.pos == 1:
						# it's a modstart, grab subsectionlabels stored from processing of raw xml
						for l in self.data['slabels']:
							if (l[6] == "2") and (int(l[2]) == p.chapter) and (int(l[3]) == p.section) and (int(l[4]) == p.subsection):
								# prepend mmlabel tag and html anchor (which was created by ttm outside the xcontent block)
								p.content = "<a id=\"" + l[0] + "\"></a><!-- mmlabel;;" + l[0] + ";;" + l[1] + ";;" + l[2] + ";;" + l[3] + ";;" + l[4] + ";;" + l[5] + ";;" + l[6] + "; //-->" + p.content
								p.contentlabel = l[0] # subsection label will be new contentlabel, no matter what

					p.right = None
					pos = pos + 1

					lastcontent = p

				else:
					sys.message(sys.CLIENTERROR, "xcontent element of level 4 contains no xcontent information tags, cannot parse it")

		sys.message(sys.VERBOSEINFO, "Tree buildup: \n" + str(root))
		sys.timestamp("setup_contenttree finished successfully")


	# scan raw html for course scope relevant information tags, note that rawxml is not used in further computations
	def analyze_html(self):
		sys.timestamp("analyze_html start")

		# output user debug messages
		def cmessage(m):
			sys.message(sys.DEBUGINFO, m.group(1))
			return "<!-- debug;;" + m.group(1) + "; //-->"
		self.rawxml = re.sub(r"\<!-- debugprint;;(.+?); //--\>", cmessage, self.rawxml, 0, re.S)

		# write section names to dict indexed by section numbers minus one (like an array but with strings)
		def dsect(m):
			if m.group(1) == "1": #  = chapter = lev1 node position, >1 => not part of course modules
				i = str(int(m.group(2)) - 1)
				self.data['sections'][i] = m.group(3)
				sys.message(sys.VERBOSEINFO, "Created section element " + i + ": " + m.group(3))
			return "" # remove the tag
		self.rawxml = re.sub(r"\<!-- mdeclaresection;;(.+?);;(.+?);;(.+?);; //--\>", dsect, self.rawxml, 0, re.S)

		m = re.search(r"\<!-- mlocation;;(.+?);;(.+?);;(.+?);; //--\>", self.rawxml, re.S)
		if m:
			self.data['locationicon'] = m.group(1)
			self.data['locationlong'] = m.group(2)
			self.data['locationshort'] = m.group(3)
			self.data['locationsite'] = "location.html"
			sys.message(sys.CLIENTINFO, "Using location declaration: " + self.data['locationlong']);
		else:
			sys.message(sys.CLIENTINFO, "Location declaration not found, no location button will be generated")

		# scan raw text for section and subsection labels which will not appear in a xcontent (and therefore not in contentxml)
		# definition from macropackage: <!-- mmlabel;;Labelbezeichner;;SubjectArea;;chapter;;section;;subsection;;Index;;Objekttyp; //-->
		# index == -1 -> section or subsection not attached to xcontent, section: type=1, subsection: type=2
		def slabel(m):
			self.data['slabels'].append((m.group(1), m.group(2), m.group(3), m.group(4), m.group(5), m.group(6), m.group(7)))
			sys.message(sys.VERBOSEINFO, "Label type " + m.group(7) + " stored: " + m.group(1))
		re.sub(r"\<!-- mmlabel;;([^;]+);;([^;]+);;([^;]+);;([^;]+);;([^;]+);;([^;]+);;([12]); //--\>", slabel, self.rawxml, 0, re.S)

		sys.timestamp("analyze_html finished successfully")


	# scan tree content elements for course scope relevant information tags
	def analyze_nodes_stage1(self, tc):
		sys.message(sys.VERBOSEINFO, "analyze_nodes_stage1 start on " + tc.title)

		# initialize modstart boxes
		def modsb(m):
			sys.message(sys.VERBOSEINFO, "Setting up modstart box (" + tc.title + ", " + str(tc.level) + ", " + str(tc.nr) + ")")
			if len(tc.children) == 0:
				sys.message(sys.CLIENTWARN, "A modstart box appears in a content node without children, so it will be empty")
				return "" # don't generate the box
			s = "<div class=\"modstartbox\">\n"
			s += settings.strings['modstartbox_tocline'] + "<br /><br />"
			# iterate children (MSubsection nodes if tc.level==2) to get local toc
			s += "<ul>\n"
			for k in range(len(tc.children)):
				p = tc.children[k]
				# descend into the tree until a label is found
				t = p.caption # caption is taken from the node, contentlabel from the node or the first fitting child
				while ((p.contentlabel == "") and (len(p.children) > 0)):
					p = p.children[0]

				if p.contentlabel == "":
					sys.message(sys.CLIENTERROR, "ModstartBox requested for content element " + tc.title + ", but child " + p.title + " misses contentlabels")
				else:
					# simulate \MNRref and MSRef from mintmod.tex
					s += "<li><!-- mmref;;" + p.contentlabel + ";;0; //-->: <!-- msref;;" + p.contentlabel + ";;" + t + "; //-->"
					if (k < len(tc.children) - 1):
						s += ","
					else:
						s += "."
					s += "<br clear=\"all\"/><br clear=\"all\"/>"
					s += "</li>\n"
			s += "</ul>\n"
			s += "</div\n>"
			return s # replace the tag in html

		(tc.content, n) = re.subn(r"\<!-- modstartbox //--\>", modsb, tc.content, 0, re.S)
		if (tc.level == 2) and (tc.nr == "1") and (n == 0):
			if (tc.parent.nr == 1):
				# only course modules need these boxes
				sys.message(sys.CLIENTWARN, "Module start content " + tc.title + " has no modstart box")


		# extract word index information (must be extracted before stage1 label management)
		def windex(m):
			idx = len(self.data['wordindexlist'])
			li = "ELI_SW" + str(idx)

			(w, n) = re.subn(r"\<math xmlns=\"(.*?)\"\>[\n ]*\<mrow\>\<mi\>(.+?)\</mi\>\</mrow\>\</math\>", "\\2", m.group(1), 0, re.S)
			if n > 0:
				sys.message(sys.VERBOSEINFO, "Removed MathML environments from index word: " + m.group(1) + " -> " + w)

			(w, n) = re.subn(r"\<math xmlns=\"(.*?)\"\>[\n ]*\<mrow\>\<mo\>(.+?)\</mo\>\</mrow\>\</math\>", "\\2", w, 0, re.S)
			if n > 0:
				sys.message(sys.VERBOSEINFO, "Removed MathML environments from index word containing symbols: " + m.group(1) + " -> " + w)

			if "<math" in w:
				sys.message(sys.CLIENTERROR, "Cannot remove MathML tag in index word: " + m.group(1))
			else:
				w = html.fromstring(w).text # decodes HTML tags to umlauts
				if w is None:
					sys.message(sys.CLIENTERROR, "fromstring returned none (perhaps because of malformed MathML) for word " + m.group(1))
				else:
					self.data['wordindexlist'].append((m.group(1), li, w))
					sys.message(sys.VERBOSEINFO, "Found index: " + m.group(1) + ", index is " + str(idx) + ", whole group is " + m.group(0))

			return "<!-- mindexentry;;" + m.group(1) + "; //--><a class=\"label\" name=\"" + li + "\"></a><!-- mmlabel;;" + li + ";;" \
				   + m.group(2) + ";;" + m.group(3) + ";;" + m.group(4) + ";;" + m.group(5) + ";;" + m.group(6) + ";;13; //-->"

		# carefull with regex, last letter of m.group(1) could be a ; because of math symbol HTML tags, on the other hand expressions have to be greedy to prevent overlaps
		tc.content = re.sub(r"\<!-- mpreindexentry;;(.+?);;([^;]+?);;([^;]+?);;([^;]+?);;([^;]+?);;([^;]+?); //--\>", windex, tc.content, 0, re.S)

		# extract labels defined by the macro package: <!-- mmlabel;;Labelbezeichner;;SubjectArea;;chapter;;section;;subsection;;Index;;Objekttyp; //-->
		def elabel(m):
			# labels defined inside math environments have data elements wrapped in an <mn>-tag
			lab = re.sub(r"\</?mn\>", "", m.group(1), 0, re.S)
			chap = re.sub(r"\</?mn\>", "", m.group(2), 0, re.S)
			sub = re.sub(r"\</?mn\>", "", m.group(3), 0, re.S)
			sec = re.sub(r"\</?mn\>", "", m.group(4), 0, re.S)
			ssec = re.sub(r"\</?mn\>", "", m.group(5), 0, re.S)
			sssec = re.sub(r"\</?mn\>", "", m.group(6), 0, re.S)
			ltype = re.sub(r"\</?mn\>", "", m.group(7), 0, re.S)

			pl = tc.fullname + "#" + lab
			self.data['labels'].append((lab, sub, chap, sec, ssec, sssec, ltype, pl))
			sys.message(sys.VERBOSEINFO, "Added label " + lab  + " in chapter " + chap + ", area + " + sub + " with number " + sec + "." + ssec + "." + sssec + "  and type " + ltype + ", pagelink = " + pl)
			return "" # remove the label tag entirely

		tc.content = re.sub(r"\<!-- mmlabel;;(.+?);;(.+?);;(.+?);;(.+?);;(.+?);;(.+?);;(.+?); //--\>", elabel, tc.content, 0, re.S)

		# check if it is a helpsite or a child of one
		if (not tc.parent is None) and tc.parent.helpsite:
			tc.helpsite = True
		else:
			m = re.search(r"(.*)HELPSECTION(.*)", tc.title, re.S)
			if m:
				sys.message(sys.CLIENTINFO, "Helpsection is being set")
				tc.title = m.group(1) + settings.strings['module_helpsitetitle'] + m.group(2)
				tc.helpsite = True
			else:
				tc.helpsite = False

		# add points of exercises to global counters
		def dpoint(m):
			if m.group(5) == "1": #  = chapter = lev1 node position, >1 => not part of course modules
				i = str(int(m.group(1)) - 1)
				sys.message(sys.VERBOSEINFO, "Expoints start, i = " + i + ", group = " + m.group(0))
				if i in self.data['expoints']:
					self.data['expoints'][i] += int(m.group(3))
				else:
					sys.message(sys.VERBOSEINFO, "Expoints added, i = " + i)
					self.data['expoints'][i] = int(m.group(3))
				if m.group(4) == "1":
					if i in self.data['testpoints']:
						self.data['testpoints'][i] += int(m.group(3))
					else:
						self.data['testpoints'][i] = int(m.group(3))
				# sys.message(sys.VERBOSEINFO, "POINTS: Module " + m.group(1) + ", id " + m.group(2) + ", points " + m.group(3) + ", intest " + m.group(4) + ", chapter " + m.group(5))
			return "" # remove the tag
		tc.content = re.sub(r"\<!-- mdeclarepoints;;(.+?);;(.+?);;(.+?);;(.+?);;(.+?);; //--\>", dpoint, tc.content, 0, re.S)

		# write uxids to content elements, save used uxids in global list and check for duplicates
		def duxid(m):
			for u in self.data['uxids']:
				if (u[0] != "UXAUTOGENERATED") and (u[0] == m.group(1)): # autouxes will never appear in point giving exercises (hopefully)
					sys.message(sys.CLIENTERROR, "Duplicate UXID " + u[0] + " mit id1 = " + u[2] + ", id2 = " + m.group(3))
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
					sys.message(sys.CLIENTERROR, "SITEUXID " + u[0] + " mit id1 = " + u[2] + ", id2 = " + m.group(3))
					return s
			self.data['siteuxids'].append([m.group(1), m.group(2), m.group(3)])
			tc.uxid = m.group(1)
			return s
		tc.content = re.sub(r"\<!-- mdeclaresiteuxid;;(.+?);;(.+?);;(.+?);; //--\>", dsuxid, tc.content, 0, re.S)

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
			sys.message(sys.VERBOSEINFO, "Expanding link " + m.group(1))
			lab = m.group(1) # Labelstring
			prefi = int(m.group(2)) # 0 -> Number only, 1 ->  Prefix (i.e.. "Picture 3") present
			href = ""
			objtype = 0
			found = False
			for sl in self.data['labels']:
				if (sl[0] == lab):
					found = True
					href = sl[7] # without tc.backpath, which will be added by the link update function
					sys.message(sys.VERBOSEINFO, "  href = " + href)
					fb = int(sl[1])
					chap = int(sl[2])
					sec = sl[3]
					ssec = sl[4]
					refindex = sl[5]
					objtype = int(sl[6])

			if not found:
				sys.message(sys.CLIENTERROR, "Label " + lab + " has not been found by stage1, label list contains " + str(len(self.data['labels'])) + " items")
				objtype = 0
				return settings.strings['brokenlabel']

			# label types must be consistent with macro file definition !

			ptext = ""
			reftext = ""

			# oh no, Python has no switch
			if objtype == 1:
				# sections are module numbers, displayed as a pure number without subsection numbers, index is irrelevant
				reftext = sec
				ptext = settings.strings['module_labelprefix']

			elif objtype == 2:
				# subsections are MSubsections in modules, represented as SECTION.SUBSECTION, index is irrelevant
				reftext = sec + "." + ssec
				ptext = settings.strings['subsection_labelprefix']

			elif objtype == 3:
				# subsubsections are prepresented as number triplet
				reftext = sec + "." + ssec + "." + refindex
				ptext = settings.strings['subsubsection_labelprefix']

			elif objtype == 4:
				# a info box, given by a number triplet
				ptext = "Infobox"
				if ((fb == 1) or (fb == 2)):
					reftext = sec + "." + ssec + "."  + refindex
				else:
					reftext = ""
					sys.message(sys.CLIENTWARN, "Reference " + lab + " to an info box given chapter index " + str(fb) + " without info box number")

			elif objtype == 5:
				# an exercise, represented by a number triplet
				ptext = settings.strings['exercise_labelprefix']
				reftext = sec + "." + ssec + "." + refindex

			elif objtype == 6:
				# an example, represented by a number triplet
				ptext = settings.strings['example_labelprefix']
				reftext = sec + "." + ssec + "." + refindex

			elif objtype == 7:
				# an experiment
				ptext = settings.strings['experiment_labelprefix']
				reftext = sec + "." + ssec + "." + refindex

			elif objtype == 8:
				# an image, is referenced by a single number
				ptext = settings.strings['image_labelprefix']
				if (((fb == 1) or (fb == 2) or (fb == 4)) and (prefi == 0)):
					reftext = refindex
				else:
					sys.message(sys.CLIENTWARN, "Reference " + lab + " to an image using chemistry settings not implemented yet")
					reftext = refindex

			elif objtype == 9:
				# a table, is referenced by a single number
				ptext = settings.strings['table_labelprefix']
				if (((fb == 1) or (fb == 2) or (fb == 4)) and (prefi == 0)):
					reftext = refindex
				else:
					sys.message(sys.CLIENTWARN, "Reference " + lab + " to a table using chemistry settings not implemented yet")
					reftext = refindex

			elif objtype == 10:
				# a equation, represented by a number triplet with braces
				# equation numbers force MLastIndex to be set to "equation" in TeX conversion
				ptext = settings.strings['equation_labelprefix']
				reftext = "(" + sec + "." + ssec + "." + refindex + ")"

			elif objtype == 11:
				# a theorem or theoremx, represented by a number triplet
				ptext = settings.strings['theorem_labelprefix']
				if (((fb == 1) or (fb == 2) or (fb == 4)) and (prefi == 0)):
					reftext = sec + "." + ssec + "." + refindex
				else:
					sys.message(sys.CLIENTWARN, "Reference " + lab + " to a theorem using chemistry settings not implemented yet")
					reftext = sec + "." + ssec + "." + refindex

			elif objtype == 12:
				# a video, represented by a single number
				ptext = settings.strings['video_labelprefix']
				if (((fb == 1) or (fb == 2) or (fb == 4)) and (prefi == 0)):
					reftext = sec + "." + ssec + "." + refindex
				else:
					sys.message(sys.CLIENTWARN, "Reference " + lab + " to a video using chemistry settings not implemented yet")
					reftext = sec + "." + ssec + "." + refindex

			elif objtype == 13:
				# index entries in modules, only position S.SS.SSS is known
				reftext = sec + "." + ssec
				ptext = settings.strings['subsection_labelprefix']

			else:
			   sys.message(sys.CLIENTWARN, "An MRef reference of type " + str(objtype) + " from label " + lab + " has unknown type")
			   reftext = ""

			if reftext != "":
				if (prefi == 1):
					reftext = ptext + " " + reftext
				return "<a class=\"MINTERLINK\" href=\"" + href + "\">" + reftext + "</a>"

			sys.message(sys.CLIENTERROR, "Label " + lab + " could not be resolved")
			return settings.strings['brokenlabel']

			# end refexpand
		tc.content = re.sub(r"\<!-- mmref;;(.+?);;(.+?); //--\>", refexpand, tc.content, 0, re.S)

		# label management: expand MSRef tags
		def srefexpand(m):
			sys.message(sys.VERBOSEINFO, "Expanding MSRef link " + m.group(1) + " of title " + m.group(2))
			lab = m.group(1)
			txt = m.group(2)
			href = ""
			for sl in self.data['labels']:
				if (sl[0] == lab):
					href = sl[7]  # without tc.backpath, which will be added by the link update function
					sys.message(sys.VERBOSEINFO, "  href = " + href)


			if href != "":
				return "<a class=\"MINTERLINK\" href=\"" + href + "\">" + txt + "</a>"
			else:
				sys.message(sys.CLIENTERROR, "Could not resolve MSRef on label " + lab + " with text " + txt)
				return settings.strings['brokenlabel']

		tc.content = re.sub(r"\<!-- msref;;(.+?);;(.+?); //--\>", srefexpand, tc.content, 0, re.S)

		# perform some HTML content optimizations

		# delete text "Chapter" in chapters (compatible with MINTERLINK?)
		m = re.search(r"^\<a name=.*?\>\n(Chapter )?(.*?)\</a\>(\<br /\>|&nbsp;&nbsp;)(.*)$", tc.title, re.S)
		if m:
			tc.title = m.group(2) + " " + m.group(4)
			sys.message(sys.VERBOSEINFO, "Chapter title modified to " + tc.title)

		# "," is treated like an operator by ttm
		# decimal numbers in mn-tag
		# care for decimal numbers with powers
		(tc.content, n) = re.subn(r"\<mn\>([0-9]*)\</mn\>\<mo\>,\</mo\>(\n|\r)*\<msup\>\<mrow\>\<mn\>([0-9]*)\</mn\>\</mrow\>\<mrow\>\<mn\>([0-9])\</mn\>\</mrow\>(\n|\r)*\</msup\>",
								  "<msup><mrow><mn>\\1,\\3</mn></mrow><mrow><mn>\\4</mn></mrow>\n</msup>", tc.content, 0, re.S)
		if n > 0:
			sys.message(sys.VERBOSEINFO, "Performed " + str(n) + " decimal number modifications")


		# Care for a bug in MathJax 2.6 (not present in 2.4): displaystyle=true is not inherited by tables and must be declared again inside the table
		(tc.content, n) = re.subn(r"\<mstyle displaystyle=\"true\"\>\<mrow\>\n\<mtable([^\>]+)\>", "<mstyle displaystyle=\"true\"><mrow>\n<mtable\\1><mstyle displaystyle=\"true\">", tc.content, 0, re.S)
		if n > 0:
			sys.message(sys.VERBOSEINFO, "Performed " + str(n) + " mstyle modifications on mtables")

		# gemerate MathML tables without width or alignment attributes (which in IE generate large spaced areas)
		(tc.content, n) = re.subn(r"\<mtable([^\>]+)\>", "<mtable>", tc.content, 0, re.S)
		if n > 0:
			sys.message(sys.VERBOSEINFO, "Performed " + str(n) + " IE-mtable modifications")

		# paragraph math not in tales, but in center tags
		(tc.content, n) = re.subn(r"\<table width=\"100%\"\>\<tr\>\<td align=\"center\"\>\s*(\<math(.|\n)*?\</math\>)\s*\</td\>\</tr\>\</table\>",
								   "<center>\\1</center>", tc.content, 0, re.S)
		if n > 0:
			sys.message(sys.VERBOSEINFO, "Performed " + str(n) + " tabletag modifications")

		# \subsetneq unknown to ttm
		tc.content = tc.content.replace("\\subsetneq", "<mtext>&subne;</mtext>")

		# mathbb set symbols
		(tc.content, n) = re.subn(r"\\mathbb\<mi\>[A-Za-z]\</mi\>", "<mo>&\\1opf;</mo>", tc.content, 0, re.S)
		if n > 0:
			sys.message(sys.VERBOSEINFO, "Performed " + str(n) + " set symbol modifications")

		# reduce space lengths in formulas
		tc.content = re.sub(r"\<mi\>&emsp;\</mi\>", "<mi>&nbsp;</mi>", tc.content, 0, re.S)
		tc.content = re.sub(r"\<mi\>&emsp;&emsp;\</mi\>", "<mi>&nbsp;&nbsp;</mi>", tc.content, 0, re.S)
		tc.content = re.sub(r"\<mi\>&emsp;&emsp;&emsp;\</mi\>", "<mi>&nbsp;&nbsp;&nbsp;</mi>", tc.content, 0, re.S)
		tc.content = re.sub(r"\<mi\>&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;\</mi\>", "<mi>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</mi>", tc.content, 0, re.S) # generated by two successive \quad

		#\empty us not an integer, but text
		tc.content = re.sub(r"\<mi\>&empty;\</mi\>", "<mtext>&empty;</mtext>", tc.content, 0, re.S)

		# text directly placed in front of a $-environment (especially open braces) receive a newline in HTML which turns into a space in HTML, remove it
		# DEACTIVATED with new ttm and mathjax 2.6
		# tc.content = re.sub(r"\n\<math", "<math", tc.content, 0, re.S)

		# tables with borders need borders for cells too (as strict html requires all elements to have same border style, which can only be
		# be circumvented using css or js tricks)

		# this produces invalid html
		#def repltd(m):
		#	t = re.sub(r"\<td([^\>]*?)\>", "<td\\1 class=\"rahmen\">", m.group(1), 0, re.S)
		#	return "<table border=\"1\" class=\"rahmen\">" + t + "</table>"
		#tc.content = re.sub(r"\<table border\=\"1\"\>((.|\s)*?)\</table\>", repltd, tc.content, 0, re.S)


		# recursively analyze children
		for c in tc.children:
			self.analyze_nodes_stage2(c)


	# generates html file content using the page factory object for the entire tree (given by its root node)
	def generate_html(self, tc):
		for c in tc.children:
			self.generate_html(c)
		self.page.renderHTML(tc)


	def write_htmlfiles(self, tc):
		for c in tc.children:
			self.write_htmlfiles(c)
		if tc.display:
			f_html = os.path.join(settings.targetpath, self.outputsubdir, tc.link + "." + self.outputextension)
			f_json = os.path.join(settings.targetpath, self.outputsubdir, tc.link + "." + "json")
			if not self.releaseCheck(tc.html, f_html):
				sys.message(sys.CLIENTWARN, "File " + f_html + " did not pass post release check")
				if settings.dorelease == 1:
					sys.message(sys.FATALERROR, "Refusing to create a release version due to check errors")

			# wrong place to set javascript vars:
			# this class should be concerned with writing files, not changing their content
			jso = json.dumps(tc.sitejson)
			if len(jso) > settings.maxsitejsonlength:
				# use a separate file for the json companion object
				tc.html = tc.html.replace("var sitejson_load = false;", "var sitejson_load = true;", 1)
				sys.writeTextFile(f_json, jso, settings.outputencoding)
				sys.message(sys.CLIENTINFO, 'JSON for %s written to %s' % (tc.caption, f_json) )
			else:
				# directly paste the object as JSON string into the page
				tc.html = tc.html.replace("var sitejson = {};", "var sitejson = " + jso + ";", 1);

			# write the actual html file
			sys.writeTextFile(f_html, tc.html, settings.outputencoding)
			self.filecount += 1
			if "<!-- mglobalstarttag -->" in tc.html:
				sys.message(sys.CLIENTINFO, "Global starttag found in file " + f_html + ", locally " + tc.link)
				self.startfile = self.outputsubdir + "/" + tc.link + "." + self.outputextension
				self.entryfile = "entry_" + tc.docname + "." + self.outputextension

			# search for other tags and create redirects if found
			for s in settings.sitetaglist:
				sys.message(sys.VERBOSEINFO, "Tag %s found in %s" % (s, tc.link) )
				if "<!-- mglobal" + s + "tag -->" in tc.html:
					sys.message(sys.CLIENTINFO, "Global " + s + "tag found in file " + f_html + ", locally " + tc.link)
					sys.message(sys.VERBOSEINFO, "Tag %s found in %s" % (s, tc.link) )
					self.siteredirects[s][1] = self.outputsubdir + "/" + tc.link + "." + self.outputextension

			# generate export files if required
			if (len(tc.exports) != 0):
				sys.message(sys.VERBOSEINFO, "Generating " + str(len(tc.exports)) + " additional export files")
				for i in range(len(tc.exports)):
					sys.writeTextFile(os.path.join(tc.fullpath, tc.exports[i][0]), tc.exports[i][1], self.outputencoding)



	def write_miscfiles(self):
		# write redirects
		if self.startfile == "":
			pass
			#sys.message(sys.FATALERROR, "No startfile found")
		else:
			self.createRedirect("index.html", self.startfile, False)
			sys.message(sys.CLIENTINFO, "HTML Tree entry chain created")
			sys.message(sys.CLIENTINFO, "  index.html -> " + self.startfile)
			if (settings.doscorm == 1) or (settings.doscorm12 == 1):
				self.createRedirect(self.entryfile, self.startfile, True)
				sys.message(sys.CLIENTINFO, "  SCORM -> " + self.entryfile + " -> " + self.startfile)

		for s in settings.sitetaglist:
			if self.siteredirects[s][1] != "":
				sys.message(sys.VERBOSEINFO, "Writing misc file for tag %s redirect in %s %s" % (s, self.siteredirects[s][0], self.siteredirects[s][1]) )
				self.createRedirect(self.siteredirects[s][0], self.siteredirects[s][1], False)

		# write SCORM manifest if needed
		if settings.doscorm == 1:
			pass

		# write variables in conversion info file
		self.data['signature'] = sys.get_conversion_signature()
		# generate a course id which is unique (given course and version)
		self.data['signature']['CID'] = "(" + settings.signature_main + ";;" + settings.signature_version + ";;" + settings.signature_localization + ")"
		sys.message(sys.CLIENTINFO, "Generating Course Signature:")
		sys.message(sys.CLIENTINFO, "	  main: " + settings.signature_main)
		sys.message(sys.CLIENTINFO, "   version: " + settings.signature_version)
		sys.message(sys.CLIENTINFO, "	locale: " + settings.signature_localization)
		sys.message(sys.CLIENTINFO, " timestamp: " + self.data['signature']['timestamp'])
		sys.message(sys.CLIENTINFO, " conv-user: " + self.data['signature']['convuser'])
		sys.message(sys.CLIENTINFO, " c-machine: " + self.data['signature']['convmachine'])
		sys.message(sys.CLIENTINFO, "	   CID: " + self.data['signature']['CID'])
		sys.message(sys.CLIENTINFO, "  git-head: " + settings.signature_git_head)
		sys.message(sys.CLIENTINFO, "git-branch: " + settings.signature_git_branch)
		sys.message(sys.CLIENTINFO, "   git-msg: " + settings.signature_git_message)
		sys.message(sys.CLIENTINFO, "   git-sha: " + settings.signature_git_commit)
		sys.message(sys.CLIENTINFO, " git-cauth: " + settings.signature_git_committer)
		sys.message(sys.CLIENTINFO, " git-dirty: " + str(settings.signature_git_dirty))
		sys.message(sys.CLIENTINFO, "Signature will be available in the HTML tree")
        # scorm and scormLogin are now available in js (intersite.isScormEnv())
		s = "// Automatically generated by the tex2x VEUNDMINT output plugin\n" \
            + "var outputExtension = \"" + self.outputextension + "\";\n" \
            + "var outputSubdir = \"" + self.outputsubdir + "\";\n" \
            + "var outputWebdir = \"" + settings.output + "\";\n" \
            + "var MESSAGE_DONE = \"" + settings.strings['message_done'] + "\";\n" \
            + "var MESSAGE_PROGRESS = \"" + settings.strings['message_progress'] + "\";\n" \
            + "var MESSAGE_PROBLEM = \"" + settings.strings['message_problem'] + "\";\n" \
            + "var forceOffline = " + str(settings.forceoffline) + ";\n" \
            + "var isRelease = " + str(settings.dorelease) + ";\n" \
            + "var doCollections = " + str(settings.docollections) + ";\n" \
            + "var isVerbose = " + str(settings.doverbose) + ";\n" \
            + "var testOnly = " + str(settings.testonly) + ";\n" \
            + "var signature_CID = \"" + self.data['signature']['CID'] + "\";\n" \
            + "var signature_git_dirty = " + str(settings.signature_git_dirty) + ";\n" \
            + "var signature_git_head = \"" + settings.signature_git_head + "\";\n" \
            + "var signature_git_branch = \"" + settings.signature_git_branch + "\";\n" \
            + "var signature_git_message = \"" + settings.signature_git_message + "\";\n" \
            + "var signature_git_commit = \"" + settings.signature_git_commit + "\";\n"

		if settings.doscorm12 == 1:
			# s += "var doScorm = 1;\n"
			s += "var expectedScormVersion = \"1.2\";\n"
		else:
			if settings.doscorm == 1:
				# s += "var doScorm = 1;\n"
				s += "var expectedScormVersion = \"2004\";\n"
			else:
				s += "var doScorm = 0;\n"
				s += "var expectedScormVersion = \"\";\n"



		for vr in ["signature_main", "signature_version", "signature_localization", "do_feedback", "do_export", "reply_mail",
				   "data_server", "exercise_server", "feedback_service", "data_server_description", "data_server_user",
				  "variant"]:
			s += "var " + vr + " = \"" + getattr(settings, vr) + "\";\n"

		s += "var feedbackdesc = data_server_description;\n";


		if settings.dorelease == 1:
			sys.message(sys.CLIENTINFO, "RELEASE VERSION will be generated")
		else:
			sys.message(sys.CLIENTINFO, "Nonrelease will be generated")
			s += "console.log(\"NON RELEASE VERSION\");\n"

		if settings.doverbose == 1:
			sys.message(sys.CLIENTINFO, "Verboseversion will be generated")
			s += "console.log(\"VERBOSE VERSION\");\n"

		if settings.do_feedback == 1:
			sys.message(sys.CLIENTINFO, "Feedbackversion will be generated")

		if settings.do_export == 1:
			sys.message(sys.CLIENTINFO, "Exportversion will be generated")

		s += "var globalsections = [];\n"
		for i in range(len(self.data["sections"])):
			s += "globalsections[" + str(i) + "] = \"" + str(self.data["sections"][str(i)]) + "\";\n"

		for glb in ['sitepoints', 'expoints', 'testpoints']:
			s += "var global" + glb + " = [];\n"
			for i in range(len(self.data[glb])):
				if str(i) in self.data[glb]:
					s += "global" + glb + "[" + str(i) + "] = " + str(self.data[glb][str(i)]) + ";\n"

				sys.writeTextFile(os.path.join(settings.targetpath, 'js', settings.convinfofile), s, settings.outputencoding)


	# generate css and js style files
	def generate_css(self):

		path = os.path.join(settings.sourcepath, settings.template_precss)
		sys.copyFiletree(settings.converterDir, settings.sourcepath, settings.template_precss)
		sys.pushdir()
		os.chdir(path)

		p = subprocess.Popen(["php", "-n", "grundlagen.php"], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
		(css, err) = p.communicate()

		if p.returncode != 0:
			css = ""
			sys.message(sys.CLIENTERROR, "php reported an error on grundlagen.php:\n" + str(css) + "\n" + str(err))

		jcss = ""
		ocss = ""

		# parse color values (given as strings without # prefix), sorting them is just to beautify git diff results
		jcss += "var COLORS = new Object();\n"
		c = sorted(settings.colors.items(), key = lambda x: x[0])
		for p in c:
			jcss += "COLORS." + p[0] + " = \"" + p[1] + "\";\n"

		# parse fonts
		jcss += "var FONTS = new Object();\n"
		c = sorted(settings.fonts.items(), key = lambda x: x[0])
		for p in c:
			jcss += "FONTS." + p[0] + " = \"" + p[1] + "\";\n"

		# parse sizes
		jcss += "var SIZES = new Object();\n"
		c = sorted(settings.sizes.items(), key = lambda x: x[0])
		for p in c:
			jcss += "SIZES." + p[0] + " = " + str(p[1]) + ";\n"

		# substitute colors, fonts and sizes in css files, but generate a original css file as JS without substitutions
		jcss += "var DYNAMICCSS = \"\"\n"
		def drow(m):
			nonlocal ocss
			nonlocal jcss
			row = m.group(1)
			ocss += row + "\n"
			row = sys.injectEscapes(row)
			jcss += " + \"" + row + "\"\n"
		re.sub(r"([^\n]+)", drow, css, 0, re.S)

		jcss += " + \"\";"

		sys.writeTextFile(os.path.join(settings.targetpath, "grundlagen.css"), ocss, settings.outputencoding)
		sys.writeTextFile(os.path.join(settings.targetpath, "js/dynamiccss.js"), jcss, settings.outputencoding)
		sys.popdir()
		sys.message(sys.VERBOSEINFO, "Stylefiles created")


	def generate_directory(self):
		sys.emptyTree(settings.targetpath)
		sys.copyFiletree(settings.converterCommonFiles, settings.targetpath, ".")
		if settings.localjax == 1:
			mpath = os.path.join(settings.targetpath, "MathJax")
			sys.emptyTree(mpath)
			p = subprocess.Popen(["tar", "-xvzf", os.path.join(settings.converterDir, settings.mathjaxtgz), "--directory=" + mpath],
								 stdout = subprocess.PIPE, shell = False, universal_newlines = True)
			(tar, err) = p.communicate()
			if p.returncode != 0:
				sys.message(sys.CLIENTERROR, "Could not unpack local MathJax folder:\n" + tar + "\n" + str(err))
			else:
				sys.message(sys.CLIENTINFO, "Local MathJax installed (from " + settings.mathjaxtgz + ") in path " + mpath)

		if settings.doscorm12 == 1:
			p = subprocess.Popen(["tar", "-xvzf", os.path.join(settings.converterDir, settings.scorm12tgz), "--directory=" + settings.targetpath],
								 stdout = subprocess.PIPE, shell = False, universal_newlines = True)
			(tar, err) = p.communicate()
			if p.returncode != 0:
				sys.message(sys.CLIENTERROR, "Could not unpack local SCORM 1.2 material:\n" + tar + "\n" + str(err))
			else:
				sys.message(sys.CLIENTINFO, "Local SCORM 1.2 base files installed (from " + settings.scorm12tgz + ")" )

		if settings.doscorm == 1:
			p = subprocess.Popen(["tar", "-xvzf", os.path.join(settings.converterDir, settings.scorm4tgz), "--directory=" + settings.targetpath],
								 stdout = subprocess.PIPE, shell = False, universal_newlines = True)
			(tar, err) = p.communicate()
			if p.returncode != 0:
				sys.message(sys.CLIENTERROR, "Could not unpack local SCORM 4 material:\n" + tar + "\n" + str(err))
			else:
				sys.message(sys.CLIENTINFO, "Local SCORM 4 base files installed (from " + settings.scorm12tgz + ")" )


	def createRedirect(self, filename, redirect, scorm):
		# filename (containing the redirect) and target are given relative to top level directory
		if scorm:
			self.writeRedirect(self.template_redirect_scorm, filename, redirect, scorm )
		else:
			s = self.template_redirect_basic
		s = re.sub(r"\$url", redirect, s, 0, re.S)
		sys.writeTextFile(os.path.join(settings.targetpath, filename), s, settings.outputencoding)
		sys.message(sys.CLIENTINFO, "Redirect created from " + filename + " to " + redirect)


	def finishing(self):
		# perform borkification if requested
		if settings.borkify == 1:
			self.borkifyHTML()
			self.minimizeJS()

		# set linux usage flags for all files
		p = subprocess.Popen(["chmod", "-R", settings.accessflags, settings.targetpath], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
		(chmod, err) = p.communicate()
		if p.returncode != 0:
			sys.message(sys.CLIENTERROR, "Could not set access flags on output folder " + settings.targetpath)

		# final check for unwanted files in target
		for xt in [ "py", "pyc", "sty", "tex", "png~", "js~", "tex~", self.outputextension + "~"]:
			fl = sys.listFiles(os.path.join(settings.targetpath, "*." + xt))
			if len(fl) > 0:
				sys.message(sys.CLIENTWARN, str(len(fl)) + " unwanted files with extension " + xt + " found in target directory")
				if settings.dorelease == 1:
					sys.message(sys.FATALERROR, "Aborting release because target directory is unclean")


		if settings.dopdf == 1:
			pd = " and pdf (" + ",".join(doct for doct in settings.generate_pdf) + ")"
		else:
			pd = ""
		sys.message(sys.CLIENTINFO, "FINISHED tree containing " + self.outputextension + pd)

		if settings.doscorm12 == 1:
			self.writeSCORM12files()

		if settings.doscorm == 1:
			self.writeSCORM4files()

		if settings.dozip == 1:
			sys.pushdir()
			os.chdir(settings.targetpath)
			zipfile = settings.output + ".zip"
			p = subprocess.Popen(["zip", "-r", os.path.join(settings.currentDir, zipfile), ".", "-i", "*"], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
			(output, err) = p.communicate()
			sys.popdir()
			if p.returncode == 0:
				sys.message(sys.CLIENTINFO, "Generated zip file " + zipfile)
			else:
				sys.message(sys.FATALERROR, "zip command error, last lines:" + output)


	# prepares the searchword index by using the wordlist generated by the tcontent node iteration
	def prepare_index(self):
		# sort the list using the modified strings according to locale (for umlauts)
		self.data['wordindexlist'] = sorted(self.data['wordindexlist'], key = lambda entry: locale.strxfrm(entry[2]))
		sys.message(sys.CLIENTINFO, "Found " + str(len(self.data['wordindexlist'])) + " index entries")
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
		if settings.dopdf != 1:
			sys.message(sys.VERBOSEINFO, "PDF generation not activated in options")
			return

		sys.message(sys.VERBOSEINFO, "Generating PDFs, can take a while...")
		sys.pushdir()
		os.chdir(settings.sourceTEX)
		pdfok = True
		for doct in settings.generate_pdf:
			tfile = doct
			docdesc = settings.generate_pdf[doct]
			if tfile[-4:] != ".tex":
				tfile = doct + ".tex"
			else:
				sys.message(sys.CLIENTWARN, "pdf texfile + " + doct + " should be without extension in options")
				pdfok = False

			sys.timestamp("Generating PDF file " + tfile + " (" + docdesc + ")")

			for cl in [ ["pdflatex", "-halt-on-error", "-interaction=errorstopmode", tfile], \
						["pdflatex", "-halt-on-error", "-interaction=errorstopmode", tfile], \
						["makeindex", "-q", doct], \
						["pdflatex", "-halt-on-error", "-interaction=errorstopmode", tfile]]:
				if pdfok:
					p = subprocess.Popen(cl, stdout = subprocess.PIPE, shell = False, universal_newlines = True)
					(output, err) = p.communicate()
					if p.returncode < 0:
						sys.message(sys.FATALERROR, "Call to " + cl[0] + " for file " + tfile + " was terminated by a signal (POSIX return code " + p.returncode + ")")
						pdfok = False
					else:
						if p.returncode > 0:
							sys.message(sys.CLIENTERROR, cl[0] + " could not process file " + tfile + ", error lines have been written to logfile")
							s = output[-256:]
							s = s.replace("\n",", ")
							sys.message(sys.VERBOSEINFO, "Last " + cl[0] + " lines: " + s)
							pdfok = False
						else:
							sys.timestamp(cl[0] + " finished successfully")

				else:
					sys.message(sys.CLIENTWARN, "Skipping system call to " + cl[0] + " on " + tfile + " due to previous tex errors")


			if pdfok:
				sys.timestamp("Generation of PDF files for " + tfile + " (" + docdesc + ") successfull")
				sys.copyFile("." , settings.targetpath, doct + ".pdf")
				sys.message(sys.CLIENTINFO, "Generated " + doct + ".pdf in top level directory")
			else:
				sys.timestamp("PDF generation aborted for " + tfile)

		sys.popdir()


	# performs some basic checks if html code can be released to the public
	def releaseCheck(self, html, fname):
		reply = True
		# check for broken labels from internal label management
		if settings.strings['brokenlabel'] in html:
			reply = False
			sys.message(sys.VERBOSEINFO, "Broken internal label found in html file " + fname)

		# check some basic unwanted substrings
		for tag in [['TODO',		'TODO line found'],
					['ToDo',		'ToDo line found'],
					['Todo',		'Todo line found'],
					['special',	 'Word \"special\" found, some \\special command from TeX got through'],
					['XXX',		 'Marker \"XXX\" found, something should be polished']
				   ]:
			if tag[0] in html:
				reply = False
				sys.message(sys.VERBOSEINFO, tag[1] + " in file " + fname)

		# check uxid processing
		uc = 0
		def ucount(m):
			nonlocal uc, reply
			uc += 1
			if (uc > 1):
				reply = False
				sys.message(sys.CLIENTWARN, "Found more then one site UXID in file " + fname + ": " + m.group(0))
		re.sub(re.escape("<!-- mdeclaresiteuxidpost;;") + r"(.+?)" + re.escape(";; //-->"), ucount, html, 0, re.S)


		# Don't use tidy on bootrap version, as it erases necessary elements.
		# tidy is applied in PageTUB on the page content anyway.
		if ( not settings.bootstrap ):
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
					for tag in settings.specialtags:
						if m.group(4) == "<" + tag + "> is not recognized!":
							ok = True
					if not ok:
						sys.message(sys.CLIENTWARN, "libtidy found error in " + fname + ": " + m.group(0))
						reply = False
				elif m.group(3) == "Warning":
					wrn += 1
				elif m.group(3) == "Info":
					inf += 1
				else:
					sys.message(sys.CLIENTERROR, "libtidy line could not be parsed: " + m.group(0))

			re.sub(r"line (\d*) column (\d*) - ([^\:]+): ([^\n]*)(?=\n)", tidyerrline, tidylines, 0, re.S)
			if wrn > 0:
				sys.message(sys.VERBOSEINFO, "libtidy found " + str(wrn) + " warnings and " + str(inf) + " infos in file " + fname)
			else:
				sys.message(sys.CLIENTWARN, "libtidy found no errors (or its output was somehow not parsed correctly) for file " + fname)


		return reply


	def minimizeJS(self):
		sys.pushdir()
		os.chdir(settings.targetpath)

		fs = ""
		for f in settings.jstominimize:
			jcontent = sys.readTextFile(f, "utf-8")
			# perform some checks on the JS code
			if "console.log" in jcontent:
				sys.message(sys.CLIENTINFO, "There are console.log commands in js file " + f + ", these should be replaced by logMessage commands")

			p = subprocess.Popen(["java", "-jar", os.path.join(settings.converterDir, "yuicompressor-2.4.8.jar"), f, "-o", f], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
			(output, err) = p.communicate()
			if p.returncode < 0:
				sys.message(sys.FATALERROR, "Call to java for jar yuicompressor on file " + f + " was terminated by a signal (POSIX return code " + p.returncode + ")")
			else:
				if p.returncode > 0:
					sys.message(sys.CLIENTERROR, "java yuicompressor could not process javascript file " + f + ", error lines have been written to logfile")
					s = output[-256:]
					s = s.replace("\n",", ")
					sys.message(sys.VERBOSEINFO, "Last yuicompressor lines: " + s)
					fs += " [" + f + "]"
				else:
					fs += " " + f

		sys.message(sys.VERBOSEINFO, "Minimized JS files:" + fs)
		sys.popdir()
		sys.message(sys.CLIENTINFO, "Minimized " + str(len(settings.jstominimize)) + " javascript files")


	def borkifyHTML(self):
		sys.pushdir()
		os.chdir(settings.targetpath)

		hfiles = sys.listFiles("**/*." + self.outputextension)
		for f in hfiles:
			lan = 32;
			st = list()
			GSLS = "__CQJ = CreateQuestionObj; function GSLS(c) {\n  var str = \"\";\n"
			html = sys.readTextFile(f, settings.outputencoding)
			# borkify the content
			def dobork(m):
				nonlocal st, lan
				b = "__CQJ(" + m.group(1) + "," + m.group(2) + ",GSLS(" + m.group(2) + ")"
				s = m.group(3)
				st.append((m.group(2), s, len(s)))
				if (lan <= 2*len(s)):
					lan = 2*len(s) + 1
				return b
			(html, n) = re.subn(r"[ \n\t]*CreateQuestionObj\((\".*?\"),(\d+?),\"(.*?)\"", dobork, html, 0, re.S)
			sys.message(sys.VERBOSEINFO, "Borkifying " + f + " with " + str(n) + " CreateQuestionObj calls and " + str(len(st)) + " borkstrings")
			for p in st:
				GSLS += "if(c==" + p[0] + "){str=debork(\"" + self.borkString(lan, p[1]) + "\"," + str(p[2]) + ");}"

			GSLS += "return str;}\n"
			html = re.sub(r"__CQJ", "\n" + GSLS + "\n__CQJ", html, 1, re.S)
			sys.writeTextFile(f, html, settings.outputencoding)

		sys.message(sys.CLIENTINFO, "Borkified " + str(len(hfiles)) + " " + self.outputextension + " files")
		sys.popdir()


	def randomChar(self):
		r = randint(0,len(self.randcharstr) - 1)
		return self.randcharstr[r]


	def permuteString(self, str, u):
		n = len(str)
		t = ""
		for i in range(n):
			t += str[(u*i) % n]

		return t


	def borkString(self, lan, str):
		t = ""
		for i in range(lan):
			if i < len(str):
				t += str[i]
			else:
				t += self.randomChar()
		u = (((5*lan) - (3*len(str))) % lan)
		while (self.gcd(u, lan) != 1):
			u = ((u + 1) % lan)

		t2 = self.permuteString(t, u)
		return t2


	def gcd(self, u, v):
		while (v != 0):
			(u, v) = (v, u % v)
		return abs(u)


	def writeSCORM12files(self):
		sys.message(sys.CLIENTINFO, "SCORM 1.2 output requested")
		sys.pushdir()

		# write the manifest file, including the file list
		manifest = sys.readTextFile(settings.template_scorm12manifest, settings.stdencoding)
		os.chdir(settings.targetpath)
		p = subprocess.Popen(["find", "."], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
		(output, err) = p.communicate()
		if p.returncode != 0:
			sys.message(sys.FATALERROR, "find command error, last lines:" + output)

		manif = ""
		fc = 0
		nfc = 0
		fl = output.splitlines()
		for l in fl:
			if l != ".":
				if os.path.isfile(l):
					manif += "  <file href=\"" + l[2:] + "\"/>\n" # don't use preceeding "./" in filenames
					fc += 1
				else:
					nfc += 1

		manif = "<resource adlcp:scormtype=\"sco\" href=\"" + self.entryfile + "\" type=\"webcontent\" identifier=\"xml_index.html\">\n" + manif + "</resource>\n"

		manifest = re.sub(r"</resources>", manif + "</resources>", manifest, 1, re.S)
		sys.writeTextFile("imsmanifest.xml", manifest, settings.outputencoding)

		sys.message(sys.CLIENTINFO, "SCORM 1.2: " + str(fc) + " files added to package, " + str(nfc) + " non-files excluded in manifest")
		sys.popdir()


	def writeSCORM4files(self):
		sys.message(sys.CLIENTINFO, "SCORM 4 output requested")
		sys.message(sys.FATALERROR, "SCORM 4 is not implemented yet")
