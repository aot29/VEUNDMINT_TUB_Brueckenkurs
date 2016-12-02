class AbstractPlugin(object):
	def create_output(self):
		raise NotImplementedError

class PluginException(Exception):
    """
    Plugin Exception class
    """

    def __init__(self, message):
        self.message = "Plugin exception: " + message
