"""
	Copyright (C) 2014  VEMINT-Konsortium - http://www.vemint.de

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	@author Daniel Haase for KIT 
	@author Alvaro Ortiz for TU Berlin
"""
import os, subprocess, logging, re
import sys
from tex2x.Settings import Settings
from tex2x.Settings import ve_settings as settings
from tex2x.parsers.AbstractParser import AbstractParser

class MathMLDecorator( AbstractParser ):
	"""
	This class is meant to decorate TTMParser.
	Corrects MathML generated by TTM.
	Can be decorated with VerboseParser to enable performance loging.
	"""

	def __init__(self, parser, options ):
		"""
		@param parser - Parser (object extending AbstractParser, in this case TTMParser)
		"""
		self.parser = parser
		self.options = options


	def parse(self, *args, **kwargs):
		"""
		Executes a parser and then corrects the generated MathML
		Use with TTM to correct MathML which is generated from Tex files
		"""
		# call the decorated class' runner
		temp = self.parser.parse(*args, **kwargs)
		
		return self.optimizeMathML( temp )


	def optimizeMathML(self, xmltext):
		"""
		Optimiert MathML nachträglich weiter, nachdem der ttm es erzeugt hat.
		@author - Daniel Haase
		"""

		pattern = r"<mn>(?P<a>[0-9]*)</mn><mo>,</mo><mn>(?P<b>[0-9]*)</mn>"
		replace = r"<mn>\g<a>,\g<b></mn>"
		xmltext = re.sub(pattern, replace, xmltext)

		#xmltext = "<mn>1</mn><mo>,</mo><msup><mrow><mn>001</mn></mrow><mrow><mn>2</mn></mrow></msup>"

		pattern = r"<mn>(?P<a>[0-9]*)<\/mn><mo>,</mo>[\n|\r]*<msup><mrow><mn>(?P<b>[0-9]*)</mn></mrow><mrow><mn>(?P<c>[0-9])</mn></mrow>[\n|\r]*</msup>"
		replace = r"<msup><mrow><mn>\g<a>,\g<b></mn></mrow><mrow><mn>\g<c></mn></mrow>\n</msup>"
		xmltext = re.sub(pattern, replace, xmltext)

		#s/<mtable([^>]+)>/<mtable>/g;
		pattern = r"<mtable[^>]+>"
		replace = r"<mtable>"
		xmltext = re.sub(pattern, replace, xmltext)

		if not hasattr(self.options, "keepequationtables"): self.options.keepequationtables = 0
		if self.options.keepequationtables == 0:
			pattern = r"<table width=\"100%\"><tr><td align=\"center\">(?P<a>\s*(<math(.|\n)*?</math>)\s*)</td></tr></table>"
			replace = r"<center>\g<a></center>"
			xmltext = re.sub(pattern, replace, xmltext)

		"""Kein Effekt
		#Das Zeichen \subsetneq kennt ttm nicht
		pattern = r"\\subsetneq"
		replace = r"<mtext>&#8842;</mtext>"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]
		"""

		"""Kein Effekt
		#mathbb-Zeichen (Reals, Integers, usw)
		pattern = r"\\mathbb<mi>(?P<a>[A-Za-z])</mi>"
		replace = r"<mo>&\g<a>1opf;</mo>"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]
		"""

		#Ab hier werden übertrieben große Abstände verringert
		"""Kein Effekt
		pattern = r"<mi>&emsp;</mi>"
		replace = r"<mi>&nbsp;</mi>"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]
		"""
		"""Kein Effekt
		pattern = r"<mi>&emsp;&emsp;</mi>"
		replace = r"<mi>&nbsp;&nbsp;</mi>"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]
		"""

		pattern = r"<mi>&emsp;&emsp;&emsp;</mi>"
		replace = r"<mi>&nbsp;&nbsp;&nbsp;</mi>"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]

		pattern = r"<mi>&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;</mi>"
		replace = r"<mi>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</mi>"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]

		#\empty ist kein Integer, sondern Text
		pattern = r"<mi>&empty;</mi>"
		replace = r"<mtext>&empty;</mtext>"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]

		"""replacetd()-Fkt gibt es nicht.. vielleicht ist das hier auch inzwischen überflüssig. FF geht auch so, IE wird noch getestet
		#Bei Tabellen mit Rahmen sollen auch die Zellen Rahmen haben
		pattern = r"<table border=\"1\">((.|\s)*?)</table>"
		replace = r""#"r"replacetd($1)"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]
		"""

		#Probleme mit dem nicht-Teilbarkeitszeichen beheben
		pattern = r"&nmid;"
		replace = r"<mo>∤</mo>"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]


		#Probleme mit dem nicht-Orthogonalitätszeichen beheben
		pattern = r"</mi>\s*&nparallel;\s*<mi>"
		replace = r" ∦ "
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]

		#Probleme mit vertikalen Punkten beheben
		pattern = r"<mrow>:</mrow>"
		replace = r"<mo>&#8942;</mo>"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]

		#umgehe tex fehler in 5.2.1_grenzwertefunktionen.tex
		#TODO: Tex-Quelle reparieren
		pattern = r"<mstyle fontweight=\"bold\">h</mstyle>"
		replace = r"h"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]
		
		#Probleme Ableitungen 2. Grades beheben
		pattern = r"</mi>\"<mo stretchy"
		replace = r"</mi><mo>'</mo><mo>'</mo><mo stretchy"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]

		#Probleme Ableitungen 3. Grades beheben
		pattern = r"</mi>\"<mo>'</mo><mo stretchy"
		replace = r"</mi><mo>'</mo><mo>'</mo><mo>'</mo><mo stretchy"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]

		#Problem mit Ableitung 2. Grades ohne Klammern - wichtig darf erst nach der Behebung des Problems mit 3. Ableitung erfolgen
		pattern = r"<mi>f</mi>\""
		replace = r"<mi>f</mi><mo>'</mo><mo>'</mo>"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]

		#Problem mit Ableitung 2. Grades ohne Klammern - wichtig darf erst nach der Behebung des Problems mit 3. Ableitung erfolgen
		pattern = r"<mi>g</mi>\""
		replace = r"<mi>g</mi><mo>'</mo><mo>'</mo>"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]

		#4.2.1 Hinführung: Kästen werden nicht richtig dargestellt
		pattern = r"&square;"
		replace = r"<mo>□</mo>"
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]

		#4.3.6 Hinführung: a''
		pattern = r"<mrow>\"</mrow>"
		replace = r'<mrow><mi>"</mi></mrow>'
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]

		#5.4.2-24 ä wird vom ttm als Operator interpretiert
		pattern = r"</mi>&#228;<mi fontstyle=\"italic\">"
		replace = r'&#228;'
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]

		#5.4.2-24 ö wird vom ttm als Operator interpretiert
		pattern = r"</mi>&#246;<mi fontstyle=\"italic\">"
		replace = r'&#246;'
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]

		#7.1.2 - ∦ wird nicht als "Operator" erkannt
		"""
		pattern = r"∦"
		replace = r'<mo>∦</mo>'
		t = re.subn(pattern, replace, xmltext)
		xmltext = t[0]
		"""
		#Diese Zeile kann nach dem Ersetzen genutzt werden, um mitgeteilt zu bekommen, wie viele Ersetzungen stattfanden
		#print("##########zahl: " + str(t[1]))

		return xmltext;				