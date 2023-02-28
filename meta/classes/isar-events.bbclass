# Isar event handlers.
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH
# Copyright (c) Siemens AG, 2018

addhandler build_started

python build_started() {
    bb.utils.remove(d.getVar('TMPDIR') + "/work/*/*/*/temp/once.*")
    bb.utils.remove(d.getVar('TMPDIR') + "/work/*/*/*/rootfs.mount")
    bb.utils.remove(d.getVar('TMPDIR') + "/deploy/buildchroot-*/*.mount")
}
build_started[eventmask] = "bb.event.BuildStarted"

def task_once_stamp(d):
    return "{temp}/once.{task}".format(temp=d.getVar('T'),
                                       task=d.getVar('BB_RUNTASK'))

addhandler task_started

python task_started() {
    try:
        f = open(task_once_stamp(d), "x")
        f.close()
    except FileExistsError:
        bb.error("Detect multiple executions of %s in %s" %
                 (d.getVar('BB_RUNTASK'), d.getVar('WORKDIR')))
        bb.error("Rerun a clean build with empty STAMPCLEAN " \
                 "and compare the sigdata files")
}
task_started[eventmask] = "bb.build.TaskStarted"

addhandler task_failed

python task_failed() {
    # Avoid false positives if a second target depends on this task and retries
    # the execution after the first failure.
    os.remove(task_once_stamp(d))
}
task_failed[eventmask] = "bb.build.TaskFailed"

addhandler build_completed

python build_completed() {
    import subprocess

    tmpdir = d.getVar('TMPDIR')
    if not tmpdir:
        return

    basepath = tmpdir + '/work/'

    with open('/proc/mounts') as f:
        for line in f.readlines():
            if basepath in line:
                bb.debug(1, '%s left mounted, unmounting...' % line.split()[1])
                subprocess.call(
                    ["sudo", "umount", "-l", line.split()[1]],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )

    # Cleanup build UUID, the next bitbake run will generate new one
    bb.persist_data.persist('BB_ISAR_UUID_DATA', d).clear()
}

build_completed[eventmask] = "bb.event.BuildCompleted"
