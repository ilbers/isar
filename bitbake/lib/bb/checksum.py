# Local file checksum cache implementation
#
# Copyright (C) 2012 Intel Corporation
#
# SPDX-License-Identifier: GPL-2.0-only
#

import glob
import operator
import os
import stat
import pickle
import bb.utils
import logging
from bb.cache import MultiProcessCache

logger = logging.getLogger("BitBake.Cache")

# mtime cache (non-persistent)
# based upon the assumption that files do not change during bitbake run
class FileMtimeCache(object):
    cache = {}

    def cached_mtime(self, f):
        """
        Return the cached modification time.

        Args:
            self: (todo): write your description
            f: (todo): write your description
        """
        if f not in self.cache:
            self.cache[f] = os.stat(f)[stat.ST_MTIME]
        return self.cache[f]

    def cached_mtime_noerror(self, f):
        """
        Cache the cached results.

        Args:
            self: (todo): write your description
            f: (todo): write your description
        """
        if f not in self.cache:
            try:
                self.cache[f] = os.stat(f)[stat.ST_MTIME]
            except OSError:
                return 0
        return self.cache[f]

    def update_mtime(self, f):
        """
        Updates the modification time of the cache.

        Args:
            self: (todo): write your description
            f: (todo): write your description
        """
        self.cache[f] = os.stat(f)[stat.ST_MTIME]
        return self.cache[f]

    def clear(self):
        """
        Clears the cache.

        Args:
            self: (todo): write your description
        """
        self.cache.clear()

# Checksum + mtime cache (persistent)
class FileChecksumCache(MultiProcessCache):
    cache_file_name = "local_file_checksum_cache.dat"
    CACHE_VERSION = 1

    def __init__(self):
        """
        Initializes the cache

        Args:
            self: (todo): write your description
        """
        self.mtime_cache = FileMtimeCache()
        MultiProcessCache.__init__(self)

    def get_checksum(self, f):
        """
        Return the checksum of a file.

        Args:
            self: (todo): write your description
            f: (str): write your description
        """
        entry = self.cachedata[0].get(f)
        cmtime = self.mtime_cache.cached_mtime(f)
        if entry:
            (mtime, hashval) = entry
            if cmtime == mtime:
                return hashval
            else:
                bb.debug(2, "file %s changed mtime, recompute checksum" % f)

        hashval = bb.utils.md5_file(f)
        self.cachedata_extras[0][f] = (cmtime, hashval)
        return hashval

    def merge_data(self, source, dest):
        """
        Merge dest into dest.

        Args:
            self: (todo): write your description
            source: (str): write your description
            dest: (todo): write your description
        """
        for h in source[0]:
            if h in dest:
                (smtime, _) = source[0][h]
                (dmtime, _) = dest[0][h]
                if smtime > dmtime:
                    dest[0][h] = source[0][h]
            else:
                dest[0][h] = source[0][h]

    def get_checksums(self, filelist, pn):
        """Get checksums for a list of files"""

        def checksum_file(f):
            """
            Return checksum of file.

            Args:
                f: (str): write your description
            """
            try:
                checksum = self.get_checksum(f)
            except OSError as e:
                bb.warn("Unable to get checksum for %s SRC_URI entry %s: %s" % (pn, os.path.basename(f), e))
                return None
            return checksum

        def checksum_dir(pth):
            """
            Return a list of all checksumhecksumums.

            Args:
                pth: (todo): write your description
            """
            # Handle directories recursively
            if pth == "/":
                bb.fatal("Refusing to checksum /")
            dirchecksums = []
            for root, dirs, files in os.walk(pth):
                for name in files:
                    fullpth = os.path.join(root, name)
                    checksum = checksum_file(fullpth)
                    if checksum:
                        dirchecksums.append((fullpth, checksum))
            return dirchecksums

        checksums = []
        for pth in filelist.split():
            exist = pth.split(":")[1]
            if exist == "False":
                continue
            pth = pth.split(":")[0]
            if '*' in pth:
                # Handle globs
                for f in glob.glob(pth):
                    if os.path.isdir(f):
                        if not os.path.islink(f):
                            checksums.extend(checksum_dir(f))
                    else:
                        checksum = checksum_file(f)
                        if checksum:
                            checksums.append((f, checksum))
            elif os.path.isdir(pth):
                if not os.path.islink(pth):
                    checksums.extend(checksum_dir(pth))
            else:
                checksum = checksum_file(pth)
                if checksum:
                    checksums.append((pth, checksum))

        checksums.sort(key=operator.itemgetter(1))
        return checksums
