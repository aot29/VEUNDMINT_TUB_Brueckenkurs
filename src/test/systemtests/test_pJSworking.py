import unittest
from selenium import webdriver
from test.systemtests.AbstractSystemTest import AbstractSystemTest

class TestOne(AbstractSystemTest):

    def test_url(self):
        self.driver.get("http://duckduckgo.com/")
        self.driver.find_element_by_id(
            'search_form_input_homepage').send_keys("realpython")
        self.driver.find_element_by_id("search_button_homepage").click()
        self.assertIn(
            "https://duckduckgo.com/?q=realpython", self.driver.current_url
        )

if __name__ == '__main__':
    unittest.main()
