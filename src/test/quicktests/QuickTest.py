import unittest
from selenium import webdriver
from settings import BASE_URL, BASE_DIR


class QuickTest(unittest.TestCase):

	def setUp(self):
		self.driver = webdriver.PhantomJS(executable_path=BASE_DIR + '/node_modules/phantomjs/lib/phantom/bin/phantomjs', service_log_path=BASE_DIR + '/ghostdriver.log')
		
		self.driver.set_window_size(1120, 550)
		self.driver.set_page_load_timeout(30)
