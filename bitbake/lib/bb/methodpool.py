#
# Copyright (C)       2006 Holger Hans Peter Freyther
#
# SPDX-License-Identifier: GPL-2.0-only
#

from bb.utils import better_compile, better_exec

def insert_method(modulename, code, fn, lineno):
    """
    Add code of a module should be added. The methods
    will be simply added, no checking will be done
    """
    comp = better_compile(code, modulename, fn, lineno=lineno)
    better_exec(comp, None, code, fn)

compilecache = {}

def compile_cache(code):
    """
    Compile cache.

    Args:
        code: (str): write your description
    """
    h = hash(code)
    if h in compilecache:
        return compilecache[h]
    return None

def compile_cache_add(code, compileobj):
    """
    Compile the given code.

    Args:
        code: (str): write your description
        compileobj: (todo): write your description
    """
    h = hash(code)
    compilecache[h] = compileobj
