# Isar event handlers.
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH
# Copyright (c) Siemens AG, 2018

addhandler isar_handler

python isar_handler() {
    import subprocess
    import bb.runqueue

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

isar_handler[eventmask] = "bb.runqueue.runQueueExitWait bb.event.BuildCompleted"
