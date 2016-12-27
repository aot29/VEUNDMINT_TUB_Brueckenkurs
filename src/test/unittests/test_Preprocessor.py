'''
Created on Dec. 26, 2016

Activate Python venv if necessary, then run with:
> cd src
> python3 -m unittest test.unittests.test_Preprocessor.test_Preprocessor

@author: Alvaro Ortiz
'''
import os
import sys
import unittest
from tex2x.preprocessors.AbstractPreprocessor import *


class MockPreprocessor( AbstractPreprocessor ):
	def __init__(self):
		pass


class test_Preprocessor(unittest.TestCase):
	
	def setUp(self):
		self.preprocessor = MockPreprocessor()
		
		
	def testCreate(self):
		'''
		Check if a Preprocessor can be created at all
		'''
		self.assertIsNotNone( self.preprocessor )


	def testGetFileList(self):
		"""
		Check that the lsit of .tex files is generated
		"""
		fileList = self.preprocessor.getFileList()
		self.assertIsNotNone( fileList, "Could not get fileList" )
		fileList2 = self.preprocessor.getFileList()
		self.assertIs( fileList, fileList2, "fileList was generated twice" )
		
		