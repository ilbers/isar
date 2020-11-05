"""
BitBake Parsers

File parsers for the BitBake build tools.

"""


# Copyright (C) 2003, 2004  Chris Larson
# Copyright (C) 2003, 2004  Phil Blundell
#
# SPDX-License-Identifier: GPL-2.0-only
#
# Based on functions from the base bb module, Copyright 2003 Holger Schurig
#

handlers = []

import errno
import logging
import os
import stat
import bb
import bb.utils
import bb.siggen

logger = logging.getLogger("BitBake.Parsing")

class ParseError(Exception):
    """Exception raised when parsing fails"""
    def __init__(self, msg, filename, lineno=0):
        """
        Initialize a message.

        Args:
            self: (todo): write your description
            msg: (str): write your description
            filename: (str): write your description
            lineno: (int): write your description
        """
        self.msg = msg
        self.filename = filename
        self.lineno = lineno
        Exception.__init__(self, msg, filename, lineno)

    def __str__(self):
        """
        Return a string representation of this file.

        Args:
            self: (todo): write your description
        """
        if self.lineno:
            return "ParseError at %s:%d: %s" % (self.filename, self.lineno, self.msg)
        else:
            return "ParseError in %s: %s" % (self.filename, self.msg)

class SkipRecipe(Exception):
    """Exception raised to skip this recipe"""

class SkipPackage(SkipRecipe):
    """Exception raised to skip this recipe (use SkipRecipe in new code)"""

__mtime_cache = {}
def cached_mtime(f):
    """
    Cached time of a function f.

    Args:
        f: (todo): write your description
    """
    if f not in __mtime_cache:
        __mtime_cache[f] = os.stat(f)[stat.ST_MTIME]
    return __mtime_cache[f]

def cached_mtime_noerror(f):
    """
    Cached cache time.

    Args:
        f: (todo): write your description
    """
    if f not in __mtime_cache:
        try:
            __mtime_cache[f] = os.stat(f)[stat.ST_MTIME]
        except OSError:
            return 0
    return __mtime_cache[f]

def update_mtime(f):
    """
    Update the modification time of a file.

    Args:
        f: (todo): write your description
    """
    try:
        __mtime_cache[f] = os.stat(f)[stat.ST_MTIME]
    except OSError:
        if f in __mtime_cache:
            del __mtime_cache[f]
        return 0
    return __mtime_cache[f]

def update_cache(f):
    """
    Update the cache

    Args:
        f: (str): write your description
    """
    if f in __mtime_cache:
        logger.debug(1, "Updating mtime cache for %s" % f)
        update_mtime(f)

def clear_cache():
    """
    Clear all cached cache.

    Args:
    """
    global __mtime_cache
    __mtime_cache = {}

def mark_dependency(d, f):
    """
    Mark the dependency to the dependency

    Args:
        d: (todo): write your description
        f: (str): write your description
    """
    if f.startswith('./'):
        f = "%s/%s" % (os.getcwd(), f[2:])
    deps = (d.getVar('__depends', False) or [])
    s = (f, cached_mtime_noerror(f))
    if s not in deps:
        deps.append(s)
        d.setVar('__depends', deps)

def check_dependency(d, f):
    """
    Determine if the dependency has_dependency

    Args:
        d: (todo): write your description
        f: (str): write your description
    """
    s = (f, cached_mtime_noerror(f))
    deps = (d.getVar('__depends', False) or [])
    return s in deps
   
def supports(fn, data):
    """Returns true if we have a handler for this file, false otherwise"""
    for h in handlers:
        if h['supports'](fn, data):
            return 1
    return 0

def handle(fn, data, include = 0):
    """Call the handler that is appropriate for this file"""
    for h in handlers:
        if h['supports'](fn, data):
            with data.inchistory.include(fn):
                return h['handle'](fn, data, include)
    raise ParseError("not a BitBake file", fn)

def init(fn, data):
    """
    Initialize a function.

    Args:
        fn: (int): write your description
        data: (todo): write your description
    """
    for h in handlers:
        if h['supports'](fn):
            return h['init'](data)

def init_parser(d):
    """
    Initialize the parser.

    Args:
        d: (todo): write your description
    """
    bb.parse.siggen = bb.siggen.init(d)

def resolve_file(fn, d):
    """
    Resolve a file.

    Args:
        fn: (str): write your description
        d: (todo): write your description
    """
    if not os.path.isabs(fn):
        bbpath = d.getVar("BBPATH")
        newfn, attempts = bb.utils.which(bbpath, fn, history=True)
        for af in attempts:
            mark_dependency(d, af)
        if not newfn:
            raise IOError(errno.ENOENT, "file %s not found in %s" % (fn, bbpath))
        fn = newfn
    else:
        mark_dependency(d, fn)

    if not os.path.isfile(fn):
        raise IOError(errno.ENOENT, "file %s not found" % fn)

    return fn

# Used by OpenEmbedded metadata
__pkgsplit_cache__={}
def vars_from_file(mypkg, d):
    """
    Returns a list of vars from a file.

    Args:
        mypkg: (str): write your description
        d: (str): write your description
    """
    if not mypkg or not mypkg.endswith((".bb", ".bbappend")):
        return (None, None, None)
    if mypkg in __pkgsplit_cache__:
        return __pkgsplit_cache__[mypkg]

    myfile = os.path.splitext(os.path.basename(mypkg))
    parts = myfile[0].split('_')
    __pkgsplit_cache__[mypkg] = parts
    if len(parts) > 3:
        raise ParseError("Unable to generate default variables from filename (too many underscores)", mypkg)
    exp = 3 - len(parts)
    tmplist = []
    while exp != 0:
        exp -= 1
        tmplist.append(None)
    parts.extend(tmplist)
    return parts

def get_file_depends(d):
    '''Return the dependent files'''
    dep_files = []
    depends = d.getVar('__base_depends', False) or []
    depends = depends + (d.getVar('__depends', False) or [])
    for (fn, _) in depends:
        dep_files.append(os.path.abspath(fn))
    return " ".join(dep_files)

from bb.parse.parse_py import __version__, ConfHandler, BBHandler
