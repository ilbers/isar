# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

UBINIZE_CFG ??= "ubinize.cfg"

IMAGER_INSTALL_ubi += "mtd-utils"

# Generate ubi filesystem image
IMAGE_CMD_ubi() {
    if [ ! -e "${WORKDIR}/${UBINIZE_CFG}" ]; then
        die "UBINIZE_CFG does not contain ubinize config file."
    fi

    ${SUDO_CHROOT} /usr/sbin/ubinize ${UBINIZE_ARGS} \
                -o '${IMAGE_FILE_CHROOT}' '${PP_WORK}/${UBINIZE_CFG}'
}
IMAGE_CMD_ubi[depends] = "${PN}:do_transform_template"
IMAGE_CMD_REQUIRED_ARGS_ubi = "UBINIZE_ARGS"
