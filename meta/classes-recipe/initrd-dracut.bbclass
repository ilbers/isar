# This software is a part of Isar.
# This class provides the necessary options to
# customize a dracut based initramfs.
#
# This class should not provide every dracut cmdline
# option possible. Use the dracut configuration files.

INITRAMFS_GENERATOR_PKG = "dracut"

# The preferred way to configure dracut is to
# provide dracut-config-<your-config> package which
# contains all necessary config options
DRACUT_CONFIG_PATH ??= ""

# Variable to add additional kernel driver to the initrd
DRACUT_EXTRA_DRIVERS ??= ""

# Variable to add additional dracut modules to the initrd
DRACUT_EXTRA_MODULES ??= ""

# This option does not work with some of the dracut modules in Debian
# as there is no standardized mapping between module name and package name
DRACUT_EXTRACT_MODULES_FROM_PACKAGE_NAMES ??= "False"

def extend_dracut_cmdline(d):
    config_path = d.getVar('DRACUT_CONFIG_PATH') or ''
    extra_drivers = d.getVar('DRACUT_EXTRA_DRIVERS') or ''
    extra_modules = d.getVar('DRACUT_EXTRA_MODULES') or ''
    enable_module_extraction = bb.utils.to_boolean(d.getVar('DRACUT_EXTRACT_MODULES_FROM_PACKAGE_NAMES'))
    pkg_list = d.getVar('INITRAMFS_INSTALL') or ''

    cmdline = []
    modules_from_pkg_names = []
    if enable_module_extraction:
        for pkg in pkg_list.split():
            # Skip dracut-config-* packages
            if pkg.startswith('dracut-config-'):
                continue
            elif pkg.startswith('dracut-'):
                modules_from_pkg_names.append(pkg[7:])
            elif pkg.endswith('-dracut'):
                modules_from_pkg_names.append(pkg[:-7])
            elif '-dracut-' in pkg:
                _, module_name = pkg.split('-dracut-', 1)
                modules_from_pkg_names.append(module_name)
        extra_modules = extra_modules + ' ' +' '.join(modules_from_pkg_names)

    if config_path:
        cmdline.append(f"--conf {config_path}")
    if extra_drivers:
        cmdline.append(f'--add-drivers "{extra_drivers}"')
    if extra_modules:
        cmdline.append(f'--add "{extra_modules}"')
    return ' '.join(cmdline)

ROOTFS_INITRAMFS_GENERATOR_CMDLINE = "dracut --force --kver $kernel_version -L 5 --reproducible"
ROOTFS_INITRAMFS_GENERATOR_CMDLINE:append = " ${@ extend_dracut_cmdline(d)}"

# Cross-assemble the initramfs, requires preparation of dracut module definitions
def dracut_cross_default(d):
    return bb.utils.to_boolean(d.getVar('ISAR_CROSS_COMPILE')) \
        and bb.utils.to_boolean(d.getVar('ROOTFS_USE_DRACUT')) \
        and d.getVar('ROOTFS_ARCH') != d.getVar('HOST_ARCH')

ROOTFS_DRACUT_CROSS ??= "${@ '1' if dracut_cross_default(d) else '0' }"
ROOTFS_DRACUT_CROSS:bookworm = "0"
OVERRIDES:append = "${@':dracut-cross' if bb.utils.to_boolean(d.getVar('ROOTFS_DRACUT_CROSS')) else ''}"

ROOTFS_INSTALL_DEPENDS:append:dracut-cross = " ${@bb.utils.contains('ROOTFS_INSTALL_COMMAND', 'rootfs_generate_initramfs', '${HOST_TOOLING_DEP}', '', d)}"
ROOTFS_INITRAMFS_GENERATOR_CMDLINE:append:dracut-cross = " --sysroot /mnt/rootfs"
DRACUT_MOUNTS = ""
DRACUT_MOUNTS:append:dracut-cross = " ${ROOTFSDIR}:/mnt/rootfs"
DRACUT_ROOTFS = "${ROOTFSDIR}"
DRACUT_ROOTFS:dracut-cross = "${WORKDIR}/host-tooling"
DRACUT_ENV = "DRACUT_ARCH=${QEMU_ARCH}"
DRACUT_ENV:append:dracut-cross = " \
    DRACUT_INSTALL=/usr/lib/dracut/dracut-install \
    DRACUT_LDD=/usr/libexec/dracut-cross-ldd \
"

run_initrd_generator() {
    mods_total="$(find ${ROOTFSDIR}/usr/lib/dracut/modules.d/ -maxdepth 1 -type d | wc -l)"
    echo "Total number of modules: $mods_total (dracut)"
    if [ "${ROOTFS_DRACUT_CROSS}" = "1" ]; then
        mkdir -p ${DRACUT_ROOTFS}
        run_privileged tar -xf ${HOST_TOOLING_CHROOT} -C ${DRACUT_ROOTFS}
        trap 'run_privileged rm -rf ${DRACUT_ROOTFS}' EXIT
    fi
    run_privileged_heredoc <<'EOF'
        trap '${@ insert_isar_umounts(d, d.getVar('DRACUT_ROOTFS'), d.getVar('DRACUT_MOUNTS')) }' EXIT
        ${@ insert_isar_mounts(d, d.getVar('DRACUT_ROOTFS'), d.getVar('DRACUT_MOUNTS')) }
        export ${DRACUT_ENV}
        chroot ${DRACUT_ROOTFS} ${ROOTFS_INITRAMFS_GENERATOR_CMDLINE}
EOF
}

HOST_TOOLING_DEP ??= ""
inherit_defer ${@'host-tooling' if bb.utils.to_boolean(d.getVar('ROOTFS_DRACUT_CROSS')) else ''}
do_generate_initramfs[depends] += "${HOST_TOOLING_DEP}"
