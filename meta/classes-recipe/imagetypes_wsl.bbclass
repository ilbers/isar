# This software is a part of Isar.
# Copyright (C) Siemens AG, 2026
#
# SPDX-License-Identifier: MIT

# This class allows to generate WSL import artifacts.
#

IMAGE_TYPEDEP:wsl = "tar"

IMAGE_CMD:wsl() {
    gzip -f -9 -n -c "${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.tar" > "${IMAGE_FILE_HOST}"
}
