# This software is a part of ISAR.
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
        cmdline.append(f"--add-drivers {extra_drivers}")
    if extra_modules:
        cmdline.append(f"--add {extra_modules}")
    return ' '.join(cmdline)

ROOTFS_INITRAMFS_GENERATOR_CMDLINE:append = " ${@ extend_dracut_cmdline(d)}"

inherit initramfs
