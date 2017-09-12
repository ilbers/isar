# This software is a part of ISAR.
# Copyright (C) 2017 Siemens AG

# Install package to dedicated deploy directory
do_install() {
    install -m 644 ${WORKDIR}/*.deb ${DEPLOY_DIR_DEB}/
}

addtask install after do_build
do_install[dirs] = "${DEPLOY_DIR_DEB}"
do_install[stamp-extra-info] = "${MACHINE}"
