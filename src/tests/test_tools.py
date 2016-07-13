import os
from os.path import dirname

def getBaseDirectory():
    '''Gets the base directory of the repository'''
    return dirname(dirname(dirname(os.path.realpath(__file__))))
