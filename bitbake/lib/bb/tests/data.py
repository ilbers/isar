#
# BitBake Tests for the Data Store (data.py/data_smart.py)
#
# Copyright (C) 2010 Chris Larson
# Copyright (C) 2012 Richard Purdie
#
# SPDX-License-Identifier: GPL-2.0-only
#

import unittest
import bb
import bb.data
import bb.parse
import logging

class LogRecord():
    def __enter__(self):
        """
        Add a new logger.

        Args:
            self: (todo): write your description
        """
        logs = []
        class LogHandler(logging.Handler):
            def emit(self, record):
                """
                Emit a record.

                Args:
                    self: (todo): write your description
                    record: (todo): write your description
                """
                logs.append(record)
        logger = logging.getLogger("BitBake")
        handler = LogHandler()
        self.handler = handler
        logger.addHandler(handler)
        return logs
    def __exit__(self, type, value, traceback):
        """
        Removes a logger.

        Args:
            self: (todo): write your description
            type: (todo): write your description
            value: (todo): write your description
            traceback: (todo): write your description
        """
        logger = logging.getLogger("BitBake")
        logger.removeHandler(self.handler)
        return

def logContains(item, logs):
    """
    Logs true if logs are in log.

    Args:
        item: (str): write your description
        logs: (todo): write your description
    """
    for l in logs:
        m = l.getMessage()
        if item in m:
            return True
    return False

class DataExpansions(unittest.TestCase):
    def setUp(self):
        """
        Sets the duration of the duration.

        Args:
            self: (todo): write your description
        """
        self.d = bb.data.init()
        self.d["foo"] = "value_of_foo"
        self.d["bar"] = "value_of_bar"
        self.d["value_of_foo"] = "value_of_'value_of_foo'"

    def test_one_var(self):
        """
        Test whether one test variable.

        Args:
            self: (todo): write your description
        """
        val = self.d.expand("${foo}")
        self.assertEqual(str(val), "value_of_foo")

    def test_indirect_one_var(self):
        """
        Test if one test test variable.

        Args:
            self: (todo): write your description
        """
        val = self.d.expand("${${foo}}")
        self.assertEqual(str(val), "value_of_'value_of_foo'")

    def test_indirect_and_another(self):
        """
        Set test test and test test.

        Args:
            self: (todo): write your description
        """
        val = self.d.expand("${${foo}} ${bar}")
        self.assertEqual(str(val), "value_of_'value_of_foo' value_of_bar")

    def test_python_snippet(self):
        """
        Test if the test snippet.

        Args:
            self: (todo): write your description
        """
        val = self.d.expand("${@5*12}")
        self.assertEqual(str(val), "60")

    def test_expand_in_python_snippet(self):
        """
        Evaluate a python object.

        Args:
            self: (todo): write your description
        """
        val = self.d.expand("${@'boo ' + '${foo}'}")
        self.assertEqual(str(val), "boo value_of_foo")

    def test_python_snippet_getvar(self):
        """
        Test if snippet_snippet.

        Args:
            self: (todo): write your description
        """
        val = self.d.expand("${@d.getVar('foo') + ' ${bar}'}")
        self.assertEqual(str(val), "value_of_foo value_of_bar")

    def test_python_unexpanded(self):
        """
        Unexpanded the value in python 2.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("bar", "${unsetvar}")
        val = self.d.expand("${@d.getVar('foo') + ' ${bar}'}")
        self.assertEqual(str(val), "${@d.getVar('foo') + ' ${unsetvar}'}")

    def test_python_snippet_syntax_error(self):
        """
        Test for test test test test test test.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("FOO", "${@foo = 5}")
        self.assertRaises(bb.data_smart.ExpansionError, self.d.getVar, "FOO", True)

    def test_python_snippet_runtime_error(self):
        """
        Test if the test.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("FOO", "${@int('test')}")
        self.assertRaises(bb.data_smart.ExpansionError, self.d.getVar, "FOO", True)

    def test_python_snippet_error_path(self):
        """
        Test if snippet_snippet

        Args:
            self: (todo): write your description
        """
        self.d.setVar("FOO", "foo value ${BAR}")
        self.d.setVar("BAR", "bar value ${@int('test')}")
        self.assertRaises(bb.data_smart.ExpansionError, self.d.getVar, "FOO", True)

    def test_value_containing_value(self):
        """
        Set the test value.

        Args:
            self: (todo): write your description
        """
        val = self.d.expand("${@d.getVar('foo') + ' ${bar}'}")
        self.assertEqual(str(val), "value_of_foo value_of_bar")

    def test_reference_undefined_var(self):
        """
        Test if reference is a test.

        Args:
            self: (todo): write your description
        """
        val = self.d.expand("${undefinedvar} meh")
        self.assertEqual(str(val), "${undefinedvar} meh")

    def test_double_reference(self):
        """
        Test if the reference is set the reference.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("BAR", "bar value")
        self.d.setVar("FOO", "${BAR} foo ${BAR}")
        val = self.d.getVar("FOO")
        self.assertEqual(str(val), "bar value foo bar value")

    def test_direct_recursion(self):
        """
        Test whether the recursion.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("FOO", "${FOO}")
        self.assertRaises(bb.data_smart.ExpansionError, self.d.getVar, "FOO", True)

    def test_indirect_recursion(self):
        """
        Test if the test test test test for the test.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("FOO", "${BAR}")
        self.d.setVar("BAR", "${BAZ}")
        self.d.setVar("BAZ", "${FOO}")
        self.assertRaises(bb.data_smart.ExpansionError, self.d.getVar, "FOO", True)

    def test_recursion_exception(self):
        """
        Test if the test data

        Args:
            self: (todo): write your description
        """
        self.d.setVar("FOO", "${BAR}")
        self.d.setVar("BAR", "${${@'FOO'}}")
        self.assertRaises(bb.data_smart.ExpansionError, self.d.getVar, "FOO", True)

    def test_incomplete_varexp_single_quotes(self):
        """
        Test if a single single test is a single test.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("FOO", "sed -i -e 's:IP{:I${:g' $pc")
        val = self.d.getVar("FOO")
        self.assertEqual(str(val), "sed -i -e 's:IP{:I${:g' $pc")

    def test_nonstring(self):
        """
        Test if the test string.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST", 5)
        val = self.d.getVar("TEST")
        self.assertEqual(str(val), "5")

    def test_rename(self):
        """
        Rename a variable

        Args:
            self: (todo): write your description
        """
        self.d.renameVar("foo", "newfoo")
        self.assertEqual(self.d.getVar("newfoo", False), "value_of_foo")
        self.assertEqual(self.d.getVar("foo", False), None)

    def test_deletion(self):
        """
        Test the test test

        Args:
            self: (todo): write your description
        """
        self.d.delVar("foo")
        self.assertEqual(self.d.getVar("foo", False), None)

    def test_keys(self):
        """
        : return the keys in the keys

        Args:
            self: (todo): write your description
        """
        keys = list(self.d.keys())
        self.assertCountEqual(keys, ['value_of_foo', 'foo', 'bar'])

    def test_keys_deletion(self):
        """
        Deletes the keys of the keys in the keys.

        Args:
            self: (todo): write your description
        """
        newd = bb.data.createCopy(self.d)
        newd.delVar("bar")
        keys = list(newd.keys())
        self.assertCountEqual(keys, ['value_of_foo', 'foo'])

class TestNestedExpansions(unittest.TestCase):
    def setUp(self):
        """
        Sets the duration of the duration.

        Args:
            self: (todo): write your description
        """
        self.d = bb.data.init()
        self.d["foo"] = "foo"
        self.d["bar"] = "bar"
        self.d["value_of_foobar"] = "187"

    def test_refs(self):
        """
        Set the reference value

        Args:
            self: (todo): write your description
        """
        val = self.d.expand("${value_of_${foo}${bar}}")
        self.assertEqual(str(val), "187")

    #def test_python_refs(self):
    #    val = self.d.expand("${@${@3}**2 + ${@4}**2}")
    #    self.assertEqual(str(val), "25")

    def test_ref_in_python_ref(self):
        """
        Test if the reference reference to_ref

        Args:
            self: (todo): write your description
        """
        val = self.d.expand("${@'${foo}' + 'bar'}")
        self.assertEqual(str(val), "foobar")

    def test_python_ref_in_ref(self):
        """
        Test if the reference is in place

        Args:
            self: (todo): write your description
        """
        val = self.d.expand("${${@'f'+'o'+'o'}}")
        self.assertEqual(str(val), "foo")

    def test_deep_nesting(self):
        """
        Calculate the test test test.

        Args:
            self: (todo): write your description
        """
        depth = 100
        val = self.d.expand("${" * depth + "foo" + "}" * depth)
        self.assertEqual(str(val), "foo")

    #def test_deep_python_nesting(self):
    #    depth = 50
    #    val = self.d.expand("${@" * depth + "1" + "+1}" * depth)
    #    self.assertEqual(str(val), str(depth + 1))

    def test_mixed(self):
        """
        Set the test value.

        Args:
            self: (todo): write your description
        """
        val = self.d.expand("${value_of_${@('${foo}'+'bar')[0:3]}${${@'BAR'.lower()}}}")
        self.assertEqual(str(val), "187")

    def test_runtime(self):
        """
        Set the runtime.

        Args:
            self: (todo): write your description
        """
        val = self.d.expand("${${@'value_of' + '_f'+'o'+'o'+'b'+'a'+'r'}}")
        self.assertEqual(str(val), "187")

class TestMemoize(unittest.TestCase):
    def test_memoized(self):
        """
        Test if the memoized data

        Args:
            self: (todo): write your description
        """
        d = bb.data.init()
        d.setVar("FOO", "bar")
        self.assertTrue(d.getVar("FOO", False) is d.getVar("FOO", False))

    def test_not_memoized(self):
        """
        Test if the memo memoization.

        Args:
            self: (todo): write your description
        """
        d1 = bb.data.init()
        d2 = bb.data.init()
        d1.setVar("FOO", "bar")
        d2.setVar("FOO", "bar2")
        self.assertTrue(d1.getVar("FOO", False) is not d2.getVar("FOO", False))

    def test_changed_after_memoized(self):
        """
        Determine the memo is changed changes

        Args:
            self: (todo): write your description
        """
        d = bb.data.init()
        d.setVar("foo", "value of foo")
        self.assertEqual(str(d.getVar("foo", False)), "value of foo")
        d.setVar("foo", "second value of foo")
        self.assertEqual(str(d.getVar("foo", False)), "second value of foo")

    def test_same_value(self):
        """
        Gets / sets as_same as the same value.

        Args:
            self: (todo): write your description
        """
        d = bb.data.init()
        d.setVar("foo", "value of")
        d.setVar("bar", "value of")
        self.assertEqual(d.getVar("foo", False),
                         d.getVar("bar", False))

class TestConcat(unittest.TestCase):
    def setUp(self):
        """
        Sets the dag.

        Args:
            self: (todo): write your description
        """
        self.d = bb.data.init()
        self.d.setVar("FOO", "foo")
        self.d.setVar("VAL", "val")
        self.d.setVar("BAR", "bar")

    def test_prepend(self):
        """
        Prepend the test is_prepend

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST", "${VAL}")
        self.d.prependVar("TEST", "${FOO}:")
        self.assertEqual(self.d.getVar("TEST"), "foo:val")

    def test_append(self):
        """
        Appends a test record

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST", "${VAL}")
        self.d.appendVar("TEST", ":${BAR}")
        self.assertEqual(self.d.getVar("TEST"), "val:bar")

    def test_multiple_append(self):
        """
        Append multiple multiple multiple multiple dtype as a list

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST", "${VAL}")
        self.d.prependVar("TEST", "${FOO}:")
        self.d.appendVar("TEST", ":val2")
        self.d.appendVar("TEST", ":${BAR}")
        self.assertEqual(self.d.getVar("TEST"), "foo:val:val2:bar")

class TestConcatOverride(unittest.TestCase):
    def setUp(self):
        """
        Sets the dag.

        Args:
            self: (todo): write your description
        """
        self.d = bb.data.init()
        self.d.setVar("FOO", "foo")
        self.d.setVar("VAL", "val")
        self.d.setVar("BAR", "bar")

    def test_prepend(self):
        """
        Prepend to the test

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST", "${VAL}")
        self.d.setVar("TEST_prepend", "${FOO}:")
        self.assertEqual(self.d.getVar("TEST"), "foo:val")

    def test_append(self):
        """
        Appends a test to the end of the dtype is a dict.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST", "${VAL}")
        self.d.setVar("TEST_append", ":${BAR}")
        self.assertEqual(self.d.getVar("TEST"), "val:bar")

    def test_multiple_append(self):
        """
        Add multiple multiple multiple multiple multiple multiple dtype.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST", "${VAL}")
        self.d.setVar("TEST_prepend", "${FOO}:")
        self.d.setVar("TEST_append", ":val2")
        self.d.setVar("TEST_append", ":${BAR}")
        self.assertEqual(self.d.getVar("TEST"), "foo:val:val2:bar")

    def test_append_unset(self):
        """
        This method will be called test data to unset

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST_prepend", "${FOO}:")
        self.d.setVar("TEST_append", ":val2")
        self.d.setVar("TEST_append", ":${BAR}")
        self.assertEqual(self.d.getVar("TEST"), "foo::val2:bar")

    def test_remove(self):
        """
        Removes the test variable

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST", "${VAL} ${BAR}")
        self.d.setVar("TEST_remove", "val")
        self.assertEqual(self.d.getVar("TEST"), " bar")

    def test_remove_cleared(self):
        """
        Removes the test variable.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST", "${VAL} ${BAR}")
        self.d.setVar("TEST_remove", "val")
        self.d.setVar("TEST", "${VAL} ${BAR}")
        self.assertEqual(self.d.getVar("TEST"), "val bar")

    # Ensure the value is unchanged if we have an inactive remove override
    # (including that whitespace is preserved)
    def test_remove_inactive_override(self):
        """
        Removes the test config that was created.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST", "${VAL} ${BAR}    123")
        self.d.setVar("TEST_remove_inactiveoverride", "val")
        self.assertEqual(self.d.getVar("TEST"), "val bar    123")

    def test_doubleref_remove(self):
        """
        Remove double double double double double double precision.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST", "${VAL} ${BAR}")
        self.d.setVar("TEST_remove", "val")
        self.d.setVar("TEST_TEST", "${TEST} ${TEST}")
        self.assertEqual(self.d.getVar("TEST_TEST"), " bar  bar")

    def test_empty_remove(self):
        """
        Removes empty empty empty empty.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST", "")
        self.d.setVar("TEST_remove", "val")
        self.assertEqual(self.d.getVar("TEST"), "")

    def test_remove_expansion(self):
        """
        Remove all expansion

        Args:
            self: (todo): write your description
        """
        self.d.setVar("BAR", "Z")
        self.d.setVar("TEST", "${BAR}/X Y")
        self.d.setVar("TEST_remove", "${BAR}/X")
        self.assertEqual(self.d.getVar("TEST"), " Y")

    def test_remove_expansion_items(self):
        """
        Remove all items in this object.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST", "A B C D")
        self.d.setVar("BAR", "B D")
        self.d.setVar("TEST_remove", "${BAR}")
        self.assertEqual(self.d.getVar("TEST"), "A  C ")

    def test_remove_preserve_whitespace(self):
        """
        Removes the test variables from the test has been removed from the test.

        Args:
            self: (todo): write your description
        """
        # When the removal isn't active, the original value should be preserved
        self.d.setVar("TEST", " A B")
        self.d.setVar("TEST_remove", "C")
        self.assertEqual(self.d.getVar("TEST"), " A B")

    def test_remove_preserve_whitespace2(self):
        """
        Removes the test test variables.

        Args:
            self: (todo): write your description
        """
        # When the removal is active preserve the whitespace
        self.d.setVar("TEST", " A B")
        self.d.setVar("TEST_remove", "B")
        self.assertEqual(self.d.getVar("TEST"), " A ")

class TestOverrides(unittest.TestCase):
    def setUp(self):
        """
        Sets the values of the dag.

        Args:
            self: (todo): write your description
        """
        self.d = bb.data.init()
        self.d.setVar("OVERRIDES", "foo:bar:local")
        self.d.setVar("TEST", "testvalue")

    def test_no_override(self):
        """
        Test if the current value of a test.

        Args:
            self: (todo): write your description
        """
        self.assertEqual(self.d.getVar("TEST"), "testvalue")

    def test_one_override(self):
        """
        Test if there is_one.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST_bar", "testvalue2")
        self.assertEqual(self.d.getVar("TEST"), "testvalue2")

    def test_one_override_unset(self):
        """
        Test if there is_one_unset_unset

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST2_bar", "testvalue2")

        self.assertEqual(self.d.getVar("TEST2"), "testvalue2")
        self.assertCountEqual(list(self.d.keys()), ['TEST', 'TEST2', 'OVERRIDES', 'TEST2_bar'])

    def test_multiple_override(self):
        """
        Test if there is a set of the current values.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST_bar", "testvalue2")
        self.d.setVar("TEST_local", "testvalue3")
        self.d.setVar("TEST_foo", "testvalue4")
        self.assertEqual(self.d.getVar("TEST"), "testvalue3")
        self.assertCountEqual(list(self.d.keys()), ['TEST', 'TEST_foo', 'OVERRIDES', 'TEST_bar', 'TEST_local'])

    def test_multiple_combined_overrides(self):
        """
        Test if there is_multiple.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST_local_foo_bar", "testvalue3")
        self.assertEqual(self.d.getVar("TEST"), "testvalue3")

    def test_multiple_overrides_unset(self):
        """
        Test if there are set of the concides.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST2_local_foo_bar", "testvalue3")
        self.assertEqual(self.d.getVar("TEST2"), "testvalue3")

    def test_keyexpansion_override(self):
        """
        Test if the keyexpansion in the same

        Args:
            self: (todo): write your description
        """
        self.d.setVar("LOCAL", "local")
        self.d.setVar("TEST_bar", "testvalue2")
        self.d.setVar("TEST_${LOCAL}", "testvalue3")
        self.d.setVar("TEST_foo", "testvalue4")
        bb.data.expandKeys(self.d)
        self.assertEqual(self.d.getVar("TEST"), "testvalue3")

    def test_rename_override(self):
        """
        Rename a dictionary of options.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("ALTERNATIVE_ncurses-tools_class-target", "a")
        self.d.setVar("OVERRIDES", "class-target")
        self.d.renameVar("ALTERNATIVE_ncurses-tools", "ALTERNATIVE_lib32-ncurses-tools")
        self.assertEqual(self.d.getVar("ALTERNATIVE_lib32-ncurses-tools"), "a")

    def test_underscore_override(self):
        """
        Test if we want todo_override.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST_bar", "testvalue2")
        self.d.setVar("TEST_some_val", "testvalue3")
        self.d.setVar("TEST_foo", "testvalue4")
        self.d.setVar("OVERRIDES", "foo:bar:some_val")
        self.assertEqual(self.d.getVar("TEST"), "testvalue3")

    def test_remove_with_override(self):
        """
        Remove test test is set.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST_bar", "testvalue2")
        self.d.setVar("TEST_some_val", "testvalue3 testvalue5")
        self.d.setVar("TEST_some_val_remove", "testvalue3")
        self.d.setVar("TEST_foo", "testvalue4")
        self.d.setVar("OVERRIDES", "foo:bar:some_val")
        self.assertEqual(self.d.getVar("TEST"), " testvalue5")

    def test_append_and_override_1(self):
        """
        Appends a new test and append the current value.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST_append", "testvalue2")
        self.d.setVar("TEST_bar", "testvalue3")
        self.assertEqual(self.d.getVar("TEST"), "testvalue3testvalue2")

    def test_append_and_override_2(self):
        """
        Appends a test and append to the appended.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST_append_bar", "testvalue2")
        self.assertEqual(self.d.getVar("TEST"), "testvaluetestvalue2")

    def test_append_and_override_3(self):
        """
        Appends the current test and append todo.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TEST_bar_append", "testvalue2")
        self.assertEqual(self.d.getVar("TEST"), "testvalue2")

    # Test an override with _<numeric> in it based on a real world OE issue
    def test_underscore_override(self):
        """
        Test if we need_unders_override is set.

        Args:
            self: (todo): write your description
        """
        self.d.setVar("TARGET_ARCH", "x86_64")
        self.d.setVar("PN", "test-${TARGET_ARCH}")
        self.d.setVar("VERSION", "1")
        self.d.setVar("VERSION_pn-test-${TARGET_ARCH}", "2")
        self.d.setVar("OVERRIDES", "pn-${PN}")
        bb.data.expandKeys(self.d)
        self.assertEqual(self.d.getVar("VERSION"), "2")

class TestKeyExpansion(unittest.TestCase):
    def setUp(self):
        """
        Sets the values of the dag.

        Args:
            self: (todo): write your description
        """
        self.d = bb.data.init()
        self.d.setVar("FOO", "foo")
        self.d.setVar("BAR", "foo")

    def test_keyexpand(self):
        """
        Test if the current test

        Args:
            self: (todo): write your description
        """
        self.d.setVar("VAL_${FOO}", "A")
        self.d.setVar("VAL_${BAR}", "B")
        with LogRecord() as logs:
            bb.data.expandKeys(self.d)
            self.assertTrue(logContains("Variable key VAL_${FOO} (A) replaces original key VAL_foo (B)", logs))
        self.assertEqual(self.d.getVar("VAL_foo"), "A")

class TestFlags(unittest.TestCase):
    def setUp(self):
        """
        Sets the ds for the dag.

        Args:
            self: (todo): write your description
        """
        self.d = bb.data.init()
        self.d.setVar("foo", "value of foo")
        self.d.setVarFlag("foo", "flag1", "value of flag1")
        self.d.setVarFlag("foo", "flag2", "value of flag2")

    def test_setflag(self):
        """
        Test if the test flag

        Args:
            self: (todo): write your description
        """
        self.assertEqual(self.d.getVarFlag("foo", "flag1", False), "value of flag1")
        self.assertEqual(self.d.getVarFlag("foo", "flag2", False), "value of flag2")

    def test_delflag(self):
        """
        Determine whether the test isflag

        Args:
            self: (todo): write your description
        """
        self.d.delVarFlag("foo", "flag2")
        self.assertEqual(self.d.getVarFlag("foo", "flag1", False), "value of flag1")
        self.assertEqual(self.d.getVarFlag("foo", "flag2", False), None)


class Contains(unittest.TestCase):
    def setUp(self):
        """
        Sets the dag.

        Args:
            self: (todo): write your description
        """
        self.d = bb.data.init()
        self.d.setVar("SOMEFLAG", "a b c")

    def test_contains(self):
        """
        Check if the report contains any of the keys.

        Args:
            self: (todo): write your description
        """
        self.assertTrue(bb.utils.contains("SOMEFLAG", "a", True, False, self.d))
        self.assertTrue(bb.utils.contains("SOMEFLAG", "b", True, False, self.d))
        self.assertTrue(bb.utils.contains("SOMEFLAG", "c", True, False, self.d))

        self.assertTrue(bb.utils.contains("SOMEFLAG", "a b", True, False, self.d))
        self.assertTrue(bb.utils.contains("SOMEFLAG", "b c", True, False, self.d))
        self.assertTrue(bb.utils.contains("SOMEFLAG", "c a", True, False, self.d))

        self.assertTrue(bb.utils.contains("SOMEFLAG", "a b c", True, False, self.d))
        self.assertTrue(bb.utils.contains("SOMEFLAG", "c b a", True, False, self.d))

        self.assertFalse(bb.utils.contains("SOMEFLAG", "x", True, False, self.d))
        self.assertFalse(bb.utils.contains("SOMEFLAG", "a x", True, False, self.d))
        self.assertFalse(bb.utils.contains("SOMEFLAG", "x c b", True, False, self.d))
        self.assertFalse(bb.utils.contains("SOMEFLAG", "x c b a", True, False, self.d))

    def test_contains_any(self):
        """
        Check if any of the items in self.

        Args:
            self: (todo): write your description
        """
        self.assertTrue(bb.utils.contains_any("SOMEFLAG", "a", True, False, self.d))
        self.assertTrue(bb.utils.contains_any("SOMEFLAG", "b", True, False, self.d))
        self.assertTrue(bb.utils.contains_any("SOMEFLAG", "c", True, False, self.d))

        self.assertTrue(bb.utils.contains_any("SOMEFLAG", "a b", True, False, self.d))
        self.assertTrue(bb.utils.contains_any("SOMEFLAG", "b c", True, False, self.d))
        self.assertTrue(bb.utils.contains_any("SOMEFLAG", "c a", True, False, self.d))

        self.assertTrue(bb.utils.contains_any("SOMEFLAG", "a x", True, False, self.d))
        self.assertTrue(bb.utils.contains_any("SOMEFLAG", "x c", True, False, self.d))

        self.assertFalse(bb.utils.contains_any("SOMEFLAG", "x", True, False, self.d))
        self.assertFalse(bb.utils.contains_any("SOMEFLAG", "x y z", True, False, self.d))


class TaskHash(unittest.TestCase):
    def test_taskhashes(self):
        """
        Return a list of the hashes of the task.

        Args:
            self: (todo): write your description
        """
        def gettask_bashhash(taskname, d):
            """
            Return the hash of the given task.

            Args:
                taskname: (str): write your description
                d: (todo): write your description
            """
            tasklist, gendeps, lookupcache = bb.data.generate_dependencies(d)
            taskdeps, basehash = bb.data.generate_dependency_hash(tasklist, gendeps, lookupcache, set(), "somefile")
            bb.warn(str(lookupcache))
            return basehash["somefile:" + taskname]

        d = bb.data.init()
        d.setVar("__BBTASKS", ["mytask"])
        d.setVar("__exportlist", [])
        d.setVar("mytask", "${MYCOMMAND}")
        d.setVar("MYCOMMAND", "${VAR}; foo; bar; exit 0")
        d.setVar("VAR", "val")
        orighash = gettask_bashhash("mytask", d)

        # Changing a variable should change the hash
        d.setVar("VAR", "val2")
        nexthash = gettask_bashhash("mytask", d)
        self.assertNotEqual(orighash, nexthash)

        d.setVar("VAR", "val")
        # Adding an inactive removal shouldn't change the hash
        d.setVar("BAR", "notbar")
        d.setVar("MYCOMMAND_remove", "${BAR}")
        nexthash = gettask_bashhash("mytask", d)
        self.assertEqual(orighash, nexthash)

        # Adding an active removal should change the hash
        d.setVar("BAR", "bar;")
        nexthash = gettask_bashhash("mytask", d)
        self.assertNotEqual(orighash, nexthash)

        # Setup an inactive contains()
        d.setVar("VAR", "${@bb.utils.contains('VAR2', 'A', 'val', '', d)}")
        orighash = gettask_bashhash("mytask", d)

        # Activate the contains() and the hash should change
        d.setVar("VAR2", "A")
        nexthash = gettask_bashhash("mytask", d)
        self.assertNotEqual(orighash, nexthash)

        # The contains should be inactive but even though VAR2 has a
        # different value the hash should match the original
        d.setVar("VAR2", "B")
        nexthash = gettask_bashhash("mytask", d)
        self.assertEqual(orighash, nexthash)

class Serialize(unittest.TestCase):

    def test_serialize(self):
        """
        Serialize the object to disk.

        Args:
            self: (todo): write your description
        """
        import tempfile
        import pickle
        d = bb.data.init()
        d.enableTracking()
        d.setVar('HELLO', 'world')
        d.setVarFlag('HELLO', 'other', 'planet')
        with tempfile.NamedTemporaryFile(delete=False) as tmpfile:
            tmpfilename = tmpfile.name
            pickle.dump(d, tmpfile)

        with open(tmpfilename, 'rb') as f:
            newd = pickle.load(f)

        os.remove(tmpfilename)

        self.assertEqual(d, newd)
        self.assertEqual(newd.getVar('HELLO'), 'world')
        self.assertEqual(newd.getVarFlag('HELLO', 'other'), 'planet')


# Remote datastore tests
# These really only test the interface, since in actual usage we have a
# tinfoil connector that does everything over RPC, and this doesn't test
# that.

class TestConnector:
    d = None
    def __init__(self, d):
        """
        Initialize the object.

        Args:
            self: (todo): write your description
            d: (int): write your description
        """
        self.d = d
    def getVar(self, name):
        """
        Get a variable by name

        Args:
            self: (todo): write your description
            name: (str): write your description
        """
        return self.d._findVar(name)
    def getKeys(self):
        """
        Return a list of all keys

        Args:
            self: (todo): write your description
        """
        return set(self.d.keys())
    def getVarHistory(self, name):
        """
        Get the history of a variable

        Args:
            self: (todo): write your description
            name: (str): write your description
        """
        return self.d.varhistory.variable(name)
    def expandPythonRef(self, varname, expr, d):
        """
        Expand a variable expression.

        Args:
            self: (todo): write your description
            varname: (str): write your description
            expr: (todo): write your description
            d: (todo): write your description
        """
        localdata = self.d.createCopy()
        for key in d.localkeys():
            localdata.setVar(d.getVar(key))
        varparse = bb.data_smart.VariableParse(varname, localdata)
        return varparse.python_sub(expr)
    def setVar(self, name, value):
        """
        Set a variable.

        Args:
            self: (todo): write your description
            name: (str): write your description
            value: (todo): write your description
        """
        self.d.setVar(name, value)
    def setVarFlag(self, name, flag, value):
        """
        Set a variable

        Args:
            self: (todo): write your description
            name: (str): write your description
            flag: (todo): write your description
            value: (todo): write your description
        """
        self.d.setVarFlag(name, flag, value)
    def delVar(self, name):
        """
        Remove a variable from the dictionary

        Args:
            self: (todo): write your description
            name: (str): write your description
        """
        self.d.delVar(name)
        return False
    def delVarFlag(self, name, flag):
        """
        Delete a variable

        Args:
            self: (todo): write your description
            name: (str): write your description
            flag: (array): write your description
        """
        self.d.delVarFlag(name, flag)
        return False
    def renameVar(self, name, newname):
        """
        Rename a variable

        Args:
            self: (todo): write your description
            name: (str): write your description
            newname: (str): write your description
        """
        self.d.renameVar(name, newname)
        return False

class Remote(unittest.TestCase):
    def test_remote(self):
        """
        Configure the remote connection.

        Args:
            self: (todo): write your description
        """

        d1 = bb.data.init()
        d1.enableTracking()
        d2 = bb.data.init()
        d2.enableTracking()
        connector = TestConnector(d1)

        d2.setVar('_remote_data', connector)

        d1.setVar('HELLO', 'world')
        d1.setVarFlag('OTHER', 'flagname', 'flagvalue')
        self.assertEqual(d2.getVar('HELLO'), 'world')
        self.assertEqual(d2.expand('${HELLO}'), 'world')
        self.assertEqual(d2.expand('${@d.getVar("HELLO")}'), 'world')
        self.assertIn('flagname', d2.getVarFlags('OTHER'))
        self.assertEqual(d2.getVarFlag('OTHER', 'flagname'), 'flagvalue')
        self.assertEqual(d1.varhistory.variable('HELLO'), d2.varhistory.variable('HELLO'))
        # Test setVar on client side affects server
        d2.setVar('HELLO', 'other-world')
        self.assertEqual(d1.getVar('HELLO'), 'other-world')
        # Test setVarFlag on client side affects server
        d2.setVarFlag('HELLO', 'flagname', 'flagvalue')
        self.assertEqual(d1.getVarFlag('HELLO', 'flagname'), 'flagvalue')
        # Test client side data is incorporated in python expansion (which is done on server)
        d2.setVar('FOO', 'bar')
        self.assertEqual(d2.expand('${@d.getVar("FOO")}'), 'bar')
        # Test overrides work
        d1.setVar('FOO_test', 'baz')
        d1.appendVar('OVERRIDES', ':test')
        self.assertEqual(d2.getVar('FOO'), 'baz')


# Remote equivalents of local test classes
# Note that these aren't perfect since we only test in one direction

class RemoteDataExpansions(DataExpansions):
    def setUp(self):
        """
        Set the d1 and d1.

        Args:
            self: (todo): write your description
        """
        self.d1 = bb.data.init()
        self.d = bb.data.init()
        self.d1["foo"] = "value_of_foo"
        self.d1["bar"] = "value_of_bar"
        self.d1["value_of_foo"] = "value_of_'value_of_foo'"
        connector = TestConnector(self.d1)
        self.d.setVar('_remote_data', connector)

class TestRemoteNestedExpansions(TestNestedExpansions):
    def setUp(self):
        """
        Set the d1 and d1.

        Args:
            self: (todo): write your description
        """
        self.d1 = bb.data.init()
        self.d = bb.data.init()
        self.d1["foo"] = "foo"
        self.d1["bar"] = "bar"
        self.d1["value_of_foobar"] = "187"
        connector = TestConnector(self.d1)
        self.d.setVar('_remote_data', connector)

class TestRemoteConcat(TestConcat):
    def setUp(self):
        """
        Set the d1 and d1.

        Args:
            self: (todo): write your description
        """
        self.d1 = bb.data.init()
        self.d = bb.data.init()
        self.d1.setVar("FOO", "foo")
        self.d1.setVar("VAL", "val")
        self.d1.setVar("BAR", "bar")
        connector = TestConnector(self.d1)
        self.d.setVar('_remote_data', connector)

class TestRemoteConcatOverride(TestConcatOverride):
    def setUp(self):
        """
        Set the d1 and d1.

        Args:
            self: (todo): write your description
        """
        self.d1 = bb.data.init()
        self.d = bb.data.init()
        self.d1.setVar("FOO", "foo")
        self.d1.setVar("VAL", "val")
        self.d1.setVar("BAR", "bar")
        connector = TestConnector(self.d1)
        self.d.setVar('_remote_data', connector)

class TestRemoteOverrides(TestOverrides):
    def setUp(self):
        """
        Set the d1 and d1.

        Args:
            self: (todo): write your description
        """
        self.d1 = bb.data.init()
        self.d = bb.data.init()
        self.d1.setVar("OVERRIDES", "foo:bar:local")
        self.d1.setVar("TEST", "testvalue")
        connector = TestConnector(self.d1)
        self.d.setVar('_remote_data', connector)

class TestRemoteKeyExpansion(TestKeyExpansion):
    def setUp(self):
        """
        Set the d1 and d1.

        Args:
            self: (todo): write your description
        """
        self.d1 = bb.data.init()
        self.d = bb.data.init()
        self.d1.setVar("FOO", "foo")
        self.d1.setVar("BAR", "foo")
        connector = TestConnector(self.d1)
        self.d.setVar('_remote_data', connector)

class TestRemoteFlags(TestFlags):
    def setUp(self):
        """
        Reset the d1 and d1.

        Args:
            self: (todo): write your description
        """
        self.d1 = bb.data.init()
        self.d = bb.data.init()
        self.d1.setVar("foo", "value of foo")
        self.d1.setVarFlag("foo", "flag1", "value of flag1")
        self.d1.setVarFlag("foo", "flag2", "value of flag2")
        connector = TestConnector(self.d1)
        self.d.setVar('_remote_data', connector)
