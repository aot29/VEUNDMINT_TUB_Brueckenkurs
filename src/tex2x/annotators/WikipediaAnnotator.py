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
from tex2x.annotators.AbstractAnnotator import *

class WikipediaAnnotator(AbstractAnnotator):
	'''
	Lists the Wikipedia entries in the STEM categories, in the chosen language.
	Use this to create external lists of links on each page.
	'''
	
	WP_MATH_CATEGORY = { 
					'de' : [
						"Mathematischer Grundbegriff", "Algebra", "Analysis", "Arithmetik", "Diskrete Mathematik", "Funktionentheorie", "Geometrie", 
						"Kategorientheorie", "Mathematische Logik", "Numerische Mathematik", "Ordnungstheorie", "Stochastik",
						"Theorie dynamischer Systeme", "Topologie", "Unterhaltungsmathematik", "Wirtschaftsmathematik", "Zahlentheorie"
					],
					'en' : [
						"Mathematical terminology", "Fields of mathematics", "Algebra‎", "Elementary algebra",
						"Mathematical analysis‎", "Applied mathematics‎", "Arithmetic‎", "Calculus", 
						"Combinatorics", "Computational mathematics", "Discrete mathematics", 
						"Dynamical systems", "Elementary mathematics‎", "Experimental mathematics", 
						"Foundations of mathematics", "Game theory", "Geometry", "Graph theory", 
						"Mathematical logic", "Mathematics of infinitesimals", "Number theory", 
						"Order theory", "Recreational mathematics‎", "Representation theory", "Topology"
						]
					}
	'''
	The category containing the math words in German and English
	'''
	
	WP_API_URL_TPL = "https://%s.wikipedia.org/w/api.php?action=query&list=categorymembers&cmlimit=500&cmprop=title&format=json&cmtitle=Category:%s"
	'''
	The URL to the Wikipedia API search category entry point, with placeholders for the language and the category
	'''

	WP_URL_TPL = "https://%s.wikipedia.org/wiki/%s"
	'''
	The URL to Wikipedia, with placeholders for the language and the page title
	'''
	
	WP_DISAMBIGUATION = { 'de' : ["(Mathematik)"], 'en' : ["(mathematics)", "(logic)"] }
	'''
	Strings used by Wikipedia for disambiguation. Have to be removed to serach for words in course pages
	'''
	
	def generate( self, lang ):
		"""
		List the entries of the maths category in Wikipedia
		
		@param lang - language code
		@return array of [word, Wikipedia lemma] items, e.g. ['Operator', 'Operator (Mathematik)']
		"""
		resp = []
		WpPages = self.loadCategoryPages( self.getCategoryNames(lang), lang )
		for pageName in WpPages:
			word = pageName
			# remove disambiguation terms from word
			for dis in WikipediaAnnotator.WP_DISAMBIGUATION[lang]:
				word = word.replace( dis, "")
			word = word.strip()
			
			# make a tuple containing the word, the Wikipedia page name and the complete URL
			resp.append( Annotation( word, pageName, self.getPageUrl(lang, pageName) ) )
			
		return resp
	

	def getCategoryNames(self, lang):
		"""
		The localized name of the category
		
		@param lang - language code (de or en)
		@return string - the name of a Wikipedia category
		"""
		return WikipediaAnnotator.WP_MATH_CATEGORY[lang]
	
	
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


