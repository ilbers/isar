# Isar event handlers.
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH
# Copyright (c) Siemens AG, 2018

addhandler isar_handler

python isar_handler () {
    import subprocess
    import time

    def umount_all(basepath):
        # '/proc/mounts' contains all the active mounts, so knowing basepath
        # we can get the list of mounts for the specific multiconfig and
        # clean them.
        with open('/proc/mounts', 'rU') as f:
            for line in f:
                if basepath in line:
                    if subprocess.call('sudo umount ' + line.split()[1],
                                       stdout=devnull, stderr=devnull,
                                       shell=True) != 0:
                        return False
        return True

    devnull = open(os.devnull, 'w')

    if isinstance(e, bb.event.BuildCompleted):
        tmpdir = d.getVar('TMPDIR', True)
        distro = d.getVar('DISTRO', True)
        arch = d.getVar('DISTRO_ARCH', True)

        if tmpdir and distro and arch:
            basepath = tmpdir + '/work/' + distro + '-' + arch

            while not umount_all(basepath):
                time.sleep(1)

    devnull.close()
}
