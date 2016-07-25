import sys
import settings as global_settings
from plugins.VEUNDMINT.Option import Option as VEUNDMINTOption

class Settings(object):

    def __init__(self, custom_settings=None, *args, **kwargs):

        self.overridden = []

        self.load_settings(global_settings)

        #overwrite global settings with custom settings if they were supplied
        self.load_settings(custom_settings)

    def load_settings(self, custom_settings):
        """
        Loads settings from the supplied instance attributes of custom_settings
        """
        if custom_settings is not None:
            for setting in custom_settings.__dict__:
                if hasattr(self, setting):
                    self.overridden.append(setting)
                setattr(self, setting, getattr(custom_settings, setting))

    def is_overridden(self, attribute_name=None):
        """
        Checks if a setting value has been overridden by another loaded setting
        """
        if attribute_name is not None:
            return attribute_name in self.overridden

class SettingsMixin(Settings):
    """
    Mixin to allow easier access to setting values. If we inherit from SettingsMixin,
    it is possible to do x = MY_SETTING_KEY instead of x = settings.MY_SETTING_KEY
    """
    pass


settings = Settings()

# for convenience an VEUNDMINT-Option settings is supplied
import argparse
parser = argparse.ArgumentParser(description='tex2x converter')
parser.add_argument("plugin", help="specify the plugin you want to run")
parser.add_argument("-v", "--verbose", help="increases verbosity", action="store_true")
parser.add_argument("override", help = "override option values ", nargs = "*", type = str, metavar = "option=value")
args = parser.parse_args()
print (args.override)
ve_settings = Settings(VEUNDMINTOption('',args.override))
