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
        result = True
        with open('/proc/mounts', 'rU') as f:
            for line in f:
                if basepath in line:
                    if subprocess.call('sudo umount ' + line.split()[1],
                                       stdout=devnull, stderr=devnull,
                                       shell=True) != 0:
                        result = False
        return result

    devnull = open(os.devnull, 'w')

    if isinstance(e, bb.event.BuildCompleted):
        tmpdir = d.getVar('TMPDIR', True)

        if tmpdir:
            basepath = tmpdir + '/work/'

            while not umount_all(basepath):
                time.sleep(1)

    devnull.close()
}
