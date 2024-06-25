require recipes-kernel/linux/linux-mainline_6.6.11.bb

SRC_URI:remove = "file://ftpm-module.cfg"
SRC_URI:remove = "file://subdir/no-ubifs-fs.cfg"

check_fragments_applied() {
    echo "Kernel config fragments checking disabled"
}

KERNEL_DEFCONFIG = "imx_v6_v7_defconfig"

LINUX_VERSION_EXTENSION = "-isar"

COMPATIBLE_MACHINE = "phyboard-mira"
