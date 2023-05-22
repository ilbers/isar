# Isar Unittests

The unittest python module adds some simple infrastructure that allows to
unittest python functions defined in bitbake files.

## Running the tests

You can run the tests using avocado with `avocado --show=app,test run testsuite/unittests/`
or by using the buildin module with `python3 -m unittest discover testsuite/unittests/`

## Creating new tests

See the [unittest documentation](https://docs.python.org/3/library/unittest.html)
on how to create a test module and name it test_*bitbake_module_name*.py

Use the function `load_function(file_name: str, function_name: str) -> Callable`
in the bitbake module to load the function.

Example:
```python
from bitbake import load_function

my_function = load_function("meta/classes/my_module.bbclass", "my_function")
my_function(arg1, arg2)
```

Use the [unittest.mock](https://docs.python.org/3/library/unittest.mock.html)
library to mock the bb modules as needed.
