# This software is a part of Isar.
# Copyright (C) 2026 ilbers GmbH
#
# SPDX-License-Identifier: MIT

DEPLOYDIR = "${WORKDIR}/deploy_${@ d.getVar('MACHINE').replace('-','_') or ''}"
KERNEL_DEPLOY_TASKNAME ?= "do_deploy_kernel_${@ d.getVar('MACHINE').replace('-','_') or ''}"
SSTATETASKS += "${KERNEL_DEPLOY_TASKNAME}"

python () {
    kernel_name = d.getVar('KERNEL_NAME_PROVIDED') or ''
    if "linux-image-"+kernel_name in d.getVar('PROVIDES'):
        task = d.getVar('KERNEL_DEPLOY_TASKNAME')
        d.setVar(task, d.expand('kernel_deploy'))
        d.setVarFlag(task, 'func', '1')
        d.setVarFlag(task, 'sstate-inputdirs', d.getVar('DEPLOYDIR'))
        d.setVarFlag(task, 'sstate-outputdirs', d.getVar('KERNEL_DEPLOY_DIR'))
        d.appendVarFlag(task, 'cleandirs', d.getVar('DEPLOYDIR'))
        d.appendVarFlag(task, 'stamp-extra-info', d.getVar('MACHINE'))
        bb.build.addtask(task, 'do_build', 'do_dpkg_build', d)
}

KERNEL_DEPLOY_DIR ?= "${DEPLOY_DIR_IMAGE}/kernel-${KERNEL_NAME_PROVIDED}"

KERNEL_LOCATION ?= "./boot"
KERNEL_DEB ?= "linux-image-${KERNEL_NAME_PROVIDED}_${CHANGELOG_V}_${DISTRO_ARCH}.deb"

# Take care the case when requested kernel format doesn't match distro one
DEPLOY_WILDCARDS = "'${KERNEL_LOCATION}/${@ 'vmlinu[xz]*' if (p := d.getVar('KERNEL_FILE')) == 'vmlinux' else p+'*'}'"
DEPLOY_WILDCARDS += "${@(' '.join("'*%s'" % p for p in (d.getVar('DTB_FILES') or '').split()))}"

kernel_deploy() {
       case "${PROVIDES}" in
               *linux-image-${KERNEL_NAME_PROVIDED}*)
                       dpkg --fsys-tarfile ${WORKDIR}/${KERNEL_DEB} | \
                               tar xvf - -C "${DEPLOYDIR}" \
                                       --transform='s|^.*/||' \
                                       --wildcards ${DEPLOY_WILDCARDS}
               ;;
       esac
}

python do_copy_boot_files_setscene () {
    sstate_setscene(d)
}
addtask do_copy_boot_files_setscene
