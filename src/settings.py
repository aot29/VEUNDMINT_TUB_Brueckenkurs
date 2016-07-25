import os
import logging

# The base directory of everything
BASE_DIR = os.path.dirname(os.path.dirname(__file__))

# The base url where the server will run - used for testing and configuration
BASE_URL = 'http://localhost:3000'

# Set the project wide log level (can be ovveridden in files)
LOG_LEVEL = logging.DEBUG

converterDir = 'defaultConverterDirSetting'


#####################
#### TTM Options ####
#####################

# The directory where the module's TeX files are located
module_tex = os.path.join(BASE_DIR, 'module_veundmint')

# The ttm binary file
ttmBin = os.path.join(BASE_DIR, 'src/ttm/ttm')

# The directory ttm will look for TeX Files ?
sourceTEX = os.path.join(BASE_DIR, 'src/tex')

# The TeX file ttm will start parsing with
sourceTEXStartFile = os.path.join(module_tex, 'tree_tu9onlinekurs.tex')

# the file ttm will write its TeX parsing to (xml)
ttmFile = os.path.join(sourceTEX, 'ttm_output.xml')
