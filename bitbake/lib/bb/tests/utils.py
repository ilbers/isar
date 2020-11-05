#
# BitBake Tests for utils.py
#
# Copyright (C) 2012 Richard Purdie
#
# SPDX-License-Identifier: GPL-2.0-only
#

import unittest
import bb
import os
import tempfile
import re

class VerCmpString(unittest.TestCase):

    def test_vercmpstring(self):
        """
        .. versionadded version

        Args:
            self: (todo): write your description
        """
        result = bb.utils.vercmp_string('1', '2')
        self.assertTrue(result < 0)
        result = bb.utils.vercmp_string('2', '1')
        self.assertTrue(result > 0)
        result = bb.utils.vercmp_string('1', '1.0')
        self.assertTrue(result < 0)
        result = bb.utils.vercmp_string('1', '1.1')
        self.assertTrue(result < 0)
        result = bb.utils.vercmp_string('1.1', '1_p2')
        self.assertTrue(result < 0)
        result = bb.utils.vercmp_string('1.0', '1.0+1.1-beta1')
        self.assertTrue(result < 0)
        result = bb.utils.vercmp_string('1.1', '1.0+1.1-beta1')
        self.assertTrue(result > 0)
        result = bb.utils.vercmp_string('1a', '1a1')
        self.assertTrue(result < 0)
        result = bb.utils.vercmp_string('1a1', '1a')
        self.assertTrue(result > 0)
        result = bb.utils.vercmp_string('1.', '1.1')
        self.assertTrue(result < 0)
        result = bb.utils.vercmp_string('1.1', '1.')
        self.assertTrue(result > 0)

    def test_explode_dep_versions(self):
        """
        Explode versions of versions.

        Args:
            self: (todo): write your description
        """
        correctresult = {"foo" : ["= 1.10"]}
        result = bb.utils.explode_dep_versions2("foo (= 1.10)")
        self.assertEqual(result, correctresult)
        result = bb.utils.explode_dep_versions2("foo (=1.10)")
        self.assertEqual(result, correctresult)
        result = bb.utils.explode_dep_versions2("foo ( = 1.10)")
        self.assertEqual(result, correctresult)
        result = bb.utils.explode_dep_versions2("foo ( =1.10)")
        self.assertEqual(result, correctresult)
        result = bb.utils.explode_dep_versions2("foo ( = 1.10 )")
        self.assertEqual(result, correctresult)
        result = bb.utils.explode_dep_versions2("foo ( =1.10 )")
        self.assertEqual(result, correctresult)

    def test_vercmp_string_op(self):
        """
        .. versionadded :: 2019. 2. 0

        Args:
            self: (todo): write your description
        """
        compareops = [('1', '1', '=', True),
                      ('1', '1', '==', True),
                      ('1', '1', '!=', False),
                      ('1', '1', '>', False),
                      ('1', '1', '<', False),
                      ('1', '1', '>=', True),
                      ('1', '1', '<=', True),
                      ('1', '0', '=', False),
                      ('1', '0', '==', False),
                      ('1', '0', '!=', True),
                      ('1', '0', '>', True),
                      ('1', '0', '<', False),
                      ('1', '0', '>>', True),
                      ('1', '0', '<<', False),
                      ('1', '0', '>=', True),
                      ('1', '0', '<=', False),
                      ('0', '1', '=', False),
                      ('0', '1', '==', False),
                      ('0', '1', '!=', True),
                      ('0', '1', '>', False),
                      ('0', '1', '<', True),
                      ('0', '1', '>>', False),
                      ('0', '1', '<<', True),
                      ('0', '1', '>=', False),
                      ('0', '1', '<=', True)]

        for arg1, arg2, op, correctresult in compareops:
            result = bb.utils.vercmp_string_op(arg1, arg2, op)
            self.assertEqual(result, correctresult, 'vercmp_string_op("%s", "%s", "%s") != %s' % (arg1, arg2, op, correctresult))

        # Check that clearly invalid operator raises an exception
        self.assertRaises(bb.utils.VersionStringException, bb.utils.vercmp_string_op, '0', '0', '$')


class Path(unittest.TestCase):
    def test_unsafe_delete_path(self):
        """
        Test if path exists.

        Args:
            self: (todo): write your description
        """
        checkitems = [('/', True),
                      ('//', True),
                      ('///', True),
                      (os.getcwd().count(os.sep) * ('..' + os.sep), True),
                      (os.environ.get('HOME', '/home/test'), True),
                      ('/home/someone', True),
                      ('/home/other/', True),
                      ('/home/other/subdir', False),
                      ('', False)]
        for arg1, correctresult in checkitems:
            result = bb.utils._check_unsafe_delete_path(arg1)
            self.assertEqual(result, correctresult, '_check_unsafe_delete_path("%s") != %s' % (arg1, correctresult))


class EditMetadataFile(unittest.TestCase):
    _origfile = """
# A comment
HELLO = "oldvalue"

THIS = "that"

# Another comment
NOCHANGE = "samevalue"
OTHER = 'anothervalue'

MULTILINE = "a1 \\
             a2 \\
             a3"

MULTILINE2 := " \\
               b1 \\
               b2 \\
               b3 \\
               "


MULTILINE3 = " \\
              c1 \\
              c2 \\
              c3 \\
"

do_functionname() {
    command1 ${VAL1} ${VAL2}
    command2 ${VAL3} ${VAL4}
}
"""
    def _testeditfile(self, varvalues, compareto, dummyvars=None):
        """
        Create a variable in the variable.

        Args:
            self: (todo): write your description
            varvalues: (todo): write your description
            compareto: (str): write your description
            dummyvars: (str): write your description
        """
        if dummyvars is None:
            dummyvars = []
        with tempfile.NamedTemporaryFile('w', delete=False) as tf:
            tf.write(self._origfile)
            tf.close()
            try:
                varcalls = []
                def handle_file(varname, origvalue, op, newlines):
                    """
                    Todo variable.

                    Args:
                        varname: (str): write your description
                        origvalue: (str): write your description
                        op: (str): write your description
                        newlines: (str): write your description
                    """
                    self.assertIn(varname, varvalues, 'Callback called for variable %s not in the list!' % varname)
                    self.assertNotIn(varname, dummyvars, 'Callback called for variable %s in dummy list!' % varname)
                    varcalls.append(varname)
                    return varvalues[varname]

                bb.utils.edit_metadata_file(tf.name, varvalues.keys(), handle_file)
                with open(tf.name) as f:
                    modfile = f.readlines()
                # Ensure the output matches the expected output
                self.assertEqual(compareto.splitlines(True), modfile)
                # Ensure the callback function was called for every variable we asked for
                # (plus allow testing behaviour when a requested variable is not present)
                self.assertEqual(sorted(varvalues.keys()), sorted(varcalls + dummyvars))
            finally:
                os.remove(tf.name)


    def test_edit_metadata_file_nochange(self):
        """
        Sets the metadata file metadata.

        Args:
            self: (todo): write your description
        """
        # Test file doesn't get modified with nothing to do
        self._testeditfile({}, self._origfile)
        # Test file doesn't get modified with only dummy variables
        self._testeditfile({'DUMMY1': ('should_not_set', None, 0, True),
                        'DUMMY2': ('should_not_set_again', None, 0, True)}, self._origfile, dummyvars=['DUMMY1', 'DUMMY2'])
        # Test file doesn't get modified with some the same values
        self._testeditfile({'THIS': ('that', None, 0, True),
                        'OTHER': ('anothervalue', None, 0, True),
                        'MULTILINE3': ('               c1               c2               c3 ', None, 4, False)}, self._origfile)

    def test_edit_metadata_file_1(self):
        """
        Edit the metadata file metadata file.

        Args:
            self: (todo): write your description
        """

        newfile1 = """
# A comment
HELLO = "newvalue"

THIS = "that"

# Another comment
NOCHANGE = "samevalue"
OTHER = 'anothervalue'

MULTILINE = "a1 \\
             a2 \\
             a3"

MULTILINE2 := " \\
               b1 \\
               b2 \\
               b3 \\
               "


MULTILINE3 = " \\
              c1 \\
              c2 \\
              c3 \\
"

do_functionname() {
    command1 ${VAL1} ${VAL2}
    command2 ${VAL3} ${VAL4}
}
"""
        self._testeditfile({'HELLO': ('newvalue', None, 4, True)}, newfile1)


    def test_edit_metadata_file_2(self):
        """
        Edit metadata file.

        Args:
            self: (todo): write your description
        """

        newfile2 = """
# A comment
HELLO = "oldvalue"

THIS = "that"

# Another comment
NOCHANGE = "samevalue"
OTHER = 'anothervalue'

MULTILINE = " \\
    d1 \\
    d2 \\
    d3 \\
    "

MULTILINE2 := " \\
               b1 \\
               b2 \\
               b3 \\
               "


MULTILINE3 = "nowsingle"

do_functionname() {
    command1 ${VAL1} ${VAL2}
    command2 ${VAL3} ${VAL4}
}
"""
        self._testeditfile({'MULTILINE': (['d1','d2','d3'], None, 4, False),
                        'MULTILINE3': ('nowsingle', None, 4, True),
                        'NOTPRESENT': (['a', 'b'], None, 4, False)}, newfile2, dummyvars=['NOTPRESENT'])


    def test_edit_metadata_file_3(self):
        """
        Test if metadata file metadata

        Args:
            self: (todo): write your description
        """

        newfile3 = """
# A comment
HELLO = "oldvalue"

# Another comment
NOCHANGE = "samevalue"
OTHER = "yetanothervalue"

MULTILINE = "e1 \\
             e2 \\
             e3 \\
             "

MULTILINE2 := "f1 \\
\tf2 \\
\t"


MULTILINE3 = " \\
              c1 \\
              c2 \\
              c3 \\
"

do_functionname() {
    othercommand_one a b c
    othercommand_two d e f
}
"""

        self._testeditfile({'do_functionname()': (['othercommand_one a b c', 'othercommand_two d e f'], None, 4, False),
                        'MULTILINE2': (['f1', 'f2'], None, '\t', True),
                        'MULTILINE': (['e1', 'e2', 'e3'], None, -1, True),
                        'THIS': (None, None, 0, False),
                        'OTHER': ('yetanothervalue', None, 0, True)}, newfile3)


    def test_edit_metadata_file_4(self):
        """
        Test if metadata file.

        Args:
            self: (todo): write your description
        """

        newfile4 = """
# A comment
HELLO = "oldvalue"

THIS = "that"

# Another comment
OTHER = 'anothervalue'

MULTILINE = "a1 \\
             a2 \\
             a3"

MULTILINE2 := " \\
               b1 \\
               b2 \\
               b3 \\
               "


"""

        self._testeditfile({'NOCHANGE': (None, None, 0, False),
                        'MULTILINE3': (None, None, 0, False),
                        'THIS': ('that', None, 0, False),
                        'do_functionname()': (None, None, 0, False)}, newfile4)


    def test_edit_metadata(self):
        """
        Edit metadata for a metadata file.

        Args:
            self: (todo): write your description
        """
        newfile5 = """
# A comment
HELLO = "hithere"

# A new comment
THIS += "that"

# Another comment
NOCHANGE = "samevalue"
OTHER = 'anothervalue'

MULTILINE = "a1 \\
             a2 \\
             a3"

MULTILINE2 := " \\
               b1 \\
               b2 \\
               b3 \\
               "


MULTILINE3 = " \\
              c1 \\
              c2 \\
              c3 \\
"

NEWVAR = "value"

do_functionname() {
    command1 ${VAL1} ${VAL2}
    command2 ${VAL3} ${VAL4}
}
"""


        def handle_var(varname, origvalue, op, newlines):
            """
            Handle a variable.

            Args:
                varname: (str): write your description
                origvalue: (str): write your description
                op: (todo): write your description
                newlines: (list): write your description
            """
            if varname == 'THIS':
                newlines.append('# A new comment\n')
            elif varname == 'do_functionname()':
                newlines.append('NEWVAR = "value"\n')
                newlines.append('\n')
            valueitem = varvalues.get(varname, None)
            if valueitem:
                return valueitem
            else:
                return (origvalue, op, 0, True)

        varvalues = {'HELLO': ('hithere', None, 0, True), 'THIS': ('that', '+=', 0, True)}
        varlist = ['HELLO', 'THIS', 'do_functionname()']
        (updated, newlines) = bb.utils.edit_metadata(self._origfile.splitlines(True), varlist, handle_var)
        self.assertTrue(updated, 'List should be updated but isn\'t')
        self.assertEqual(newlines, newfile5.splitlines(True))

    # Make sure the orig value matches what we expect it to be
    def test_edit_metadata_origvalue(self):
        """
        Edit metadata in the metadata of the metadata metadata.

        Args:
            self: (todo): write your description
        """
        origfile = """
MULTILINE = "  stuff \\
    morestuff"
"""
        expected_value = "stuff morestuff"
        global value_in_callback
        value_in_callback = ""

        def handle_var(varname, origvalue, op, newlines):
            """
            Handle a variable.

            Args:
                varname: (str): write your description
                origvalue: (str): write your description
                op: (todo): write your description
                newlines: (list): write your description
            """
            global value_in_callback
            value_in_callback = origvalue
            return (origvalue, op, -1, False)

        bb.utils.edit_metadata(origfile.splitlines(True),
                               ['MULTILINE'],
                               handle_var)

        testvalue = re.sub('\s+', ' ', value_in_callback.strip())
        self.assertEqual(expected_value, testvalue)

class EditBbLayersConf(unittest.TestCase):

    def _test_bblayers_edit(self, before, after, add, remove, notadded, notremoved):
        """
        Test if two - layer.

        Args:
            self: (todo): write your description
            before: (todo): write your description
            after: (str): write your description
            add: (todo): write your description
            remove: (bool): write your description
            notadded: (todo): write your description
            notremoved: (bool): write your description
        """
        with tempfile.NamedTemporaryFile('w', delete=False) as tf:
            tf.write(before)
            tf.close()
            try:
                actual_notadded, actual_notremoved = bb.utils.edit_bblayers_conf(tf.name, add, remove)
                with open(tf.name) as f:
                    actual_after = f.readlines()
                self.assertEqual(after.splitlines(True), actual_after)
                self.assertEqual(notadded, actual_notadded)
                self.assertEqual(notremoved, actual_notremoved)
            finally:
                os.remove(tf.name)


    def test_bblayers_remove(self):
        """
        Remove bblayers.

        Args:
            self: (todo): write your description
        """
        before = r"""
# A comment

BBPATH = "${TOPDIR}"
BBFILES ?= ""
BBLAYERS = " \
  /home/user/path/layer1 \
  /home/user/path/layer2 \
  /home/user/path/subpath/layer3 \
  /home/user/path/layer4 \
  "
"""
        after = r"""
# A comment

BBPATH = "${TOPDIR}"
BBFILES ?= ""
BBLAYERS = " \
  /home/user/path/layer1 \
  /home/user/path/subpath/layer3 \
  /home/user/path/layer4 \
  "
"""
        self._test_bblayers_edit(before, after,
                                 None,
                                 '/home/user/path/layer2',
                                 [],
                                 [])


    def test_bblayers_add(self):
        """
        Add two layers to bblayers.

        Args:
            self: (todo): write your description
        """
        before = r"""
# A comment

BBPATH = "${TOPDIR}"
BBFILES ?= ""
BBLAYERS = " \
  /home/user/path/layer1 \
  /home/user/path/layer2 \
  /home/user/path/subpath/layer3 \
  /home/user/path/layer4 \
  "
"""
        after = r"""
# A comment

BBPATH = "${TOPDIR}"
BBFILES ?= ""
BBLAYERS = " \
  /home/user/path/layer1 \
  /home/user/path/layer2 \
  /home/user/path/subpath/layer3 \
  /home/user/path/layer4 \
  /other/path/to/layer5 \
  "
"""
        self._test_bblayers_edit(before, after,
                                 '/other/path/to/layer5/',
                                 None,
                                 [],
                                 [])


    def test_bblayers_add_remove(self):
        """
        Add bblayers to bblayers.

        Args:
            self: (todo): write your description
        """
        before = r"""
# A comment

BBPATH = "${TOPDIR}"
BBFILES ?= ""
BBLAYERS = " \
  /home/user/path/layer1 \
  /home/user/path/layer2 \
  /home/user/path/subpath/layer3 \
  /home/user/path/layer4 \
  "
"""
        after = r"""
# A comment

BBPATH = "${TOPDIR}"
BBFILES ?= ""
BBLAYERS = " \
  /home/user/path/layer1 \
  /home/user/path/layer2 \
  /home/user/path/layer4 \
  /other/path/to/layer5 \
  "
"""
        self._test_bblayers_edit(before, after,
                                 ['/other/path/to/layer5', '/home/user/path/layer2/'], '/home/user/path/subpath/layer3/',
                                 ['/home/user/path/layer2'],
                                 [])


    def test_bblayers_add_remove_home(self):
        """
        Add bblayers layers to bblayers.

        Args:
            self: (todo): write your description
        """
        before = r"""
# A comment

BBPATH = "${TOPDIR}"
BBFILES ?= ""
BBLAYERS = " \
  ~/path/layer1 \
  ~/path/layer2 \
  ~/otherpath/layer3 \
  ~/path/layer4 \
  "
"""
        after = r"""
# A comment

BBPATH = "${TOPDIR}"
BBFILES ?= ""
BBLAYERS = " \
  ~/path/layer2 \
  ~/path/layer4 \
  ~/path2/layer5 \
  "
"""
        self._test_bblayers_edit(before, after,
                                 [os.environ['HOME'] + '/path/layer4', '~/path2/layer5'],
                                 [os.environ['HOME'] + '/otherpath/layer3', '~/path/layer1', '~/path/notinlist'],
                                 [os.environ['HOME'] + '/path/layer4'],
                                 ['~/path/notinlist'])


    def test_bblayers_add_remove_plusequals(self):
        """
        Add bblayers to bblayers layer.

        Args:
            self: (todo): write your description
        """
        before = r"""
# A comment

BBPATH = "${TOPDIR}"
BBFILES ?= ""
BBLAYERS += " \
  /home/user/path/layer1 \
  /home/user/path/layer2 \
  "
"""
        after = r"""
# A comment

BBPATH = "${TOPDIR}"
BBFILES ?= ""
BBLAYERS += " \
  /home/user/path/layer2 \
  /home/user/path/layer3 \
  "
"""
        self._test_bblayers_edit(before, after,
                                 '/home/user/path/layer3',
                                 '/home/user/path/layer1',
                                 [],
                                 [])


    def test_bblayers_add_remove_plusequals2(self):
        """
        Add bblayers layers.

        Args:
            self: (todo): write your description
        """
        before = r"""
# A comment

BBPATH = "${TOPDIR}"
BBFILES ?= ""
BBLAYERS += " \
  /home/user/path/layer1 \
  /home/user/path/layer2 \
  /home/user/path/layer3 \
  "
BBLAYERS += "/home/user/path/layer4"
BBLAYERS += "/home/user/path/layer5"
"""
        after = r"""
# A comment

BBPATH = "${TOPDIR}"
BBFILES ?= ""
BBLAYERS += " \
  /home/user/path/layer2 \
  /home/user/path/layer3 \
  "
BBLAYERS += "/home/user/path/layer5"
BBLAYERS += "/home/user/otherpath/layer6"
"""
        self._test_bblayers_edit(before, after,
                                 ['/home/user/otherpath/layer6', '/home/user/path/layer3'], ['/home/user/path/layer1', '/home/user/path/layer4', '/home/user/path/layer7'],
                                 ['/home/user/path/layer3'],
                                 ['/home/user/path/layer7'])
