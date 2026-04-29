# This software is a part of Isar.
# Copyright (C) 2026 ilbers GmbH
#
# SPDX-License-Identifier: MIT

KERNEL_DEPLOY_DIR ?= "${DEPLOY_DIR_IMAGE}/kernel-${KERNEL_NAME_PROVIDED}"

KERNEL_LOCATION ?= "./boot"
KERNEL_DEB ?= "linux-image-${KERNEL_NAME_PROVIDED}_${CHANGELOG_V}_${DISTRO_ARCH}.deb"

DEPLOY_WILDCARDS = "'${KERNEL_LOCATION}/vmlinu[xz]-*'"
DEPLOY_WILDCARDS += "${@(' '.join("'*%s'" % p for p in (d.getVar('DTB_FILES') or '').split()))}"

do_deploy_kernel[dirs] = "${KERNEL_DEPLOY_DIR}"
do_deploy_kernel() {
       case "${PROVIDES}" in
               *linux-image-${KERNEL_NAME_PROVIDED}*)
                       dpkg --fsys-tarfile ${WORKDIR}/${KERNEL_DEB} | \
                               tar xvf - -C "${KERNEL_DEPLOY_DIR}" \
                                       --transform='s|^.*/||' \
                                       --wildcards ${DEPLOY_WILDCARDS}
               ;;
       esac
}
addtask deploy_kernel before do_deploy_deb after do_dpkg_build
