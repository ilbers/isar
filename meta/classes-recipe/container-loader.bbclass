# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2024-2025
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

FILESPATH:append = ":${LAYERDIR_core}/recipes-support/container-loader/files"
SRC_URI += " \
    file://container-loader.service.tmpl \
    file://container-loader.sh.tmpl"

DPKG_ARCH ?= "${DISTRO_ARCH}"
DEBIAN_MULTI_ARCH ?= "allowed"

CONTAINER_DELETE_AFTER_LOAD ?= "0"

DEBIAN_DEPENDS += "${CONTAINER_ENGINE_PACKAGES}, zstd"

TEMPLATE_FILES += " \
    container-loader.service.tmpl \
    container-loader.sh.tmpl"
TEMPLATE_VARS += " \
    CONTAINER_ENGINE \
    CONTAINER_DELETE_AFTER_LOAD"

do_install() {
    install -m 755 ${WORKDIR}/container-loader.sh ${D}/usr/share/${BPN}
}
do_install[cleandirs] += " \
    ${D}/usr/share/${BPN} \
    ${D}/usr/share/${BPN}/images"

python do_install_fetched_containers() {
    from oe.path import copyhardlink

    workdir = d.getVar('WORKDIR')
    D = d.getVar('D')
    BPN = d.getVar('BPN')

    image_list = open(D + "/usr/share/" + BPN + "/image.list", "w")

    src_uri = d.getVar('SRC_URI').split()
    for uri in src_uri:
        scheme, host, path, _, _, parm = bb.fetch.decodeurl(uri)
        if scheme != "docker":
            continue

        tag = parm["tag"] if "tag" in parm else "latest"
        image_name = host + (path if path != "/" else "")
        image_file = image_name.replace('/', '.') + \
            ":" + tag + ".zst"
        dest_dir = D + "/usr/share/" + BPN + "/images"

        copyhardlink(workdir + "/" + image_file, dest_dir + "/" + image_file)

        line = f"{image_file} {image_name}:{tag}"
        bb.note(f"adding '{line}' to image.list")
        image_list.write(line + "\n")

    image_list.close()
}

addtask install_fetched_containers after do_install before do_prepare_build

do_prepare_build:append() {
    install -v -m 644 ${WORKDIR}/container-loader.service ${S}/debian/${BPN}.service

    # Do not compress the package, most of its payload is already, and trying
    # nevertheless will only cost time without any gain.
    cat <<EOF >> ${S}/debian/rules
override_dh_builddeb:
	dh_builddeb -- -Znone
EOF
}
