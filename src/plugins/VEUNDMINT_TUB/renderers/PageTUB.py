## @package plugins.VEUNDMINT_TUB.renderers.PageTUB
#  Render page by applying XSLT templates
#
#  \copyright tex2x converter - Processes tex-files in order to create various output formats via plugins
#  Copyright (C) 2014  VEMINT-Konsortium - http://www.vemint.de
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#  \author Alvaro Ortiz for TU Berlin
from lxml import etree
import os
import re
from tex2x.Settings import settings
from tex2x.AbstractRenderer import *
from .PageXmlRenderer import *

class PageTUB( AbstractHtmlRenderer ):
	"""
	Render page by applying XSLT templates, using the lxml library.
	"""

	## The template which includes all others
	BASE_TEMPLATE = "page.xslt"

	def __init__( self, contentRenderer, tocRenderer, data ):
		"""
		Constructor.
		Instantiated by PageFactory.

		@param contentRenderer - PageXmlRenderer an AbstractXMLRenderer that builds the page contents, including the questions and roulettes added by the decorators
		@param tocRenderer - TocRenderer an AbstractXMLRenderer that builds the table of contents
		@param data - simplify access to the interface data member (Daniel Haase)
		"""

		## @var contentRenderer
		#  PageXmlRenderer an AbstractXMLRenderer that builds the page contents, including the questions and roulettes added by the decorators
		self.contentRenderer = contentRenderer

		## @var tocRenderer
		#  TocRenderer an AbstractXMLRenderer that builds the table of contents
		self.tocRenderer = tocRenderer

		## @var data
		#  simplify access to the interface data member (Daniel Haase)
		self.data = data

		## @var tplPath
		#  tplPath - String path to the directory holding the xslt templates
		self.tplPath = settings.converterTemplates

		## @var disableLogin
		#  Boolean, whether to disable the login button. false=enabled (default), true = disabled.
		self.disableLogin = settings.disableLogin


	def renderHTML( self, tc ):
		"""
		Applies the template to the page data. The result is a HTML string which is stored in tc.html.

		@param tc - TContent object encapsulating the data for the page to be rendered
		"""

		# get the base path
		basePath = self.getBasePath(tc)

		# Create the XML output
		xml = self.contentRenderer.renderXML( tc )
		self.addFlags(xml, tc, basePath)

		# Prepare a non-special page, otherwise skip TOC and FF-RW links
		#if not ( AbstractXmlRenderer.isSpecialPage( tc ) or AbstractXmlRenderer.isTestPage( tc ) )  :
		#	# toc
		#	xml.append( self.tocRenderer.renderXML( tc ) )
		xml.append( self.tocRenderer.renderXML( tc ) )

		# add links to next and previous entries
		self._addPrevNextLinks(xml, tc, basePath)

		# add annotations (but only to content pages)
		if AbstractXmlRenderer.isCoursePage(tc):
			self._addAnnotations( xml, tc.annotations )

		# correct the links in content and TOC
		self.correctLinks( xml, basePath )

		# Load the template
		templatePath = os.path.join( settings.TEMPLATE_PATH, PageTUB.BASE_TEMPLATE )
		template = etree.parse( templatePath )

		# Apply the template
		transform = etree.XSLT( template )
		result = transform( xml )

		if AbstractXmlRenderer.isSpecialPage( tc ) and tc.uxid != 'VBKM_MISCSEARCH' :
			# Special pages are now generated from templates_xslt
			self.loadSpecialPage( tc )

		# Prepare content which is stored in tc.content (change paths etc.)
		self.prepareContent( tc, basePath )

		# Replace the content placeholder added in PageXmlRenderer with the actual (not necessarily XML-valid) HTML content
		resultString = str( result )
		tc.html = resultString.replace( '<content></content>', tc.content )

		# move this to a better place
		def dhtml(m):
			pos = int(m.group(1))
			#if 'DirectHTML' in self.data and pos in self.data['DirectHTML']:
			return self.data['DirectHTML'][pos]
		tc.html = re.sub(r"\<!-- directhtml;;(.+?); //--\>", dhtml, tc.html, 0, re.S)


	def addFlags(self, xml, tc, basePath):
		"""
		Add the attributes of the page element. These are used for rendering.

		@param xml - etree holding the page
		@param tc - TContent object for the page
		@param basePath - String prefix for all links
		"""
		# add base path to XML, as the transformer doesn't seem to support parameter passing
		xml.set( 'basePath', basePath )

		# flag test pages
		xml.set( 'isTest', str( tc.testsite ).lower() ) # JS booleans are lowercase

		# flag the course pages
		xml.set( 'isCoursePage', str( AbstractXmlRenderer.isCoursePage(tc) ) )
		xml.set( 'isSpecialPage', str( AbstractXmlRenderer.isSpecialPage(tc) ) )
		xml.set( 'isInfoPage', str( AbstractXmlRenderer.isInfoPage(tc) ) )
		xml.set( 'isTestPage', str( AbstractXmlRenderer.isTestPage(tc) ) )
		xml.set( 'requestLogout', str( AbstractXmlRenderer.isLogoutPage(tc) ).lower() )

		# disable the login button?
		xml.set( 'disableLogin', str( self.disableLogin ) )


	def loadSpecialPage(self, tc):
		"""
		Load a special page. Special pages are listed in AbstractRenderer.specialPagesUXID,
		e.g. data, signup, login, logout, search, favorites

		@param tc - TContent object for the page
		"""
		if tc.uxid not in AbstractXmlRenderer.specialPagesUXID.keys():
			raise Exception( "This does not seem to be a special page: %" % tc.uxid )

		pageContentPath = os.path.join( settings.TEMPLATE_PATH, "%s.xml" % AbstractXmlRenderer.specialPagesUXID[ tc.uxid ] )
		parser = etree.XMLParser(remove_blank_text=True)
		tree = etree.parse(pageContentPath, parser)
		tc.content = etree.tostring( tree ).decode("utf-8")


	def prepareContent(self, tc, basePath):
		"""
		TTM produces non-valid HTML, so it has to be added after XML has been parsed.
		Don't use tidy on the whole page, as tidy version 1 drops MathML elements (among other)
		Note: string replace is faster than regex

		@param tc - TContent object for the page
		@param basePath - String prefix for all links
		"""
		# Reduce the number of breaks and clear=all's, since they mess-up the layout
		breakStr = '<br style="margin-bottom: 2em" />'
		tc.content = tc.content.replace( '<br/> <br/>', breakStr )
		tc.content = tc.content.replace( '<br clear="all"/><br clear="all"/>', breakStr )
		tc.content = tc.content.replace( '<br clear="all"></br>\n<br clear="all"></br>', breakStr )
		tc.content = tc.content.replace( '\t', ' ' )
		tc.content = tc.content.replace( '\n', ' ' )
		# make sure punctuation flow is rendered correctly in exercises and equations
		tc.content = tc.content.replace( '%s .<br/>' % breakStr, '.<br/>' )
		tc.content = tc.content.replace( '%s . %s' % (breakStr, breakStr), '.<br/>' )
		tc.content = tc.content.replace( '%s .  %s' % (breakStr, breakStr), '.<br/>' )
		tc.content = tc.content.replace( '%s , %s' % (breakStr, breakStr), ',<br/>' )

		tc.content = tc.content.replace( '<a class="MINTERLINK" href="', '<a class="MINTERLINK" href="%s/' % basePath )

		# if this is a special page, replace the title by i18n entry
		if AbstractXmlRenderer.isSpecialPage(tc) or AbstractXmlRenderer.isTestPage(tc):
			tc.content = re.sub( r"<h4>(.+?)</h4><h4>(.+?)</h4>", "<h1 id='pageTitle' data-toggle='i18n' data-i18n='%s' ></h1>" % tc.uxid, tc.content )

		#if this is not a special page, apply some layout
		if not ( AbstractXmlRenderer.isSpecialPage(tc) or AbstractXmlRenderer.isTestPage(tc) ):
			tc.content = re.sub( r"<h4>(.+?) - (.+?)</h4><h4>(.+?)</h4>", r"<h4><div class='label label-default'>\1</div></h4><strong>\2</strong><h1>\3</h1>", tc.content )


	def getBasePath(self, tc):
		"""
		Set base path to point up from the level of the current tc object

		@param tc - TContent object encapsulating the data for the page to be rendered
		"""
		basePath = ".."

		if AbstractXmlRenderer.isSpecialPage( tc ):
			return basePath

		if tc.level == ROOT_LEVEL:
			basePath = ".."
		if tc.level == MODULE_LEVEL:
			basePath = ".."
		if tc.level == SECTION_LEVEL:
			basePath = "../.."
		if tc.level == SUBSECTION_LEVEL:
			basePath = "../.."

		return basePath


	def _addPrevNextLinks(self, page, tc, basePath=''):
		"""
		Add links to previous and next pages

		@param page - etree Element holding content and TOC
		@param tc - a TContent object encapsulating page data and content
		@param basePath - String prefix for all links
		"""
		navPrev = tc.left
		if navPrev is None:
			navPrev = tc.xleft
		if navPrev is not None:
			navPrevEl = etree.Element( "navPrev" )
			navPrevEl.set( "href", os.path.join(basePath, navPrev.fullname ) )
			page.append( navPrevEl )

		navNext = tc.right
		if navNext is None:
			navNext = tc.xright
		if navNext is not None:
			navNextEl = etree.Element( "navNext" )
			navNextEl.set( "href", os.path.join(basePath, navNext.fullname ) )
			page.append( navNextEl )


	def _addAnnotations( self, xml, annotations ):
		"""
		Add annotations
		@param xml - etree Element holding content and TOC
		@param annotations - an array of Annotation objects
		"""
		annotationsEl = etree.Element( "annotations" )
		for annotation in annotations:
			annotationsEl.append( annotation.toEtree() )
		if len(annotationsEl) > 0 :
			xml.append( annotationsEl )
