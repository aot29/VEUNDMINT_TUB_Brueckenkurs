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
from tex2x.dispatcher.runners import AbstractRunner

class PluginRunner( AbstractRunner ):
	'''
	Run LinkerRunner.
	Can be decorated with VerboseDecorator to enable performance loging.
	'''
	def __init__(self, data, content, tocxml, requiredImages, plugins):
		'''
		@param content - a list of [toc_node, content_node] items
		'''
		self.data = data
		self.content = content
		self.tocxml = tocxml
		self.requiredImages = requiredImages
		self.plugins = plugins		


	def run(self):
		"""
		Loads all plugins are runs them
		
		@author Daniel Haase
		"""

		self.data['content'] = self.content
		self.data['tocxml'] = self.tocxml
		self.data['required_images'] = self.requiredImages

		#reset data
		self.content = None
		self.tocxml = None
		self.required_images = None

		#activate pre-processing from plugins
		for op in self.plugins:
			op.create_output()

