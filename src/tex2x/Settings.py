import sys, os
from plugins.VEUNDMINT.Option import Option as VEUNDMINTOption
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
        
        if self.get_command_line_args() is not None:
            self.load_settings(dict(k.split('=') for k in self.get_command_line_args().override))
        
        self.load_settings(self.get_env_settings())
        
        import settings as default_settings
        self.load_settings(default_settings)

        #TODO loads the veundmint plugin options per default, this should be refactored later
        from plugins.VEUNDMINT.Option import Option as VEUNDMINTOption
        if self.get_command_line_args() is not None:
            self.load_settings(VEUNDMINTOption('', self.get_command_line_args().override))
        else:
            self.load_settings(VEUNDMINTOption('', ''))
        

    def load_settings(self, custom_settings, override=False):
        """
        Loads settings from the supplied settings in custom_settings, which
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
    
    def to_javascript_settings(self):
        """
        Return a json String that can be used to export all values of the settings to javascript
        A new dict is constructed because of an NotSerializable error
        """
        d = dict()
        for k,v in self.items():
            if isinstance(v, (str, int, float, dict, list)):
                d[k] = v
        return json.dumps(d, indent=4)

settings = Settings()