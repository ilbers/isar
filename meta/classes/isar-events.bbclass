# Isar event handlers.
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

addhandler isar_handler

python isar_handler () {
    import subprocess

    devnull = open(os.devnull, 'w')

    if isinstance(e, bb.event.BuildCompleted):
        bchroot = d.getVar('BUILDCHROOT_DIR', True)

        # Clean up buildchroot
        subprocess.call('/usr/bin/sudo /bin/umount ' + bchroot + '/isar-apt || /bin/true', stdout=devnull, stderr=devnull, shell=True)

    devnull.close()
}
