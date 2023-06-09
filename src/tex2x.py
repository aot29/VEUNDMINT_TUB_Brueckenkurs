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

	@author - Daniel Haase for KIT
	@author Alvaro Ortiz for TU Berlin
"""
import os
from tex2x.Settings import settings
from tex2x.dispatcher.Dispatcher import Dispatcher
from tex2x.dispatcher.AbstractDispatcher import VerboseDispatcher
import argparse
import traceback

try:
	parser = argparse.ArgumentParser(description='tex2x converter')
	parser.add_argument("plugin", help="specify the plugin you want to run")
	parser.add_argument("-v", "--verbose", help="increases verbosity", action="store_true")
	parser.add_argument("override", help = "override option values ", nargs = "*", type = str, metavar = "option=value")
	args = parser.parse_args()

	if (os.path.abspath(os.getcwd()) != os.path.abspath(os.path.dirname(__file__))):
	    raise Exception("tex2x must be called in its own directory")

	settings.to_javascript_settings(settings.JS_SETTINGS_FILE)
	# #create dispatcher and start processing
	dispatcher = Dispatcher(args.verbose, args.plugin, args.override )
	if args.verbose: dispatcher = VerboseDispatcher( dispatcher, "Total duration of conversion" )
	dispatcher.dispatch()
	#
	# create a dispatcher for all languages
	# if (settings.languages is 'all'):
	# 	print ('going for all languages')
	# 	language_dirs = [name for name in os.listdir("./content_submodule") if os.path.isdir(os.path.join('./content_submodule',name)) and len(name) is 2]
	# 	print(language_dirs)
	# 	for language_dir in language_dirs:
	# 		dispatcher = Dispatcher(args.verbose, args.plugin, "lang=%s" % language_dir)
	# 		if args.verbose: dispatcher = VerboseDispatcher( dispatcher, "Total duration of conversion" )
	# 		dispatcher.dispatch()
	# elif (isinstance (settings.languages, list)):
	# 	print('going for %s languages' % settings.languages)
	# else:
	# 	print('going for the 1 language %s' % settings.languages)

except Exception:
	# Handle exceptions at the highest level, not in the classes
	print(traceback.format_exc())
