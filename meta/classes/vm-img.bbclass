# This software is a part of ISAR.
# Copyright (C) 2019-2020 Siemens AG
#
# This class allows to generate images for VMware and VirtualBox
#

inherit buildchroot
inherit wic-img

FILESEXTRAPATHS_prepend := "${FILE_DIRNAME}/vm-img:"
OVF_TEMPLATE_FILE ?= "vm-img-virtualbox.ovf.tmpl"
SRC_URI += "file://${OVF_TEMPLATE_FILE}"

IMAGER_INSTALL += "qemu-utils gawk uuid-runtime"

# virtual machine disk settings
SOURCE_IMAGE_FILE ?= "${IMAGE_FULLNAME}.wic.img"

# For VirtualBox, this needs to be "monolithicSparse" (default to it).
# VMware needs this to be "streamOptimized".
VMDK_SUBFORMAT ?= "monolithicSparse"

VIRTUAL_MACHINE_IMAGE_TYPE ?= "vmdk"
VIRTUAL_MACHINE_IMAGE_FILE = "${IMAGE_FULLNAME}-disk001.${VIRTUAL_MACHINE_IMAGE_TYPE}"
VIRTUAL_MACHINE_DISK = "${PP_DEPLOY}/${VIRTUAL_MACHINE_IMAGE_FILE}"

def set_convert_options(d):
   format = d.getVar("VIRTUAL_MACHINE_IMAGE_TYPE")
   if format == "vmdk":
      return "-o subformat=%s" % d.getVar("VMDK_SUBFORMAT")
   else:
      return ""


CONVERSION_OPTIONS = "${@set_convert_options(d)}"

do_convert_wic() {
    rm -f '${DEPLOY_DIR_IMAGE}/${VIRTUAL_MACHINE_IMAGE_FILE}'
    image_do_mounts
    bbnote "Creating ${VIRTUAL_MACHINE_IMAGE_FILE} from ${SOURCE_IMAGE_FILE}"
    sudo -E  chroot --userspec=$( id -u ):$( id -g ) ${BUILDCHROOT_DIR} \
    /usr/bin/qemu-img convert -f raw -O ${VIRTUAL_MACHINE_IMAGE_TYPE} ${CONVERSION_OPTIONS} \
        '${PP_DEPLOY}/${SOURCE_IMAGE_FILE}' '${VIRTUAL_MACHINE_DISK}'
}

addtask convert_wic before do_build after do_wic_image do_copy_boot_files do_install_imager_deps do_transform_template

# User settings for OVA
OVA_NAME ?= "${IMAGE_FULLNAME}"
OVA_MEMORY ?= "8192"
OVA_NUMBER_OF_CPU ?= "4"
OVA_VRAM ?= "64"
OVA_FIRMWARE ?= "efi"
OVA_ACPI ?= "true"
OVA_3D_ACCEL ?= "false"
OVA_SHA_ALG = "1"

# Generate random MAC addresses just as VirtualBox does, the format is
# their assigned prefix for the first 3 bytes followed by 3 random bytes.
VBOX_MAC_PREFIX = "080027"

macgen() {
    hexdump -n3 -e "\"${VBOX_MAC_PREFIX}%06X\n\"" /dev/urandom
}

OVA_VARS = "OVA_NAME OVA_MEMORY OVA_NUMBER_OF_CPU OVA_VRAM \
            OVA_FIRMWARE OVA_ACPI OVA_3D_ACCEL \
            OVA_SHA_ALG VIRTUAL_MACHINE_IMAGE_FILE"

# the ovf template is updated with ensubst
# this function adds the variable from OVA_VARS to the environment
python update_environment() {
    template_vars = (d.getVar('OVA_VARS', True) or "").split()
    if len(template_vars) == 0:
        return

    for varname in template_vars:
        value = d.getVar(varname, True)
        if value:
            os.environ.update({varname: value})
}

do_create_ova[prefuncs] += "update_environment"
do_create_ova() {
    if [ ! ${VIRTUAL_MACHINE_IMAGE_TYPE} = "vmdk" ]; then
        exit 0
    fi
    rm -f '${DEPLOY_DIR_IMAGE}/${OVA_NAME}.ova'
    rm -f '${DEPLOY_DIR_IMAGE}/${OVA_NAME}.ovf'
    rm -f '${DEPLOY_DIR_IMAGE}/${OVA_NAME}.mf'

    export PRIMARY_MAC=$(macgen)
    export LAST_CHANGE=$(date -u "+%Y-%m-%dT%H:%M:%SZ")
    export OVA_FIRMWARE_UPPERCASE=$(echo ${OVA_FIRMWARE} | tr '[a-z]' '[A-Z]')

    image_do_mounts

    sudo -Es chroot --userspec=$( id -u ):$( id -g ) ${BUILDCHROOT_DIR} <<'EOSUDO'
        set -e
        export DISK_SIZE_BYTES=$(qemu-img info -f vmdk "${VIRTUAL_MACHINE_DISK}" \
                                 | gawk 'match($0, /^virtual size:.*\(([0-9]+) bytes\)/, a) {print a[1]}')
        export DISK_UUID=$(uuidgen)
        export VM_UUID=$(uuidgen)
        # create ovf
        cat ${PP_WORK}/${OVF_TEMPLATE_FILE} | envsubst > ${PP_DEPLOY}/${OVA_NAME}.ovf
        tar -cvf ${PP_DEPLOY}/${OVA_NAME}.ova -C ${PP_DEPLOY} ${OVA_NAME}.ovf

        # VirtualBox needs here a manifest file. VMware does accept that format.
        if [ "${VMDK_SUBFORMAT}" = "monolithicSparse" ]; then
            echo "SHA${OVA_SHA_ALG}(${VIRTUAL_MACHINE_IMAGE_FILE})=$(sha${OVA_SHA_ALG}sum ${PP_DEPLOY}/${VIRTUAL_MACHINE_IMAGE_FILE} | cut -d' ' -f1)" >> ${PP_DEPLOY}/${OVA_NAME}.mf
            echo "SHA${OVA_SHA_ALG}(${OVA_NAME}.ovf)=$(sha${OVA_SHA_ALG}sum ${PP_DEPLOY}/${OVA_NAME}.ovf | cut -d' ' -f1)" >> ${PP_DEPLOY}/${OVA_NAME}.mf
            tar -uvf ${PP_DEPLOY}/${OVA_NAME}.ova -C ${PP_DEPLOY} ${OVA_NAME}.mf
        fi
        tar -uvf ${PP_DEPLOY}/${OVA_NAME}.ova -C ${PP_DEPLOY} ${VIRTUAL_MACHINE_IMAGE_FILE}
EOSUDO
}

addtask do_create_ova after do_convert_wic before do_deploy
