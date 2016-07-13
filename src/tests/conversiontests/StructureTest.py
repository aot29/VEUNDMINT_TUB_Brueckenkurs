import unittest
import imp
import os
import sys
import logging
from tex2xStruct.structure import Structure
from tests.test_tools import getBaseDirectory

logging.basicConfig(level=logging.DEBUG)

class StructureTest(unittest.TestCase):

    def setUp(self):
        self.log = logging.getLogger('test_structure_logger')

        plugin_name = 'VEUNDMINT'

        self.struct = Structure()
        self.struct.interface = dict()
        self.struct.options = dict()

        # load options <- not failsafe
        options_file = "Option.py"
        module = imp.load_source(plugin_name, os.path.join(getBaseDirectory(), "src/plugins", plugin_name, options_file))
        self.struct.interface['options'] = module.Option(getBaseDirectory(), '')

        #load system <- not failsafe
        module = imp.load_source(plugin_name, os.path.join(getBaseDirectory(), "src/plugins", plugin_name, "system.py"))
        self.struct.interface['system'] = module.System(self.struct.interface['options'])

        self.struct.options = self.struct.interface['options']
        self.struct.sys = self.struct.interface['system']


    def testStartTtm(self):
        '''Tests the xml generation method in Structure:start_ttm'''

        #create directories if not exist
        self.struct.sys.makePath(os.path.join(getBaseDirectory(), '_tmp/tex'))

        self.struct.options.ttmFile = os.path.join(self.struct.options.sourcepath,"test_ttm.xml")

        #will call self.struct.start_ttm() after xml generation
        self.struct.prepare_xml_file()
        self.assertTrue(os.path.exists(self.struct.options.ttmFile))

        #test a little for content correctness
        #TODO where is defined what tex files get included?
        tex_directories = [x[0] for x in os.walk(self.struct.options.sourcepath) if 'VBKM' in x[0]]
        self.log.debug(tex_directories)

    def testOptimizeMathml(self):
        self.assertRaises(TypeError, lambda _: self.struct.optimize_mathml(None))

    def testGetRequiredImages(self):
        pass
        # /media/VE/_tmp/tex/targetxml.xml

    def testGetRequiredImagesNone(self):
        self.assertRaises(TypeError, lambda _: Structure().get_required_images(None))

    def testcreateTocAndDisectContent(self):
        pass
        # s = Structure()
        #
        # # fake the functionality of Structure::startTex2x
        # s.interface = dict()
        # s.options = dict()
        #
        # module = imp.load_source('VEUNDMIT', os.path.join("plugins", "VEUNDMINT", "Option.py"))
        # s.interface['options'] = module.Option('..', [])
        #
        # # simplify access
        # s.options = s.interface['options']
        #
        # s.content = None
        # s.create_toc_and_disect_content()
        # print (s.content)

def suite():
    suite = unittest.makeSuite(StructureTest)
    return suite

if __name__ == '__main__':
    runner = unittest.TextTestRunner(verbosity=3)
    test_suite = suite()
    runner.run (test_suite)
