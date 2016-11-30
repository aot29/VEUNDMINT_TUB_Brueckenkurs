import sys, os
from plugins.VEUNDMINT.Option import Option as VEUNDMINTOption
from types import ModuleType
import inspect

class Settings(dict):
    
    _instance = None
    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super(Settings, cls).__new__(
                                cls, *args, **kwargs)
        return cls._instance
    
    def __getattr__(self, key):
        """
        Override the getattr function to return the already set values if they exist
        in the instance, otherwise return the attr from the calling module
        """
        frm = inspect.stack()[1]
        mod = inspect.getmodule(frm[0])
        
        default = mod.__dict__.get(key, '')
        
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

    #settings that were set on the command line
    command_line_settings = {}

    def __init__(self, cl_settings={}, *args, **kwargs):
        
        #print('init called with settings %s , %s, %s' % (default_settings, plugin_settings, cl_settings))
        
        self.__dict__ = self
        
        self.command_line_settings = cl_settings
        
        #load command line settings first and then the environment settings
        #other settings must be loaded via load_settings in some main module (currently tex2x.py)
        self.load_settings(self.command_line_settings)
        self.load_settings(self.get_env_settings())


    def load_settings(self, custom_settings):
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
                    if self.get(setting) is None:
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


class SettingsMixin(Settings):
    """
    Mixin to allow easier access to setting values. If we inherit from SettingsMixin,
    it is possible to do x = MY_SETTING_KEY instead of x = settings.MY_SETTING_KEY
    """
    pass


#settings = Settings()

## for convenience an VEUNDMINT-Option settings is supplied
#import argparse
#parser = argparse.ArgumentParser(description='tex2x converter')
#parser.add_argument("--plugin", help="specify the plugin you want to run")
#parser.add_argument("-v", "--verbose", help="increases verbosity", action="store_true")
#parser.add_argument("override", help = "override option values ", nargs = "*", type = str, metavar = "option=value")
#args = parser.parse_args()

#ve_settings = Settings(VEUNDMINTOption('', args.override))
