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
# which currently fails with
# File "/Users/n/Sites/VEUNDMINT_TUB_Brueckenkurs/src/plugins/VEUNDMINT/Option.py", line 254, in __init__
#     with open(os.path.join(self.converterDir, "plugins", "VEUNDMINT", "colorset_blue.json")) as colorfile:
# FileNotFoundError: [Errno 2] No such file or directory: '/Users/n/Sites/VEUNDMINT_TUB_Brueckenkurs/src/src/plugins/VEUNDMINT/colorset_blue.json'
# might be related to the Constructor
ve_settings = Settings(VEUNDMINTOption('',[]))
