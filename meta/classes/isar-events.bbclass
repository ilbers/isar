# Isar event handlers.
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH
# Copyright (c) Siemens AG, 2018

addhandler build_completed

python build_completed() {
    import subprocess

    tmpdir = d.getVar('TMPDIR', True)
    if not tmpdir:
        return

    basepath = tmpdir + '/work/'

    with open('/proc/mounts') as f:
        for line in f.readlines():
            if basepath in line:
                subprocess.call(
                    ["sudo", "umount", "-l", line.split()[1]],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
}

build_completed[eventmask] = "bb.event.BuildCompleted"
