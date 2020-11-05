"""
BitBake 'Fetch' git annex implementation
"""

# Copyright (C) 2014 Otavio Salvador
# Copyright (C) 2014 O.S. Systems Software LTDA.
#
# SPDX-License-Identifier: GPL-2.0-only
#

import os
import bb
from   bb.fetch2.git import Git
from   bb.fetch2 import runfetchcmd
from   bb.fetch2 import logger

class GitANNEX(Git):
    def supports(self, ud, d):
        """
        Check to see if a given url can be fetched with git.
        """
        return ud.type in ['gitannex']

    def urldata_init(self, ud, d):
        """
        Initialize the udf file.

        Args:
            self: (todo): write your description
            ud: (todo): write your description
            d: (todo): write your description
        """
        super(GitANNEX, self).urldata_init(ud, d)
        if ud.shallow:
            ud.shallow_extra_refs += ['refs/heads/git-annex', 'refs/heads/synced/*']

    def uses_annex(self, ud, d, wd):
        """
        Return true if the given uuid

        Args:
            self: (todo): write your description
            ud: (todo): write your description
            d: (todo): write your description
            wd: (todo): write your description
        """
        for name in ud.names:
            try:
                runfetchcmd("%s rev-list git-annex" % (ud.basecmd), d, quiet=True, workdir=wd)
                return True
            except bb.fetch.FetchError:
                pass

        return False

    def update_annex(self, ud, d, wd):
        """
        .. versionadded

        Args:
            self: (todo): write your description
            ud: (todo): write your description
            d: (todo): write your description
            wd: (todo): write your description
        """
        try:
            runfetchcmd("%s annex get --all" % (ud.basecmd), d, quiet=True, workdir=wd)
        except bb.fetch.FetchError:
            return False
        runfetchcmd("chmod u+w -R %s/annex" % (ud.clonedir), d, quiet=True, workdir=wd)

        return True

    def download(self, ud, d):
        """
        Download a file.

        Args:
            self: (todo): write your description
            ud: (int): write your description
            d: (int): write your description
        """
        Git.download(self, ud, d)

        if not ud.shallow or ud.localpath != ud.fullshallow:
            if self.uses_annex(ud, d, ud.clonedir):
                self.update_annex(ud, d, ud.clonedir)

    def clone_shallow_local(self, ud, dest, d):
        """
        Clone a local repository.

        Args:
            self: (todo): write your description
            ud: (todo): write your description
            dest: (todo): write your description
            d: (todo): write your description
        """
        super(GitANNEX, self).clone_shallow_local(ud, dest, d)

        try:
            runfetchcmd("%s annex init" % ud.basecmd, d, workdir=dest)
        except bb.fetch.FetchError:
            pass

        if self.uses_annex(ud, d, dest):
            runfetchcmd("%s annex get" % ud.basecmd, d, workdir=dest)
            runfetchcmd("chmod u+w -R %s/.git/annex" % (dest), d, quiet=True, workdir=dest)

    def unpack(self, ud, destdir, d):
        """
        Unpack a file or directory.

        Args:
            self: (todo): write your description
            ud: (todo): write your description
            destdir: (str): write your description
            d: (todo): write your description
        """
        Git.unpack(self, ud, destdir, d)

        try:
            runfetchcmd("%s annex init" % (ud.basecmd), d, workdir=ud.destdir)
        except bb.fetch.FetchError:
            pass

        annex = self.uses_annex(ud, d, ud.destdir)
        if annex:
            runfetchcmd("%s annex get" % (ud.basecmd), d, workdir=ud.destdir)
            runfetchcmd("chmod u+w -R %s/.git/annex" % (ud.destdir), d, quiet=True, workdir=ud.destdir)

