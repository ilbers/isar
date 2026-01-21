# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019-2025
#
# SPDX-License-Identifier: MIT
#
# This file extends the image.bbclass to supply tools for futher imager functions

inherit sbuild

IMAGER_INSTALL ??= ""
IMAGER_BUILD_DEPS ??= ""

do_image_tools[depends] += " \
    ${@' '.join(dep + ':do_deploy_deb' for dep in d.getVar('IMAGER_BUILD_DEPS').split())}"

SCHROOT_MOUNTS = "${WORKDIR}:${PP_WORK} ${IMAGE_ROOTFS}:${PP_ROOTFS} ${DEPLOY_DIR_IMAGE}:${PP_DEPLOY}"
SCHROOT_MOUNTS += "${REPO_ISAR_DIR}/${DISTRO}:/isar-apt"

imager_run() {
    local_install="${@(d.getVar("INSTALL_%s" % d.getVar("BB_CURRENTTASK")) or '').strip()}"
    local_bom="${@(d.getVar("BOM_%s" % d.getVar("BB_CURRENTTASK")) or '').strip()}"

    schroot_create_configs
    insert_mounts

    session_id=$(schroot -q -b -c ${SBUILD_CHROOT})
    echo "Started session: ${session_id}"

    # Schroot session mountpoint for deb downloads import/export
    schroot_dir="/var/run/schroot/mount/${session_id}"

    # setting up error handler
    imager_cleanup() {
        set +e
        schroot -q -f -e -c ${session_id} > /dev/null 2>&1
        remove_mounts > /dev/null 2>&1
        schroot_delete_configs > /dev/null 2>&1
    }
    trap 'exit 1' INT HUP QUIT TERM ALRM USR1
    trap 'imager_cleanup' EXIT

    if [ -n "${local_install}" ]; then
        echo "Installing imager deps: ${local_install}"

        distro="${BASE_DISTRO}-${BASE_DISTRO_CODENAME}"
        if [ ${ISAR_CROSS_COMPILE} -eq 1 ]; then
            distro="${HOST_BASE_DISTRO}-${BASE_DISTRO_CODENAME}"
        fi

        E="${@ isar_export_proxies(d)}"
        deb_dl_dir_import ${schroot_dir} ${distro}
        ${SCRIPTSDIR}/lockrun.py -r -f "${REPO_ISAR_DIR}/isar.lock" -s <<EOAPT
        schroot -r -c ${session_id} -d / -u root -- sh -c " \
            apt-get update \
                -o Dir::Etc::SourceList='sources.list.d/isar-apt.list' \
                -o Dir::Etc::SourceParts='-' \
                -o APT::Get::List-Cleanup='0'
            apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y \
                --allow-unauthenticated --allow-downgrades --download-only install \
                ${local_install}"
EOAPT

        deb_dl_dir_export ${schroot_dir} ${distro}
        schroot -r -c ${session_id} -d / -u root -- sh -c " \
            apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y \
                --allow-unauthenticated --allow-downgrades install \
                ${local_install}"
    fi

    schroot -r -c ${session_id} "$@"

    if [ -n "${local_bom}" ]; then
        schroot -r -c ${session_id} -d / -- \
            dpkg-query -W -f='${source:Package}|${source:Version}|${Package}:${Architecture}|${Version}\n' ${local_bom} > \
        ${WORKDIR}/imager.manifest

        ${@bb.utils.contains('ROOTFS_FEATURES', 'generate-sbom', 'generate_imager_sbom', '', d)}
    fi

    schroot -e -c ${session_id}

    remove_mounts
    schroot_delete_configs
}

generate_imager_sbom() {
    TIMESTAMP=$(date --iso-8601=s -d @${SOURCE_DATE_EPOCH})
    sbom_document_uuid="${@d.getVar('SBOM_DOCUMENT_UUID') or generate_document_uuid(d, False)}"
    bwrap \
        --unshare-user \
        --unshare-pid \
        --bind ${SBOM_CHROOT} / \
        --bind $schroot_dir /mnt/rootfs \
        --bind ${WORKDIR} /mnt/deploy-dir \
        -- debsbom -vv generate ${SBOM_DEBSBOM_TYPE_ARGS} \
            --from-pkglist -r /mnt/rootfs -o /mnt/deploy-dir/imager \
            --distro-name '${SBOM_DISTRO_NAME}-Imager' --distro-supplier '${SBOM_DISTRO_SUPPLIER}' \
            --distro-version '${SBOM_DISTRO_VERSION}' --distro-arch '${DISTRO_ARCH}' \
            --base-distro-vendor '${SBOM_BASE_DISTRO_VENDOR}' \
            --cdx-serialnumber $sbom_document_uuid \
            --spdx-namespace '${SBOM_SPDX_NAMESPACE_PREFIX}'-$sbom_document_uuid \
            --timestamp $TIMESTAMP ${SBOM_DEBSBOM_EXTRA_ARGS} \
    < ${WORKDIR}/imager.manifest
}
