# Isar event handlers.
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

addhandler isar_handler

python isar_handler () {
    import subprocess

    devnull = open(os.devnull, 'w')

    if isinstance(e, bb.event.BuildCompleted):
        tmpdir = d.getVar('TMPDIR', True)
        distro = d.getVar('DISTRO', True)
        arch = d.getVar('DISTRO_ARCH', True)

        w = tmpdir + '/work/' + distro + '-' + arch

        # '/proc/mounts' contains all the active mounts, so knowing 'w' we
        # could get the list of mounts for the specific multiconfig and
        # clean them.
        with open('/proc/mounts', 'rU') as f:
            for line in f:
                if w in line:
                    subprocess.call('sudo umount -f ' + line.split()[1], stdout=devnull, stderr=devnull, shell=True)

    devnull.close()
}
