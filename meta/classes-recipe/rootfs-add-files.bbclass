# This software is a part of Isar.
# Copyright (C) Siemens AG, 2024
# This class allows to add a file directly to
# the rootfs.
# An example usecase would be an installer which
# contains an complete rootfs added with multiconfig.
ROOTFS_INSTALL_COMMAND =+ "rootfs_add_files"
ROOTFS_ADDITIONAL_FILES ??= ""

# ROOTFS_ADDITIONAL_FILES ??= "installer-target"
#
# ROOTFS_ADDITIONAL_FILE_installer-target[source] = \
# "${DEPLOY_DIR_IMAGE}/${IMG_DATA_FILE}.${IMAGE_DATA_POSTFIX}"
# ROOTFS_ADDITIONAL_FILE_installer-target[destination] = \
# "/install/${IMG_DATA_FILE}.${IMAGE_DATA_POSTFIX}"


python rootfs_add_files() {
    cmd = d.getVar('RUN_PRIVILEGED_CMD')
    copy_args = '-a'
    if d.getVar('ISAR_CHROOT_MODE') == 'unshare':
        copy_args += ' --no-preserve=ownership'

    postprocess_additional_files = d.getVar('ROOTFS_ADDITIONAL_FILES').split()
    rootfsdir = d.getVar("ROOTFSDIR")

    for entry in postprocess_additional_files:
        additional_file_entry = f"ROOTFS_ADDITIONAL_FILE_{entry}"
        destination = d.getVarFlag(additional_file_entry, "destination") or ""
        source = d.getVarFlag(additional_file_entry, "source") or ""
        if os.path.exists(f"{rootfsdir}/{destination}"):
            bb.process.run(f"{cmd} /usr/bin/rm -f {rootfsdir}/{destination}")

        dest_dir = os.path.dirname(destination)
        bb.process.run(f"{cmd} /usr/bin/mkdir -p {rootfsdir}/{dest_dir}")
        # empty source creates only an empty destination file
        if not source:
            bb.process.run(f"{cmd} /usr/bin/touch {rootfsdir}/{destination}")
            return

        if not os.path.exists(f"{source}"):
            bb.error(f"{source} does not exists and cannot be copied to the rootfs!")
        # no recursive copy only single files
        bb.process.run(f"{cmd} /usr/bin/cp {copy_args} {source} {rootfsdir}/{destination}")
}
ROOTFS_INSTALL_COMMAND += "rootfs_add_files"
