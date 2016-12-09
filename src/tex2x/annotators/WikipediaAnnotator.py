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
import re

class WikipediaAnnotator(AbstractAnnotator):
	'''
	Lists the Wikipedia entries in the STEM categories, in the chosen language.
	Use this to create external lists of links on each page.
	'''
	
	WP_CATEGORIES_PATH = "WikipediaCategories.json"
	'''
	Path to the json file containing containing Wikipedia categories to scan for math words in German and English
	'''
	
	WP_API_URL_TPL = "https://%s.wikipedia.org/w/api.php?action=query&list=categorymembers&cmlimit=500&cmprop=title&format=json&cmtitle=Category:%s"
	'''
	The URL to the Wikipedia API search category entry point, with placeholders for the language and the category
	'''

	WP_URL_TPL = "https://%s.wikipedia.org/wiki/%s"
	'''
	The URL to Wikipedia human-readable pages, with placeholders for the language and the page title
	'''

	WP_MIN_LENGTH = 3
	'''
	Words shorter than this will be ignored
	'''
	
	MAX_ATTEMPTS = 3
	'''
	Max number of attempts to load a page from Wikipedia
	'''
	
	def generate( self, lang ):
		"""
		List the entries of the maths category in Wikipedia
		
		@param lang - language code
		@return array of [word, Wikipedia lemma] items, e.g. ['Operator', 'Operator (Mathematik)']
		"""
		resp = []
		
		# Load the json files containing the desired categories and blacklists
		categoryNames, blacklist = self.loadCategoryNames(lang)
		wpPages = self.loadCategoryPages(categoryNames , lang )

		# the regex pattern used for each page, see below
		disambiguationPattern = re.compile('(.+?)\(.+?\)')
		
		for pageName in wpPages:
			word = pageName
						
			# remove disambiguation terms from word, e.g. (mathematics) or (logic)
			matches = re.search(disambiguationPattern, word)
			if matches: word = matches.group(1).strip()				
			
			# ignore short words, as otherwise there are too many false positives
			if len(word) <= WikipediaAnnotator.WP_MIN_LENGTH: continue
			
			# ignore blacklisted words
			if word in blacklist: continue
			
			# make a tuple containing the word, the Wikipedia page name and the complete URL
			resp.append( Annotation( word, pageName, self.getPageUrl(lang, pageName) ) )
			
		return resp
			

	def loadCategoryNames(self, lang):
		"""
		Load the json files with the Wikipedia categories.
		Return the localized names of the categories
		
		@param lang - language code (de or en)
		@return list<string> - the names of the Wikipedia categories, list<string> - list of words to exclude
		"""
		categories = []
		blacklist = []
		with open( os.path.join( settings.BASE_DIR, "src", "tex2x", "annotators", WikipediaAnnotator.WP_CATEGORIES_PATH ) ) as file:
			strings = json.load( file )
			
			# Wikipedia categories to scan for potential links from course pages
			categories = strings["mathematics"][lang]["categories"]
		
			# 	Strings to be filtered from matches, mostly because they keep popping-up on most pages
			blacklist = strings["mathematics"][lang]["blacklist"]
		
		return categories, blacklist
	
	
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

			attempts = 0
			while attempts < WikipediaAnnotator.MAX_ATTEMPTS:
				# try to connect with the Wikipedia API, give up after MAX_ATTEMPTS
				try:
					# send request
					r1 = requests.post( url, data=None, cookies=None )
					# Check http status
					self.checkRequest( r1, url )
					break
				except:
					attemps += 1
			
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
		

	def checkRequest(self, response, url ):
		"""
		Check if a http request was successful, throw an exception otherwise
		"""
		# Check http status
		if response.status_code != 200: raise Exception( 'Failed request url %s status %d' % ( url, response.status_code) )
		#Check response code
		if 'error' in response.json(): raise Exception( 'Failed request %s : %s' % ( url, response.json()['error']['info'] ) )


