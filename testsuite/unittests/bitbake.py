# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2023
#
# SPDX-License-Identifier: MIT

import sys
import pathlib
from typing import Callable

location = pathlib.Path(__file__).parent.resolve()
sys.path.insert(0, "{}/../../bitbake/lib".format(location))

from bb.parse import handle
from bb.data import init

# Modules added for reimport from testfiles
from bb.data_smart import DataSmart


def load_function(file_name: str, function_name: str) -> Callable:
    """Load a python function defined in a bitbake file.

    Args:
        file_name (str): The path to the file e.g. `meta/classes/my_special.bbclass`.
        function_name (str): The name of the python function without braces e.g. `my_special_function`

    Returns:
        Callable: The loaded function.
    """
    d = init()
    parse = handle("{}/../../{}".format(location, file_name), d)
    if function_name not in parse:
        raise KeyError("Function {} does not exist in {}".format(
            function_name, file_name))
    namespace = {}
    exec(parse[function_name], namespace)
    return namespace[function_name]
