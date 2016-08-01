'''
Created on Jul 29, 2016

@author: ortiz
'''

class AbstractPage(object):
    '''
    Base class for any Page object. Exposes an interface common to all Page objects.
    Please program to interface whenever possible (aka "programming by contract") to reduce coupling.
    '''

    def generateHTML(self, tc):
        '''
        Generates a HTML page as a string using loaded templates and the given TContent object
        '''
        raise NotImplementedError