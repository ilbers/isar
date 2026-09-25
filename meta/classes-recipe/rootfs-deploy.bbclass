# This software is a part of Isar.
# Copyright (c) Siemens AG, 2026
#
# Inherit this class to deploy the rootfs as a compressed tarball
# and remove the (local) extracted rootfs after deployment.

ROOTFS_TAR_FLAGS ?= ""
ROOTFS_ZSTD_CLEVEL ?= "8"
ROOTFS_DEPLOY_DIR ?= "${DEPLOY_DIR}/chroot-${PN}"
ROOTFS_DEPLOY_FILE ?= "${ROOTFS_DEPLOY_DIR}/${HOST_DISTRO}-${HOST_ARCH}_${DISTRO}-${DISTRO_ARCH}.tar.zst"

do_rootfs_deploy[dirs] = "${ROOTFS_DEPLOY_DIR}"
do_rootfs_deploy[network] = "${TASK_USE_SUDO}"
do_rootfs_deploy() {
    # deploy with empty var to make it smaller
    lopts="--one-file-system"
    ZSTD="zstd -${ROOTFS_ZSTD_CLEVEL} -T${ZSTD_THREADS}"

    run_privileged \
        tar -C ${ROOTFSDIR} -cpS $lopts ${ROOTFS_TAR_FLAGS} . \
            | $ZSTD > ${ROOTFS_DEPLOY_FILE}
    # cleanup extracted rootfs
    run_privileged rm -rf ${ROOTFSDIR}
}
addtask do_rootfs_deploy before do_build after do_rootfs

CLEANFUNCS += "rootfs_deploy_clean"
rootfs_deploy_clean() {
    rm -rf ${ROOTFS_DEPLOY_FILE}
}
