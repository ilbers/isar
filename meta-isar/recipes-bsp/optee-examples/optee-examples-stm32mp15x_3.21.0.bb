#
# Copyright (c) Siemens AG, 2023-2025
#
# SPDX-License-Identifier: MIT
inherit dpkg

DESCRIPTION ?= "OP-TEE examples"

FILESEXTRAPATHS:prepend := "${FILE_DIRNAME}/files:"

SRC_URI += " \
    https://github.com/linaro-swg/optee_examples/archive/${PV}.tar.gz;downloadfilename=optee_examples-${PV}.tar.gz \
    file://debian \
    "
SRC_URI[sha256sum] = "9b965f829adc532b5228534d3b9b38ae1fc4f2ac55d73159a39d43e59749f3ed"

S = "${WORKDIR}/optee_examples-${PV}"

OPTEE_NAME = "stm32mp15x"
OPTEE_PLATFORM = "stm32mp1"
TA_DEV_KIT_DIR = "/usr/lib/optee-os/${OPTEE_NAME}/export-ta_arm32"

PROVIDES += " \
    optee-examples-${OPTEE_NAME}-acipher-host \
    optee-examples-${OPTEE_NAME}-acipher-ta \
    optee-examples-${OPTEE_NAME}-aes-host \
    optee-examples-${OPTEE_NAME}-aes-ta \
    optee-examples-${OPTEE_NAME}-hello-world-host \
    optee-examples-${OPTEE_NAME}-hello-world-ta \
    optee-examples-${OPTEE_NAME}-hotp-host \
    optee-examples-${OPTEE_NAME}-hotp-ta \
    optee-examples-${OPTEE_NAME}-random-host \
    optee-examples-${OPTEE_NAME}-random-ta \
    optee-examples-${OPTEE_NAME}-secure-storage-host \
    optee-examples-${OPTEE_NAME}-secure-storage-ta \
    "

DEPENDS = "optee-os-tadevkit-${OPTEE_NAME} optee-client-${OPTEE_NAME}"
DEBIAN_BUILD_DEPENDS ?= " \
    python3-pycryptodome:native, \
    python3-cryptography:native, \
    optee-client-dev, \
    optee-os-tadevkit-${OPTEE_NAME}"

TEMPLATE_FILES = "debian/control.tmpl debian/rules.tmpl"
TEMPLATE_VARS += "DEBIAN_BUILD_DEPENDS OPTEE_PLATFORM TA_DEV_KIT_DIR DEBIAN_COMPAT DEBIAN_STANDARDS_VERSION"

do_prepare_build() {
    cp -r ${WORKDIR}/debian ${S}/

    deb_add_changelog

    # acipher.install
    echo "acipher/ta/a734eed9-d6a1-4244-aa50-7c99719e7b7b.ta /usr/lib/optee-os/${OPTEE_NAME}/ta" > \
        ${S}/debian/${PN}-acipher-ta.install
    echo "acipher/ta/a734eed9-d6a1-4244-aa50-7c99719e7b7b.stripped.elf /usr/lib/optee-os/${OPTEE_NAME}/ta" >> \
        ${S}/debian/${PN}-acipher-ta.install
    echo "acipher/host/optee_example_acipher /usr/lib/optee-os/${OPTEE_NAME}/ca" > \
        ${S}/debian/${PN}-acipher-host.install

    # aes.install
    echo "aes/ta/5dbac793-f574-4871-8ad3-04331ec17f24.ta /usr/lib/optee-os/${OPTEE_NAME}/ta" > \
        ${S}/debian/${PN}-aes-ta.install
    echo "aes/ta/5dbac793-f574-4871-8ad3-04331ec17f24.stripped.elf /usr/lib/optee-os/${OPTEE_NAME}/ta" >> \
        ${S}/debian/${PN}-aes-ta.install
    echo "aes/host/optee_example_aes /usr/lib/optee-os/${OPTEE_NAME}/ca" > \
        ${S}/debian/${PN}-aes-host.install

    # hello-world.install
    echo "hello_world/ta/8aaaf200-2450-11e4-abe2-0002a5d5c51b.ta /usr/lib/optee-os/${OPTEE_NAME}/ta" > \
        ${S}/debian/${PN}-hello-world-ta.install
    echo "hello_world/ta/8aaaf200-2450-11e4-abe2-0002a5d5c51b.stripped.elf /usr/lib/optee-os/${OPTEE_NAME}/ta" >> \
        ${S}/debian/${PN}-hello-world-ta.install
    echo "hello_world/host/optee_example_hello_world /usr/lib/optee-os/${OPTEE_NAME}/ca" > \
        ${S}/debian/${PN}-hello-world-host.install

    # hotp.install
    echo "hotp/ta/484d4143-2d53-4841-3120-4a6f636b6542.ta /usr/lib/optee-os/${OPTEE_NAME}/ta" > \
        ${S}/debian/${PN}-hotp-ta.install
    echo "hotp/ta/484d4143-2d53-4841-3120-4a6f636b6542.stripped.elf /usr/lib/optee-os/${OPTEE_NAME}/ta" >> \
        ${S}/debian/${PN}-hotp-ta.install
    echo "hotp/host/optee_example_hotp /usr/lib/optee-os/${OPTEE_NAME}/ca" > \
        ${S}/debian/${PN}-hotp-host.install

    # random.install
    echo "random/ta/b6c53aba-9669-4668-a7f2-205629d00f86.ta /usr/lib/optee-os/${OPTEE_NAME}/ta" > \
        ${S}/debian/${PN}-random-ta.install
    echo "random/ta/b6c53aba-9669-4668-a7f2-205629d00f86.stripped.elf /usr/lib/optee-os/${OPTEE_NAME}/ta" >> \
        ${S}/debian/${PN}-random-ta.install
    echo "random/host/optee_example_random /usr/lib/optee-os/${OPTEE_NAME}/ca" > \
        ${S}/debian/${PN}-random-host.install

    # secure-storage.install
    echo "secure_storage/ta/f4e750bb-1437-4fbf-8785-8d3580c34994.ta /usr/lib/optee-os/${OPTEE_NAME}/ta" > \
        ${S}/debian/${PN}-secure-storage-ta.install
    echo "secure_storage/ta/f4e750bb-1437-4fbf-8785-8d3580c34994.stripped.elf /usr/lib/optee-os/${OPTEE_NAME}/ta" >> \
        ${S}/debian/${PN}-secure-storage-ta.install
    echo "secure_storage/host/optee_example_secure_storage /usr/lib/optee-os/${OPTEE_NAME}/ca" > \
        ${S}/debian/${PN}-secure-storage-host.install
}

COMPATIBLE_MACHINE = "^(stm32mp15x)$"
