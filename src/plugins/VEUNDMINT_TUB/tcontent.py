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
	This is the TContent object associated to the mintmod macro package
"""

from os import path
import json
import re
from lxml import etree

class TContent(object):

	def __init__(self):

		# following properties are used for the root element of the tree, others have to overwrite most of them
		self.ismodule = False # if element belongs to a course module (as opposed to help and miscelannous sites), will be set later in the output processing
		self.modulepart = "" # ??
		
		self.level = 0
		self.ischapter = 0

		# tree structure of TContent
		self.children = [] # list of references to TContent objects
		self.parent = None
		self.root = None
		self.right = None # .next is special in python
		self.left = None
		self.xright = None
		self.xleft = None

		# content information
		self.helpsite = False
		self.testsite = False
		self.tocsymb = "?"
		self.title = "ROOT" # text of the html title tag for children, contains online course description and item name, not suited for buttons
		self.caption = "" # used for navigation buttons, contains a short title description
		self.modulid = ""
		# attribute chapter set for level 1 nodes and recursively for their children
		# attribute section only set for level 2 sectionstarts
		# attribute subsection only set for level 4 xcontents

		# tree context information
		self.nr = ""
		self.pos = 0
		self.link = "" # for level <=3: section combination, level4: sectioncombo/docname (without html extension)
		self.backpath = "../" # level <=3: located in targetDir/html, should be used as backpath + link, never use os.path.join here as this is evaluated in JavaScript only!
		self.fullname = "" # if display==True, this contains the full path/filename relative to the top directory
		self.contentlabel = "" # will be set by node management and processed by label management, can be used with mmref and msref tags
		self.savepage = False
		self.menuitem = True
		self.display = False
		
		# other information
		self.exports = [] # list of pairs [ localfilename, txtcontent ]
		self.docname = ""
		self.uxid = ""
		self.myid = 0 # .id is special in python, 0 is the id of the root element
		self.content = "" # pure html content of the element
		self.html = "" # will be filled by Page with proper html file content
		self.sitejson = dict() # will be filled by PageFactory with content and passed as json to the page

		self.annotations = []
		# at time of construction, this object is its own tree
		self.root = self


	# searches for an element in the tree
	def elementByID(self, myid):
		if self.myid == myid:
			return self
		else:
			for k in self.children:
				ref = k.elementByID(myid)
				if (not ref is None):
					return ref
			return None
   

	# returns a string representation of the tree
	def __str__(self):
		return self._rstr(0)
		
	def _rstr(self, inset):
		s = ""
		i = 0
		while (i < inset):
			s = s + "	"
			i = i + 1
		s = s + self.title + ", pos=" + str(self.pos) + "\n"
		for p in self.children:
			s = s + p._rstr(inset + 1)
		return s
	
	
	# returns next displayable prev object
	def navleft(self):
		p = self.left
		# iterate until root is reached or a displayable object
		while (not p is None) and (p.level != 0 and not p.display):
			p = p.left
		
		if p is None: return None
		
		if p.level != 0:
			return p
		else:
			return None

		
	# returns next displayable next object
	def navright(self):  
		p = self.right
		# iterate until end of object structure is reached or a displayable object
		while (not p is None) and p.display:
			p = p.right

		return p


		