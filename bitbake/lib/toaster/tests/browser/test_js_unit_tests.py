#! /usr/bin/env python3
#
# BitBake Toaster Implementation
#
# Copyright (C) 2013-2016 Intel Corporation
#
# SPDX-License-Identifier: GPL-2.0-only
#

"""
Run the js unit tests
"""

from django.core.urlresolvers import reverse
from tests.browser.selenium_helpers import SeleniumTestCase
import logging

logger = logging.getLogger("toaster")


class TestJsUnitTests(SeleniumTestCase):
    """ Test landing page shows the Toaster brand """

    fixtures = ['toastergui-unittest-data']

    def test_that_js_unit_tests_pass(self):
        """
        Test if javascript javascript javascript.

        Args:
            self: (todo): write your description
        """
        url = reverse('js-unit-tests')
        self.get(url)
        self.wait_until_present('#qunit-testresult .failed')

        failed = self.find("#qunit-testresult .failed").text
        passed = self.find("#qunit-testresult .passed").text
        total = self.find("#qunit-testresult .total").text

        logger.info("Js unit tests completed %s out of %s passed, %s failed",
                    passed,
                    total,
                    failed)

        failed_tests = self.find_all("li .fail .test-message")
        for fail in failed_tests:
            logger.error("JS unit test failed: %s" % fail.text)

        self.assertEqual(failed, '0',
                         "%s JS unit tests failed" % failed)
