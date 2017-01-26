import sys, os
from plugins.VEUNDMINT_TUB.Option import Option as VEUNDMINTOption
from types import ModuleType
import inspect
from tex2x import Singleton
import argparse
import json

class Settings(dict, metaclass=Singleton):

	def __getattr__(self, key):
		"""
		Override the getattr function to return the already set values if they exist
		in the instance, otherwise return the attr from the calling module
		"""
		frm = inspect.stack()[1]
		mod = inspect.getmodule(frm[0])

		if mod is not None:
			default = mod.__dict__.get(key, '')
		else:
			default = ''


		#if it is not set, default to the value in the calling module
		return self.settings.get(key, default)


	#stores which settings in default_settings were overridden
	overridden = []

	#store the 'most recent' settings that means here everything is overridden
	#according to the settings hierarchy
	settings = {}

	#store default settings from the module tex2x
	default_settings = {}

	#will store the settings of every installed plugin
	all_plugin_settings = {}

	#settings that were set in environment variables
	env_settings = {}

	def __init__(self, *args, **kwargs):

		#print('init called with settings %s , %s, %s' % (default_settings, plugin_settings, cl_settings))

		self.__dict__ = self

		# 1. load the command line settings
		if self.get_command_line_args() is not None:
			self.load_settings(dict(k.split('=') for k in self.get_command_line_args().override))

		# 2. load the environment settings (all ENV variables beginning with 'VE_')
		self.load_settings(self.get_env_settings())

		#TODO 3. load the plugin settings here

		# 4. load all the content settings
		import importlib.util
		repo_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
		content_dir = os.path.join(repo_root, 'content_submodule')
		spec = importlib.util.spec_from_file_location("settings", os.path.join(content_dir, 'settings.py'))
		settings_module = importlib.util.module_from_spec(spec)
		spec.loader.exec_module(settings_module)
		self.load_settings(settings_module, parent="content", verbose=True)

		# 5. load the default settings from settings.py
		import settings as default_settings
		self.load_settings(default_settings)

		#6. load the veundmint plugin options per default and transform them to settings
		#TODO this should be refactored later as we do not want any old Option.py anymore!
		from plugins.VEUNDMINT_TUB.Option import Option as VEUNDMINTOption
		if self.get_command_line_args() is not None:
			self.load_settings(VEUNDMINTOption('', self.get_command_line_args().override))
		else:
			self.load_settings(VEUNDMINTOption('', ''))


	def load_settings(self, custom_settings, parent=None, override=False, verbose=False):
		"""
		Loads settings from the supplied settings file in custom_settings, which
		can either be an object instance or a dict.
		"""

		if custom_settings is not None:

			is_module = False

			#convert module instance to dict
			if isinstance(custom_settings, ModuleType) or isinstance(custom_settings, VEUNDMINTOption):
				loaded_settings = {k:v for k,v in custom_settings.__dict__.items() if not k.startswith("__") and not isinstance(v, ModuleType)}
				is_module = True
			elif (isinstance(custom_settings, dict)):
				loaded_settings = custom_settings

			if isinstance(loaded_settings, dict):
				for setting in loaded_settings:
					if getattr(self, setting):
						if setting not in self.overridden:
							self.overridden.append(setting)
						if is_module:
							setattr(custom_settings, setting, self[setting])

					#do not override
					if (self.get(setting) is None) or override is True:
						self[setting] = loaded_settings[setting]
						if verbose:
							print ('setting %s: %s \n' % (setting,loaded_settings[setting]))


	def is_overridden(self, attribute_name=None):
		"""
		Checks if a setting value has been overridden by another loaded setting
		"""
		if attribute_name is not None:
			return attribute_name in self.overridden

	def get_env_settings(self, prefix='VE_'):
		"""
		Loads environment variables and considers all of them settings for our program
		if they start with the supplied prefix
		"""
		if self.env_settings:
			return self.env_settings
		else:
			env_settings = {k.replace(prefix, ''): v for k,v in os.environ.items() if k.startswith(prefix)}
			self.env_settings = env_settings
			return env_settings

	def get_command_line_args(self):
		"""
		Get the command line arguments that where used to call the python script (tex2x.py)
		"""
		args = None
		if 'tex2x' in sys.argv[0]:
			parser = argparse.ArgumentParser(description='tex2x converter')
			parser.add_argument("plugin", help="specify the plugin you want to run")
			parser.add_argument("-v", "--verbose", help="increases verbosity", action="store_true")
			parser.add_argument("override", help = "override option values ", nargs = "*", type = str, metavar = "option=value")
			args = parser.parse_args(sys.argv[1:])
		return args

	def to_json(self):
		"""
		Return a json String that can be used to export all values of the settings to javascript
		A new dict is constructed because of an NotSerializable error
		"""
		d = dict()
		for k,v in self.items():
			if isinstance(v, (str, int, float, dict, list)):
				d[k] = v
		return json.dumps(d, indent=4)

	def to_javascript_settings(self, path):
		"""
		Write the settings as a json string to the file defined by
		@param path - String of the path to write the settings to
		"""

		module_start = """(function (root, factory) {
	if (typeof define === 'function' && define.amd) {
		// AMD. Register as an anonymous module.
		define(['loglevel', 'XMLHttpRequest'], factory);
	} else if (typeof module === 'object' && module.exports) {
		// Node. Does not work with strict CommonJS, but
		// only CommonJS-like environments that support module.exports,
		// like Node.
		module.exports = factory(require('loglevel'), require('xmlhttprequest').XMLHttpRequest);
	} else {
		// Browser globals (root is window)
		root.veSettings = factory(root.log, root.XMLHttpRequest);
	}
}(this, function (log, XMLHttpRequest) {

  log.info('settings loaded');

  /*
  * Module veSettings
  *
  * This module is only responsible for loading the python settings
  * that were exported to a json file in tex2x.py and to make them
  * available with an easy call to veSettings.<setting_key>
  *
  */"""
		module_end = """  return settings;


}));"""

		if ((not os.path.exists(os.path.dirname(path))) and (os.path.dirname(path) != "")):
			os.makedirs(os.path.dirname(path))
		with open(path, "w", encoding = 'utf8') as file:
			file.write(module_start + "\n var settings = " + self.to_json() + ";\n" + module_end)

settings = Settings()
