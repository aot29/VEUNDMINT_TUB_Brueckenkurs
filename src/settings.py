import os
import logging
import platform

## The base directory of everything
BASE_DIR = os.path.dirname(os.path.dirname(__file__))

## The base url where the server will run - used for testing and configuration
BASE_URL = 'http://guest43.mulf.tu-berlin.de/gitlab-ci-test'

## Set the project wide log level (can be overridden in files)
LOG_LEVEL = logging.DEBUG

currentDir = BASE_DIR
converterDir = os.path.join( currentDir, "src" )


#####################
#### TTM Options ####
#####################

# The directory where the module's TeX files are located
module_tex = os.path.join(BASE_DIR, 'module_veundmint')

## The ttm binary file
ttmBin = os.path.join(BASE_DIR, 'src/ttm/ttm_osx') if platform.system() == 'Darwin' else os.path.join(BASE_DIR, 'src/ttm/ttm')

## The directory ttm will look for TeX Files ?
sourceTEX = os.path.join(BASE_DIR, 'src/tex')

## The TeX file ttm will start parsing with
sourceTEXStartFile = os.path.join(module_tex, 'tree_tu9onlinekurs.tex')

## the file ttm will write its TeX parsing to (xml)
ttmFile = os.path.join(sourceTEX, 'ttm_output.xml')

#########################
#### Testing Options ####
#########################

scorm2004testurl = BASE_URL + '/scorm2004testwrap.htm'

#####################################
#### Dispatcher default settings ####
#####################################

##  Pipeline lists the steps in the dispatcher.
## The default plugin is in: plugins/basic
#  1. Preprocessors: Run pre-processing plugins
#  2. Translator: Run TTM (convert Tex to XML), load XML file created by TTM, 
#  3. Parser: Parse XML files into a HTML tree
#  4. Generator: Create the table of contents (TOC) and content tree, correct links
#  5. Plugins: Output to static HTML files
#
#  Steps 1 and 5 may have multiple classes.
#  Steps 2,3,4 may be decorated.
#
# Put the complete class path here, so for example:
# if you have a plugin called VEUNDMINT and a file called preprocessor_mintmodtex.py which holds a class called Preprocessor,
# then the path is plugins.VEUNDMINT.preprocessor_mintmodtex.Preprocessor.
pipeline = {
		"preprocessors": [ 'plugins.basic.preprocessing.BasicPreprocessor' ],
		
		"translator": None,

		"translatorDecorators": None,
		
		"parser": None,

		"parserDecorators": [],
		
		"generator": None,

		"generatorDecorators": None,
		
		"plugins": [ 'plugins.basic.basic.Plugin' ]
	}
