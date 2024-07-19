# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2023
#
# SPDX-License-Identifier: MIT

import os
import sys
from typing import Callable

location = os.path.dirname(__file__)
sys.path.append(os.path.join(location, "../../bitbake/lib"))

from bb.parse import handle
from bb.data import init


def load_function(file_name: str, function_name: str) -> Callable:
    """Load a python function defined in a bitbake file.

    Args:
        file_name (str): The path to the file
                         e.g. `meta/classes/my_special.bbclass`.
        function_name (str): The name of the python function without braces
                         e.g. `my_special_function`

    Returns:
        Callable: The loaded function.
    """
    d = init()
    parse = handle(f"{location}/../../{file_name}", d)
    if function_name not in parse:
        raise KeyError(
            f"Function {function_name} does not exist in {file_name}"
        )
    namespace = {}
    exec(parse[function_name], namespace)
    return namespace[function_name]
