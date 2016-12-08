"""
	tex2x converter - Processes tex-files in order to create various output formats via plugins
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
	
	@author Alvaro Ortiz for TU Berlin
"""
import requests
import json
import os
from tex2x.annotators.AbstractAnnotator import *
import settings

class WikipediaAnnotator(AbstractAnnotator):
	'''
	Lists the Wikipedia entries in the STEM categories, in the chosen language.
	Use this to create external lists of links on each page.
	'''
	
	WP_MATH_CATEGORIES = "WikipediaCategories.json"
	'''
	Path to the json file containing containing Wikipedia categories to scan for math words in German and English
	'''
	
	WP_API_URL_TPL = "https://%s.wikipedia.org/w/api.php?action=query&list=categorymembers&cmlimit=500&cmprop=title&format=json&cmtitle=Category:%s"
	'''
	The URL to the Wikipedia API search category entry point, with placeholders for the language and the category
	'''

	WP_URL_TPL = "https://%s.wikipedia.org/wiki/%s"
	'''
	The URL to Wikipedia, with placeholders for the language and the page title
	'''
	
	WP_DISAMBIGUATION = { 'de' : ["Mathematik", "Geometrie"], 'en' : ["mathematics", "logic"] }
	'''
	Strings used by Wikipedia for disambiguation. Have to be removed to search for words in course pages
	'''
	
	WP_BLACKLIST = { 'de' : [ "NaN", "Zahl", "Weg", "Bild", "Funktion", "Term", "Ebene", "Norm", "Ecke", "Mathematik" ], 'en' : ["Function", "Map", "Norm","Sign", "Mathematics"] }
	'''
	Strings to be filtered from matches, mostly because they keep popping-up on most pages
	'''
	
	def generate( self, lang ):
		"""
		List the entries of the maths category in Wikipedia
		
		@param lang - language code
		@return array of [word, Wikipedia lemma] items, e.g. ['Operator', 'Operator (Mathematik)']
		"""
		resp = []
		WpPages = self.loadCategoryPages( self.loadCategoryNames(lang), lang )
		for pageName in WpPages:
			word = pageName
			# remove disambiguation terms from word
			for dis in WikipediaAnnotator.WP_DISAMBIGUATION[lang]:
				word = word.replace( "(%s)" % dis, "")
			word = word.strip()
			
			# ignore blacklisted words
			if word in WikipediaAnnotator.WP_BLACKLIST[lang]: continue
			
			# make a tuple containing the word, the Wikipedia page name and the complete URL
			resp.append( Annotation( word, pageName, self.getPageUrl(lang, pageName) ) )
			
		return resp
	

	def loadCategoryNames(self, lang):
		"""
		Load the json files with the Wikipedia categories.
		Return the localized names of the categories
		
		@param lang - language code (de or en)
		@return list<string> - the names of the Wikipedia categories
		"""
		categories = []
		with open( os.path.join( settings.BASE_DIR, "src", "tex2x", "annotators", WikipediaAnnotator.WP_MATH_CATEGORIES ) ) as file:
			strings = json.load( file )
			categories = strings["mathematics"][lang]
			
		return categories
	
	
	def getApiUrl(self, lang, pageTitle):
		"""
		The URL of the API of Wikipedia in the given language
		
		@param lang - language code (de or en)
		@return string - URL a the corresponding Wikipedia API entry point
		"""
		return WikipediaAnnotator.WP_API_URL_TPL % ( lang, pageTitle )


	def getPageUrl(self, lang, pageTitle):
		"""
		The URL of the Wikipedia human-readable page in the given language
		@param lang - language code (de or en)
		@return string - URL
		"""
		return WikipediaAnnotator.WP_URL_TPL % ( lang, pageTitle )
		
	
	def loadCategoryPages(self, pages, lang):
		"""
		Load a page from a public wiki using the Mediawiki API
		
		@param pages -- array of titles of wiki category pages
		@return array of Wikipedia page names
		"""
		lemmata = []
		for pageTitle in pages:
			# Read a page
			url = self.getApiUrl(lang, pageTitle)
			r1 = requests.post( url, data=None, cookies=None )
			
			# Check http status
			self.checkRequest( r1, url )
			
			for item in r1.json()['query']['categorymembers']:
				# skip category names
				if 'Category' in item['title']: continue
				lemmata.append( item['title'] )
		# remove duplicates
		lemmata = list( set( lemmata ))
		# sort
		lemmata.sort()
		# return content
		return lemmata


	def checkRequest(self, response, url ):
		"""
		Check if a http request was successful, throw an exception otherwise
		"""
		# Check http status
		if response.status_code != 200: raise Exception( 'Failed request url %s status %d' % ( url, response.status_code) )
		#Check response code
		if 'error' in response.json(): raise Exception( 'Failed request %s : %s' % ( url, response.json()['error']['info'] ) )


