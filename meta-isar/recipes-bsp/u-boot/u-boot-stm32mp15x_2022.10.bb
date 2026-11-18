#
# Copyright (c) Siemens AG, 2020
# Copyright (c) 2023-2026 ilbers GmbH
#
# SPDX-License-Identifier: MIT

MAINTAINER = "isar-users <isar-users@googlegroups.com>"

require recipes-bsp/u-boot/u-boot-custom.inc

SRC_URI += "https://git.u-boot-project.org/u-boot/u-boot/-/releases/v${PV}/downloads/u-boot-${PV}.tar.bz2 \
    file://0003-drivers-tee-optee-remove-unused-probe-local-variable.patch \
    file://0004-drivers-tee-optee-discover-OP-TEE-services.patch \
    file://0005-drivers-rng-optee_rng-register-to-CONFIG_OPTEE_SERVI.patch \
    file://0014-ARM-dts-stm32mp-alignment-with-v6.0-rc3.patch \
    file://0016-board-st-stm32mp1-use-of-correct-compatible-string-t.patch \
    file://0017-arm-stm32mp-add-defines-for-BSEC_LOCK-status-in-stm3.patch \
    file://0022-ARM-dts-stm32mp15-update-DDR-node.patch \
    file://0042-ARM-dts-stm32-update-SCMI-dedicated-file.patch \
    file://0053-ARM-dts-stm32-add-sdmmc-cd-gpios-for-STM32MP135F-DK.patch \
    file://0063-dm-pmic-ignore-disabled-node-in-pmic_bind_children.patch \
    file://0069-tee-optee-don-t-fail-probe-because-of-optee-rng.patch \
    file://0070-tee-optee-discover-services-dependent-on-tee-supplic.patch \
    file://0071-optee-bind-the-TA-drivers-on-OP-TEE-node.patch \
    file://0081-ARM-dts-stm32mp15-remove-clksrc-include-in-SCMI-dtsi.patch \
    file://0083-ARM-dts-stm32-Add-timer-interrupts-on-stm32mp15.patch \
    file://0084-stm32mp-cosmetic-Update-of-bsec-driver.patch \
    file://0085-stm32mp-Add-OP-TEE-support-in-bsec-driver.patch \
    file://0092-tee-optee-fix-uuid-comparisons-on-service-discovery.patch \
    file://0095-cmd-clk-probe-the-clock-before-dump-them.patch \
    file://0107-ARM-dts-stm32-fix-node-name-order-and-node-name-and-.patch \
    file://0108-ARM-dts-stm32-reordering-nodes-in-stm32mp151.dtsi-fi.patch \
    file://0110-configs-Resync-with-savedefconfig.patch \
    file://0111-ARM-dts-stm32-remove-stm32mp157-scmi.dtb-from-compil.patch \
    file://0112-ARM-dts-stm32-include-board-scmi.dtsi-in-each-board-.patch \
    file://0113-ARM-dts-stm32-fullfill-diversity-with-OPP-for-STM32M.patch \
    file://0114-ARM-dts-stm32-adapt-stm32mp157a-dk1-board-to-stm32-D.patch \
    file://0117-ARM-dts-stm32-add-stm32mp157d-dk1-board-support.patch \
"

SRC_URI:append:trixie = " \
    file://0003-libfdt-Fix-invalid-version-warning.patch \
    file://0004-scripts-dtc-pylibfdt-libfdt.i_shipped-Use-SWIG_Appen.patch \
"

SRC_URI[sha256sum] = "50b4482a505bc281ba8470c399a3c26e145e29b23500bc35c50debd7fa46bdf8"

DEBIAN_BUILD_DEPENDS += ", swig, python3-setuptools, python3-dev:native, \
    libssl-dev:native, libssl-dev:armhf"

S = "${WORKDIR}/u-boot-${PV}"

U_BOOT_EXTRA_BUILDARGS = "DEVICE_TREE=stm32mp157d-dk1"

COMPATIBLE_MACHINE = "^(stm32mp15x)$"

