#
# Copyright (c) Siemens AG, 2025
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

FILESPATH:append = ":${LAYERDIR_core}/recipes-initramfs/dracut-module/files"

DPKG_ARCH = "all"

DRACUT_MODULE_SETUP = "module-setup.sh"
SRC_URI:append = "file://${DRACUT_MODULE_SETUP}.tmpl"

DRACUT_MODULE_NO ??= "50"
DRACUT_MODULE_NAME ?= "${@ d.getVar('PN')[7:] if d.getVar('PN').startswith('dracut-') else d.getVar('PN')}"

DEBIAN_DEPENDS = "dracut-core"
DRACUT_MODULE_PATH = "${D}/usr/lib/dracut/modules.d/${DRACUT_MODULE_NO}${DRACUT_MODULE_NAME}/"

DRACUT_REQUIRED_BINARIES ??= ""
DRACUT_MODULE_DEPENDENCIES ??= ""
DRACUT_CHECK_CONTENT_FILE_NAME ??= ""
DRACUT_DEPENDS_CONTENT_FILE_NAME ??= ""
DRACUT_CMDLINE_CONTENT_FILE_NAME ??= ""
DRACUT_INSTALL_CONTENT_FILE_NAME ??= ""
DRACUT_INSTALLKERNEL_CONTENT_FILE_NAME ??= ""

def add_file_if_variable_is_set(d, variable_name, prefix):
    variable = d.getVar(variable_name) or ''
    if variable:
        return f"{prefix}{variable}"
    return ''

def replace_marker_with_file_content(template_file, content_file, marker):
    import re, bb

    tmpl = open(template_file).read()
    content = open(content_file).read().rstrip('\n')

    # locate marker and its indentation
    m = re.search(rf'^(?P<indent>\s*){re.escape(marker)}\s*$', tmpl, re.MULTILINE)
    if not m:
        bb.fatal(f"Marker '{marker}' not found in {template_file}")

    indent = m.group('indent')

    # indent all non-blank lines
    indented = '\n'.join(
        (indent + line) if line.strip() else ''
        for line in content.splitlines()
    )

    # replace the exact marker line
    new_tmpl = tmpl[:m.start()] + indented + tmpl[m.end():]

    open(template_file, 'w').write(new_tmpl)

SRC_URI:append = " ${@ add_file_if_variable_is_set(d, 'DRACUT_CHECK_CONTENT_FILE_NAME', 'file://')} \
            ${@ add_file_if_variable_is_set(d, 'DRACUT_DEPENDS_CONTENT_FILE_NAME', 'file://')} \
            ${@ add_file_if_variable_is_set(d, 'DRACUT_CMDLINE_CONTENT_FILE_NAME', 'file://')} \
            ${@ add_file_if_variable_is_set(d, 'DRACUT_INSTALL_CONTENT_FILE_NAME', 'file://')} \
            ${@ add_file_if_variable_is_set(d, 'DRACUT_INSTALLKERNEL_CONTENT_FILE_NAME', 'file://')}"

TEMPLATE_FILES:append = " \
    ${DRACUT_MODULE_SETUP}.tmpl \
    "

TEMPLATE_VARS:append = " \
    DRACUT_REQUIRED_BINARIES \
    DRACUT_MODULE_DEPENDENCIES \
    "
python do_add_additional_dracut_configuration() {
    workdir = os.path.normpath(d.getVar('WORKDIR'))
    module_setup = d.getVar('DRACUT_MODULE_SETUP')
    module_setup_tpml = f"{module_setup}.tmpl"
    content_file_name_to_marker = {
        "DRACUT_CHECK_CONTENT_FILE_NAME" : "# ISAR_DRACUT_CHECK",
        "DRACUT_DEPENDS_CONTENT_FILE_NAME" : "# ISAR_DRACUT_DEPENDS",
        "DRACUT_CMDLINE_CONTENT_FILE_NAME" : "# ISAR_DRACUT_CMDLINE",
        "DRACUT_INSTALL_CONTENT_FILE_NAME" : "# ISAR_DRACUT_INSTALL",
        "DRACUT_INSTALLKERNEL_CONTENT_FILE_NAME" : "# ISAR_DRACUT_KERNELINSTALL"
    }

    for var_name, marker in content_file_name_to_marker.items():
        file_name = d.getVar(var_name) or ''
        if file_name:
            replace_marker_with_file_content(f"{workdir}/{module_setup_tpml}",
                f"{workdir}/{file_name}", marker)
}
addtask add_additional_dracut_configuration before do_transform_template after do_patch

do_install[cleandirs] += "${DRACUT_MODULE_PATH}"
do_install:append() {
    install -m 770 ${WORKDIR}/${DRACUT_MODULE_SETUP} ${DRACUT_MODULE_PATH}
}
