# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT
# Class to generate discoverable disk images (DDI)

DEPENDS += "isar-ddi-definitions"
IMAGER_BUILD_DEPS:ddi += " isar-ddi-definitions"
IMAGER_INSTALL:ddi += " isar-ddi-definitions"

DDI_SIGNING_KEY_PATH ?= ""
DDI_SIGNING_CERTIFICATE_PATH ?= ""
DDI_TYPE ?= "sysext"
DDI_DEFINITION_PATH ?= "/usr/share/isar-ddi-definitions/${DDI_TYPE}.repart.d"
DDI_OUTPUT_IMAGE ?= "${IMAGE_FULLNAME}.ddi"

ddi_not_supported() {
    bberror "IMAGE TYPE DDI is not supported in distribution Release '${BASE_DISTRO_CODENAME}'"
}

create_ddi_image() {
  local_extra_arguments=""
  if [ -n "${DDI_SIGNING_KEY_PATH}" ]; then
    local_extra_arguments="${local_extra_arguments} --private-key=${DDI_SIGNING_KEY_PATH}"
  fi
  if [ -n "${DDI_SIGNING_CERTIFICATE_PATH}" ]; then
    local_extra_arguments="${local_extra_arguments} --certificate=${DDI_SIGNING_CERTIFICATE_PATH}"
  fi

  rm -rf ${DEPLOY_DIR_IMAGE}/${DDI_OUTPUT_IMAGE}

  ${SUDO_CHROOT} << EOF
    if [ -z ${DDI_SIGNING_KEY_PATH} ]; then
      rm -f ${DDI_DEFINITION_PATH}/30-root-verity-sig.conf
    fi
    /usr/bin/systemd-repart \
      --definitions='${DDI_DEFINITION_PATH}' \
      --copy-source=${PP_ROOTFS} \
      --empty=create --size=auto --dry-run=no  \
      --no-pager $local_extra_arguments \
      ${PP_DEPLOY}/${DDI_OUTPUT_IMAGE}
EOF
}

IMAGE_CMD:ddi:buster = "ddi_not_supported"
IMAGE_CMD:ddi:bullseye = "ddi_not_supported"
IMAGE_CMD:ddi:bookworm = "ddi_not_supported"
IMAGE_CMD:ddi = "create_ddi_image"
