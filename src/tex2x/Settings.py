import sys, os
import settings as default_settings
from plugins.VEUNDMINT.Option import Option as VEUNDMINTOption
from types import ModuleType

class Settings(dict):
    
    #stores which settings in default_settings were overridden
    overridden = []

    #store the 'most recent' settings that means here everything is overridden
    #according to the settings hierarchy
    settings = {}

    #will store the settings of every installed plugin
    all_plugin_settings = {}

    #settings that were set in environment variables
    env_settings = {}

    #settings that were set on the command line
    command_line_settings = {}

    def __init__(self, plugin_settings=[], cl_settings={}, *args, **kwargs):
        
        super(Settings, self).__init__(*args, **kwargs)
        self.__dict__ = self
        
        self.all_plugin_settings = plugin_settings
        self.command_line_settings = cl_settings
        
        #load settings in reverse order, most imortant settings first. that makes sure that composite settings
        #that use other settings values get the correct value
        self.load_settings(self.command_line_settings)
        self.load_settings(self.get_env_settings())
        for plugin_settings in self.all_plugin_settings:
            self.load_settings(plugin_settings)
        self.load_settings(default_settings)

    def load_settings(self, custom_settings):
        """
        Loads settings from the supplied settings in custom_settings, which
        can either be an object instance or a dict.
        """

        if custom_settings is not None:
            print('loading custom settings %s', custom_settings)
            is_module = False
            
            #convert module instance to dict
            if isinstance(custom_settings, ModuleType) or isinstance(custom_settings, VEUNDMINTOption):
                loaded_settings = {k:v for k,v in custom_settings.__dict__.items() if not k.startswith("__") and not isinstance(v, ModuleType)}
                is_module = True
            elif (isinstance(custom_settings, dict)): 
                loaded_settings = custom_settings
            
            if isinstance(loaded_settings, dict):
                for setting in loaded_settings:
                    if hasattr(self, setting):
                        self.overridden.append(setting)
                        print('overriding %s', setting)
                        setattr(default_settings, setting, loaded_settings[setting])
                        if is_module:
                            print('found setting %s in module %s' % (setting, custom_settings))
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
        env_settings = {k.replace(prefix, ''): v for k,v in os.environ.items() if k.startswith(prefix)}
        print(env_settings)
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
