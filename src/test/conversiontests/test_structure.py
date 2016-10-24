import unittest
import imp
import os
import sys
import logging
import traceback
from tex2xStruct.structure import Structure

logging.basicConfig(level=logging.DEBUG)

class StructureTest(unittest.TestCase):
    pass

#     def setUp(self):
#         self.log = logging.getLogger('test_structure_logger')
#
#         plugin_name = 'VEUNDMINT'
#
#         self.struct = Structure()
#         self.struct.interface = dict()
#         self.struct.options = dict()
#         self.struct.interface['data'] = dict()
#
#         # load options <- not failsafe
#         options_file = "Option.py"
#         module = imp.load_source(plugin_name, os.path.join(getBaseDirectory(), "src/plugins", plugin_name, options_file))
#         self.struct.interface['options'] = module.Option(getBaseDirectory(), '')
#
#         self.struct.options = self.struct.interface['options']
#
#         #load system <- not failsafe
#         module = imp.load_source(plugin_name, os.path.join(getBaseDirectory(), "src/plugins", plugin_name, "system.py"))
#         self.struct.interface['system'] = module.System(self.struct.interface['options'])
#
#         try:
#             module = imp.load_source(plugin_name, os.path.join(getBaseDirectory(), "src/plugins", plugin_name, "system.py"))
#             self.struct.interface['system'] = module.System(self.struct.interface['options'])
#         except Exception:
#             formatted_lines = traceback.format_exc().splitlines()
#             if formatted_lines[-1].find("AttributeError: 'module' object has no attribute 'System'") < 0:
#                 print(traceback.format_exc())
#             else:
#                 print("\nCannot load System facility of plugin '" + plugin_name + "', using system from tex2x\n")
#
#             self.struct.interface['system'] = TSystem
#
#         self.struct.interface['preprocessor_plugins'] = []
#         module = imp.load_source(plugin_name + "_preprocessor_" + 'mintmodtex', os.path.join(self.struct.options.converterDir, "plugins", "VEUNDMINT", "preprocessor_mintmodtex.py"))
#         self.struct.interface['preprocessor_plugins'].append(module.Preprocessor(self.struct.interface))
#
#         self.struct.interface['output_plugins'] = []
#         module = imp.load_source(plugin_name + "_output_" + 'html5_mintmodtex', os.path.join(self.struct.options.converterDir, "plugins", "VEUNDMINT", "html5_mintmodtex.py"))
#         self.struct.interface['output_plugins'].append(module.Plugin(self.struct.interface))
#
#
#         #start preprocessing
#
#         for pp in self.struct.interface['preprocessor_plugins']:
#             pp.preprocess()
#
#         # try:
#         #     self.struct.interface['preprocessor_plugins'] = []
#         #     for p in self.struct.interface['options'].usePreprocessorPlugins:
#         #         module = imp.load_source(plugin_name + "_preprocessor_" + p, self.struct.interface['options'].pluginPath[p])
#         #         self.struct.interface['preprocessor_plugins'].append(module.Preprocessor(self.struct.interface))
#         # except Exception:
#         #     formatted_lines = traceback.format_exc().splitlines()
#         #     if formatted_lines[-1].find("AttributeError: 'module' object has no attribute 'Preprocessor'") < 0:
#         #         print(traceback.format_exc())
#         #     else:
#         #         print("\nCannot load preprocessor plugins for '" + plugin_name + "'.\n")
#         #     self.struct.interface['preprocessor_plugins'] = []
#         #
#         # # output_plugins member: A list of modules exposing a class "Plugin" which has a function "create_output"
#         # try:
#         #     self.struct.interface['output_plugins'] = []
#         #     for p in self.struct.interface['options'].useOutputPlugins:
#         #         module = imp.load_source(plugin_name + "_output_" + p, self.struct.interface['options'].pluginPath[p])
#         #         self.struct.interface['output_plugins'].append(module.Plugin(self.struct.interface))
#         # except Exception:
#         #     formatted_lines = traceback.format_exc().splitlines()
#         #     if formatted_lines[-1].find("AttributeError: 'module' object has no attribute 'Plugin'") < 0:
#         #         print(traceback.format_exc())
#         #     else:
#         #         print("\nCannot load output plugins for '" + plugin_name + "'.\n")
#         #     self.struct.interface['output_plugins'] = []
#
#         self.struct.sys = self.struct.interface['system']
#
#
#
#
#     #TODO fails - we need to preprocess something first
#     @unittest.skip("needs more attention")
#     def testStartTtm(self):
#         '''Tests the xml generation method in Structure:start_ttm'''
#
#         #create directories if not exist
#         self.struct.sys.makePath(os.path.join(getBaseDirectory(), '_tmp/tex'))
#
#         self.struct.options.ttmFile = os.path.join(self.struct.options.sourcepath,"test_ttm.xml")
#         self.struct.options.module = "test_ttm.xml"
#
#         #will call self.struct.start_ttm() after xml generation
#         self.struct.prepare_xml_file()
#         self.assertTrue(os.path.exists(self.struct.options.ttmFile))
#
#         #test a little for content correctness
#         #TODO where is defined what tex files get included?
#         tex_directories = [x[0] for x in os.walk(self.struct.options.sourcepath) if 'VBKM' in x[0]]
#         self.log.debug(tex_directories)
#
#     @unittest.skip("needs more attention")
#     def testOptimizeMathml(self):
#         self.assertRaises(TypeError, lambda _: self.struct.optimize_mathml(None))
#
#     def testGetRequiredImages(self):
#         pass
#         # /media/VE/_tmp/tex/targetxml.xml
#
#     @unittest.skip("needs more attention")
#     def testGetRequiredImagesNone(self):
#         self.assertRaises(TypeError, lambda _: Structure().get_required_images(None))
#
#     @unittest.skip("needs more attention")
#     def testcreateTocAndDisectContent(self):
#         pass
#         # s = Structure()
#         #
#         # # fake the functionality of Structure::startTex2x
#         # s.interface = dict()
#         # s.options = dict()
#         #
#         # module = imp.load_source('VEUNDMIT', os.path.join("plugins", "VEUNDMINT", "Option.py"))
#         # s.interface['options'] = module.Option('..', [])
#         #
#         # # simplify access
#         # s.options = s.interface['options']
#         #
#         # s.content = None
#         # s.create_toc_and_disect_content()
#         # print (s.content)
#
# def suite():
#     suite = unittest.makeSuite(StructureTest)
#     return suite
#
# if __name__ == '__main__':
#     runner = unittest.TextTestRunner(verbosity=3)
#     test_suite = suite()
#     runner.run (test_suite)
