#import logging
#import settings

#logging.basicConfig(filename='tex2x.log', level=settings.LOG_LEVEL, format='%(asctime)s %(message)s')

class Singleton(type):
    _instances = {}
    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super(Singleton, cls).__call__(*args, **kwargs)
        return cls._instances[cls]