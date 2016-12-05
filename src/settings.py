import os
import logging
import platform
from tex2x.Settings import Settings as s

# The base directory of everything
BASE_DIR = os.path.dirname(os.path.dirname(__file__))

# The source directory (usually a subdirectory of BASE_DIR)
SRC_DIR = os.path.join(s().BASE_DIR, 'src')

# The base url where the server will run - used for testing and configuration
BASE_URL = 'https://guest6.mulf.tu-berlin.de/gitlab-ci-test'

# Set the project wide log level (can be overridden in files)
LOG_LEVEL = logging.DEBUG

converterDir = 'defaultConverterDirSetting'

# The language that is used per default
lang = 'de'

# The temporary directory for all converter output
outtmp = '_tmp'

##########################
#### Server Options   ####
##########################

# The url where the django server runs
DJANGO_SERVER_URL = 'http://localhost:8000'


##########################
#### Renderer Options ####
##########################

TEMPLATE_PATH = os.path.join(s().BASE_DIR, 'src/templates_xslt')

#####################
#### TTM Options ####
#####################

# The directory where the module's TeX files are located
#module_tex = os.path.join(s().BASE_DIR, 'module_veundmint')

# The ttm binary file
ttmBin = os.path.join(s().BASE_DIR, 'src/ttm/ttm_osx') if platform.system() == 'Darwin' else os.path.join(s().BASE_DIR, 'src/ttm/ttm')

# The directory ttm will look for TeX Files ?
# sourceTEX = os.path.join(s().BASE_DIR, 'src/tex')

# The TeX file ttm will start parsing with
#sourceTEXStartFile = os.path.join(s().module_tex, 'tree_tu9onlinekurs.tex')


sourceTEX = os.path.join(s().BASE_DIR, s().outtmp , "tex") # Teilpfad in dem die LaTeX-Quellenkopien liegen

TTM_TREE = ( lambda lang: "tree_en.tex" if lang == 'en' else "tree_de.tex" ) (s().lang)

sourceTEXStartFile = os.path.join(s().sourceTEX, s().TTM_TREE)


# the file ttm will write its TeX parsing to (xml)
#ttmFile = os.path.join(s().sourceTEX, 'ttm_output.xml')

############################
#### Javascript Options ####
############################

JS_SETTINGS_FILE = os.path.join(s().SRC_DIR, 'files', 'js', 'settings.json')



#########################
#### Testing Options ####
#########################

scorm2004testurl = s().BASE_URL + '/scorm2004testwrap.htm'
