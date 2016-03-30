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

import os.path
import json
import re

class TContent(object):

    def __init__(self):
        # following properties are used for the root element of the tree, others have to overwrite most of them
        self.ismodule = False # ???
        self.modulepart = "" # ??
        
        self.level = 0
        self.ischapter = 0

        # tree structure of TContent
        self.subcontents = [] # list of references to TContent objects
        self.parent = None
        self.root = None
        self.right = None # .next is special in python
        self.left = None
        self.xright = None
        self.xleft = None

        # content information
        self.xcontent = False
        self.helpsite = False
        self.testsite = False
        self.tocsymb = "?"
        self.title = "" # text of the html title tag
        self.modulid = ""

        # tree context information
        self.nr = 1
        self.pos = 0
        self.link = ""
        self.savepage = False
        self.menuitem = True
        self.display = False
        
        # other information
        self.exports = []
        self.docname = ""
        self.uxid = ""
        self.myid = 0 # .id is special in python, 0 is the id of the root element

        # at time of construction, this object is its own tree
        self.root = self


    # returns a string representation of the tree
    def __str__(self):
        return self._rstr(0)
        
    def _rstr(self, inset):
        s = ""
        i = 0
        while (i < inset):
            s = s + "    "
            i = i + 1
        s = s + self.title + "\n"
        for p in self.subcontents:
            s = s + p._rstr(inset + 1)
        return s
        