# This software is a part of Isar.
# Copyright (C) 2025 Siemens
#
# SPDX-License-Identifier: MIT

# sbom type to generate, accepted are "cdx" or "spdx"
SBOM_TYPES ?= "spdx cdx"

SBOM_DEBSBOM_TYPE_ARGS = "${@"-t " + " -t ".join(d.getVar("SBOM_TYPES").split())}"

# general user variables
SBOM_DISTRO_SUPPLIER ?= "isar-users <isar-users@googlegroups.com>"
SBOM_DISTRO_NAME ?= "Isar-Debian-GNU-Linux"
SBOM_DISTRO_VERSION ?= "1"
SBOM_DISTRO_SUMMARY ?= "Linux distribution built with Isar"
SBOM_BASE_DISTRO_VENDOR ??= "debian"
SBOM_DOCUMENT_UUID ?= ""
SBOM_DEBSBOM_EXTRA_ARGS ?= "--with-licenses"

# SPDX specific user variables
SBOM_SPDX_NAMESPACE_PREFIX ?= "https://spdx.org/spdxdocs"

DEPLOY_DIR_SBOM = "${DEPLOY_DIR_IMAGE}"

SBOM_DIR = "${DEPLOY_DIR}/chroot-sbom"
SBOM_CHROOT = "${SBOM_DIR}/${HOST_DISTRO}-${HOST_ARCH}_${DISTRO}-${DISTRO_ARCH}.tar.zst"
SBOM_CHROOT_LOCAL = "${WORKDIR}/chroot-sbom"

# adapted from the isar-cip-core image_uuid.bbclass
def generate_document_uuid(d, warn_not_repr=True):
    import uuid

    base_hash = d.getVar("BB_TASKHASH")
    if base_hash is None:
        if warn_not_repr:
            bb.warn("no BB_TASKHASH available, SBOM UUID is not reproducible")
        return uuid.uuid4()
    return str(uuid.UUID(base_hash[:32], version=4))

def sbom_doc_uuid(d):
    if not d.getVar("SBOM_DOCUMENT_UUID"):
        d.setVar("SBOM_DOCUMENT_UUID", generate_document_uuid(d))

prepare_sbom_chroot() {
    run_privileged_heredoc <<'EOF'
        set -e
        mkdir -p ${SBOM_CHROOT_LOCAL}
        tar -xf ${SBOM_CHROOT} -C ${SBOM_CHROOT_LOCAL}
EOF
}

generate_sbom() {
    run_privileged_heredoc <<'EOF'
        mkdir -p ${SBOM_CHROOT_LOCAL}/mnt/rootfs \
                 ${SBOM_CHROOT_LOCAL}/mnt/deploy-dir
        tar -xf ${WORKDIR}/${ROOTFS_APT_STATE} --zstd \
            -C ${SBOM_CHROOT_LOCAL}/mnt/rootfs
EOF

    TIMESTAMP=$(date --iso-8601=s -d @${SOURCE_DATE_EPOCH})
    bwrap \
        --unshare-user \
        --unshare-pid \
        --bind ${SBOM_CHROOT_LOCAL} / \
        --bind ${DEPLOY_DIR_SBOM} /mnt/deploy-dir \
        -- debsbom -v generate ${SBOM_DEBSBOM_TYPE_ARGS} -r /mnt/rootfs -o /mnt/deploy-dir/'${ROOTFS_PACKAGE_SUFFIX}' \
            --distro-name '${SBOM_DISTRO_NAME}' --distro-supplier '${SBOM_DISTRO_SUPPLIER}' \
            --distro-version '${SBOM_DISTRO_VERSION}' --distro-arch '${DISTRO_ARCH}' \
            --base-distro-vendor '${SBOM_BASE_DISTRO_VENDOR}' \
            --cdx-serialnumber '${SBOM_DOCUMENT_UUID}' \
            --spdx-namespace '${SBOM_SPDX_NAMESPACE_PREFIX}'-'${SBOM_DOCUMENT_UUID}' \
            --timestamp $TIMESTAMP ${SBOM_DEBSBOM_EXTRA_ARGS}
}

cleanup_sbom_chroot() {
    run_privileged rm -rf ${SBOM_CHROOT_LOCAL}
}

do_generate_sbom[dirs] += "${DEPLOY_DIR_SBOM}"
do_generate_sbom[network] = "${TASK_USE_SUDO}"
do_generate_sbom[depends] += "sbom-chroot:do_sbomchroot_deploy"
python do_generate_sbom() {
    sbom_doc_uuid(d)
    try:
        bb.build.exec_func("prepare_sbom_chroot", d)
        bb.build.exec_func("generate_sbom", d)
    finally:
        bb.build.exec_func("cleanup_sbom_chroot", d)
}

# The sbom generator uses the apt state captured during do_rootfs_install,
# so it can run as a standalone task afterwards
python() {
    if 'generate-sbom' in d.getVar('ROOTFS_FEATURES').split():
        bb.build.addtask('do_generate_sbom', 'do_rootfs', 'do_rootfs_install', d)
}
