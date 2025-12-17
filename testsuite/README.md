# Install Avocado

The framework could be installed by using standard HOWTO:

  https://github.com/avocado-framework/avocado#installing-with-standard-python-tools

## For Debian (tested on Debian 11.x)

```
$ sudo apt-get update -qq
$ sudo apt-get install -y virtualenv
$ rm -rf /tmp/avocado_venv
$ virtualenv --python python3 /tmp/avocado_venv
$ source /tmp/avocado_venv/bin/activate
$ pip install avocado-framework==100.1
```

# Run test

## Quick developers test

```
$ avocado run ../testsuite/citest.py -t dev --max-parallel-tasks=1
```

## Single target test

```
$ avocado run ../testsuite/citest.py -t single --max-parallel-tasks=1 -p machine=qemuamd64 -p distro=bullseye
# Generate bitbake dependency graph as well
# The output will be in build_dir/{task-depends-<testname>.dot, pn-buildlist-<testname>}
$ avocado run ../testsuite/citest.py -t single --max-parallel-tasks=1 -p machine=qemuamd64 -p distro=bullseye -p depgraph=1
```

## Fast build test

```
$ avocado run ../testsuite/citest.py -t fast --max-parallel-tasks=1
```

## Full build test

```
$ avocado run ../testsuite/citest.py -t full --max-parallel-tasks=1
```

## Fast boot test

```
$ avocado run ../testsuite/citest.py -t startvm,fast
```

## Full boot test

```
$ avocado run ../testsuite/citest.py -t startvm,full
```

# Running qemu images

## Manual running

There is a tool start_vm which is the replacement for the bash script in
`isar/scripts` directory. It can be used to run image previously built:

```
start_vm -a amd64 -b /build -d bullseye -i isar-image-base
```

# Tests for running commands under qemu images

Package `isar-image-ci` configures `ci` user with non-interactive SSH access
to the machine. Image `isar-image-ci` preinstalls this package.

Example of test that runs qemu image and executes remote command under it:

```
    def test_getty_target(self):
        self.init()
        self.vm_start('amd64','bookworm', \
            image='isar-image-ci',
            cmd='systemctl is-active getty.target')
```

To run something more complex than simple command, custom test script
can be executed instead of command:

```
    def test_getty_target(self):
        self.init()
        self.vm_start('amd64','bookworm', \
            image='isar-image-ci',
            script='test_systemd_unit.sh getty.target 10')
```

The default location of custom scripts is `isar/testsuite/`. It can be changed
by passing `-p test_script_dir="custom_path"` to `avocado run`
arguments.

# Custom test case creation

The minimal build test can be look like:

```
#!/usr/bin/env python3

from cibase import CIBaseTest

class SampleTest(CIBaseTest):
    def test_sample(self):
        self.init()
        self.perform_build_test("mc:qemuamd64-bullseye:isar-image-base")
```

To show the list of available tests you can run:

```
$ avocado list sample.py
avocado-instrumented sample.py:SampleTest.test_sample
```

And to execute this example:

```
$ avocado run sample.py:SampleTest.test_sample
```

## Using a different directory for custom testcases

Downstreams may want to keep their testcases in a different directory
(e.g. `./test/sample.py` as top-level with test description) but reuse
classes implemented in Isar testsuite (e.g. `./isar/testsuite/*.py`). This is
a common case for downstream that use `kas` to handle layers they use.

In this case it's important to adjust `PYTHONPATH` variable before running
avocado so that isar testsuite files could be found:

```
# TESTSUITEDIR="/work/isar/testsuite"
export PYTHONPATH=${PYTHONPATH}:${TESTSUITEDIR}
```

# Code style for testcases

Recommended Python code style for the testcases is based on
[PEP8 Style Guide for Python Code](https://peps.python.org/pep-0008) with
several additions described below.

## Using quotes

Despite [PEP8](https://peps.python.org/pep-0008) doesn't have any string quote
usage recommendations, Isar preferred style is the following:

 - Single quotes for data and small symbol-like strings.
 - Double quotes for human-readable strings and string interpolation.

## Line wrapping

Argument lists that don't fit in the 79 characters line limit should be placed
on the new line, keeping them on the same line if possible. Otherwise every
single argument should be placed in separate line.

## String formatting

Use format strings (f"The value is {x}") instead of printf-style formatting
("The value is %d" % x) or string concatenations ("The value is " + str(x)).

## Function definition spacing

Any function and class definition should be done in the following way:

 - One line before and after inner functions.
 - Two lines before and after module-level functions and classes.

## Tools for checking code style

To check the compliance with PEP8 standards:

```
$ flake8 sample.py
```

To format the code to recommended code style:

```
$ black -S -l 79 sample.py
```

Black use it's own [code style](https://black.readthedocs.io/en/stable/the_black_code_style/current_style.html)
based on [PEP8](https://peps.python.org/pep-0008), so some options should be
used to set non-default style checking behaviour.

# Example of the downstream testcase

See `meta-isar/test` for an example of the testcase for kas-based downstream.
