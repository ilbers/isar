# This software is a part of ISAR.
# Copyright (C) 2025 Siemens
#
# SPDX-License-Identifier: MIT

# sbom type to generate, accepted are "cdx" or "spdx"
SBOM_TYPES ?= "spdx cdx"

SBOM_DEBSBOM_TYPE_ARGS = "${@"-t " + " -t ".join(d.getVar("SBOM_TYPES").split())}"

# general user variables
SBOM_DISTRO_SUPPLIER ?= "ISAR"
SBOM_DISTRO_NAME ?= "ISAR-Debian-GNU-Linux"
SBOM_DISTRO_VERSION ?= "1"
SBOM_DISTRO_SUMMARY ?= "Linux distribution built with ISAR"
SBOM_BASE_DISTRO_VENDOR ??= "debian"
SBOM_DOCUMENT_UUID ?= ""
SBOM_DEBSBOM_EXTRA_ARGS ?= "--with-licenses"

# SPDX specific user variables
SBOM_SPDX_NAMESPACE_PREFIX ?= "https://spdx.org/spdxdocs"

DEPLOY_DIR_SBOM = "${DEPLOY_DIR_IMAGE}"

SBOM_DIR = "${DEPLOY_DIR}/sbom"
SBOM_CHROOT = "${SBOM_DIR}/sbom-chroot"

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

generate_sbom() {
    sudo mkdir -p ${SBOM_CHROOT}/mnt/rootfs ${SBOM_CHROOT}/mnt/deploy-dir

    TIMESTAMP=$(date --iso-8601=s -d @${SOURCE_DATE_EPOCH})
    bwrap \
        --unshare-user \
        --unshare-pid \
        --bind ${SBOM_CHROOT} / \
        --bind ${ROOTFSDIR} /mnt/rootfs \
        --bind ${DEPLOY_DIR_SBOM} /mnt/deploy-dir \
        -- debsbom -v generate ${SBOM_DEBSBOM_TYPE_ARGS} -r /mnt/rootfs -o /mnt/deploy-dir/'${PN}-${DISTRO}-${MACHINE}' \
            --distro-name '${SBOM_DISTRO_NAME}' --distro-supplier '${SBOM_DISTRO_SUPPLIER}' \
            --distro-version '${SBOM_DISTRO_VERSION}' --distro-arch '${DISTRO_ARCH}' \
            --base-distro-vendor '${SBOM_BASE_DISTRO_VENDOR}' \
            --cdx-serialnumber '${SBOM_DOCUMENT_UUID}' \
            --spdx-namespace '${SBOM_SPDX_NAMESPACE_PREFIX}'-'${SBOM_DOCUMENT_UUID}' \
            --timestamp $TIMESTAMP ${SBOM_DEBSBOM_EXTRA_ARGS}
}

do_generate_sbom[dirs] += "${DEPLOY_DIR_SBOM}"
python do_generate_sbom() {
    sbom_doc_uuid(d)
    bb.build.exec_func("generate_sbom", d)
}
