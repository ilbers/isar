# Isar event handlers.
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH
# Copyright (c) Siemens AG, 2018

# If set to 1, the build will fail on mounts found during cleanup,
# keeping those mounts left behind
ISAR_FAIL_ON_CLEANUP ?= "0"

addhandler build_started

python build_started() {
    bb.utils.remove(d.getVar('TMPDIR') + "/work/*/*/*/temp/once.*")
    bb.utils.remove(d.getVar('TMPDIR') + "/work/*/*/*/rootfs.mount")
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

    # bitbake calls cleanup for every multiconfig listed in BBMULTICONFIG plus
    # one for the entire build. E.g., if BBMULTICONFIG="mc1 mc2 mc3", we call
    # "bitbake mc1 mc2", the following cleanups would be called:
    # "c1 c2 c3 cdefault".
    # Skip running cleanup for additional multiconfigs
    mc = d.getVar('BB_CURRENT_MC')
    if mc != 'default':
        return

    fail_on_cleanup = bb.utils.to_boolean(d.getVar('ISAR_FAIL_ON_CLEANUP'))

    basepath = tmpdir + '/work/'

    for line in reversed(list(open('/proc/mounts'))):
        if basepath not in line:
            continue
        msg_line = f"{line.split()[1]} left mounted"
        # If bitbake is started manually, bb.warn and bb.error go to stdout;
        # with bb.error, bitbake additionally fails the build. Under CI,
        # bb.warn and bb.error currently go to a file.
        if fail_on_cleanup:
            bb.error(msg_line)
        else:
            msg_line += ', unmounting...'
            bb.warn(msg_line)
            try:
                subprocess.run(
                    f"sudo umount {line.split()[1]}", shell=True, check=True
                )
            except subprocess.CalledProcessError as e:
                bb.error(str(e))

    # Cleanup build UUID, the next bitbake run will generate new one
    bb.persist_data.persist('BB_ISAR_UUID_DATA', d).clear()
}

build_completed[eventmask] = "bb.event.BuildCompleted"
