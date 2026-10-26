# Isar Unittests

The unittest Python module adds some simple infrastructure that allows to
unittest Python functions defined in BitBake files.

## Running the tests

Run all Python unit tests with:

```sh
scripts/run-tests.sh -t unittest
```

Or by using the built-in module: `python3 -m unittest discover testsuite/unittests/`.

Run a specific test by its unittest name:

```sh
scripts/run-tests.sh -t unittest -p test=test_image_account_extension.TestImageAccountExtensionImageCreateUsers.test_new_user
```

## Creating new tests

See the [unittest documentation](https://docs.python.org/3/library/unittest.html)
on how to create a test module and name it test_*bitbake_module_name*.py

Use `load_function(file_name, function_name)` from `bitbake.py` to load regular
Python functions from BitBake files.

Example:
```python
from bitbake import load_function

my_function = load_function("meta/classes/my_module.bbclass", "my_function")
my_function(arg1, arg2)
```

Use the [unittest.mock](https://docs.python.org/3/library/unittest.mock.html)
library to mock the bb modules as needed.
