#@TYPE: Machine configuration
#@NAME: nios2

DEFAULTTUNE ?= "nios2"

TUNE_ARCH = "nios2"
TUNE_PKGARCH = "${DEFAULTTUNE}"

# Nios2 R2
TUNEVALID[r2] = "Nios2 R2 support"
TUNECONFLICTS[r2] = "bigendian"
TUNE_CCARGS .= "${@bb.utils.contains("TUNE_FEATURES", "r2", " -march=r2", " -march=r1", d)}"

# Endianess
TUNEVALID[bigendian] = "Enable big-endian mode"
TUNECONFLICTS[bigendian] = "r2"
TUNE_CCARGS .= "${@bb.utils.contains("TUNE_FEATURES", "bigendian", " -meb", " -mel", d)}"

# Multiply opcodes
TUNEVALID[hw-mul] = "Enable Nios2 Hardware Multiply"
TUNEVALID[hw-mulx] = "Enable Nios2 Extended Hardware Multiply"

# Establish which Multiply output result size to use
TUNE_CCARGS .= "${@bb.utils.contains("TUNE_FEATURES", "hw-mul", " -mhw-mul", "" ,d)}"
TUNE_CCARGS .= "${@bb.utils.contains("TUNE_FEATURES", "hw-mulx", " -mhw-mulx", "" ,d)}"

NIOS2PKGMUL_BASIC = "${@bb.utils.contains("TUNE_FEATURES", "hw-mul", "-mul", "" ,d)}"
TUNE_PKGARCH .= "${@bb.utils.contains("TUNE_FEATURES", "hw-mulx", "-mulx", "${NIOS2PKGMUL_BASIC}" ,d)}"

# Divide opcodes
TUNEVALID[hw-div] = "Enable Nios2 hardware divider."
TUNE_CCARGS .= "${@bb.utils.contains("TUNE_FEATURES", "hw-div", " -mhw-div", "" ,d)}"
TUNE_PKGARCH .= "${@bb.utils.contains("TUNE_FEATURES", "hw-div", "-div", "" ,d)}"

# FPU support
TARGET_FPU = "fpu-other"
TUNEVALID[fpu-soft] = "Use Nios2 software FPU"
TUNEVALID[fpu-custom] = "Enable Nios2 hardware FPU"
TUNEVALID[fpu-customdiv] = "Enable Nios2 hardware FPU with divider"

# Establish which fpu is configured in TUNE_FEATURES. Soft is the default for gcc.
NIOS2CCARGSFPU_BASIC = "${@bb.utils.contains("TUNE_FEATURES", "fpu-custom", " -mcustom-fpu-cfg=60-1", "", d)}"
TUNE_CCARGS .= "${@bb.utils.contains("TUNE_FEATURES", "fpu-customdiv", " -mcustom-fpu-cfg=60-2", "${NIOS2CCARGSFPU_BASIC}", d)}"

NIOS2PKGFPU_BASIC = "${@bb.utils.contains("TUNE_FEATURES", "fpu-custom", "-fpu", "", d)}"
TUNE_PKGARCH .= "${@bb.utils.contains("TUNE_FEATURES", "fpu-customdiv", "-fpudiv", "${NIOS2PKGFPU_BASIC}", d)}"

TUNECONFLICTS[fpu-custom] = "fpu-soft fpu-customdiv"
TUNECONFLICTS[fpu-customdiv] = "fpu-soft fpu-custom"

# Nios2 R2 BMX opcodes
TUNEVALID[bmx] = "Enable Nios2 R2 Bit Manipulation Extension."
TUNECONFLICTS[bmx] = "nios2 bigendian"
TUNE_CCARGS .= "${@bb.utils.contains("TUNE_FEATURES", "bmx", " -mbmx", "" ,d)}"
TUNE_PKGARCH .= "${@bb.utils.contains("TUNE_FEATURES", "bmx", "-bmx", "" ,d)}"

# Nios2 R2 CDX opcodes
TUNEVALID[cdx] = "Enable Nios2 R2 Code Density Extension."
TUNECONFLICTS[cdx] = "nios2 bigendian"
TUNE_CCARGS .= "${@bb.utils.contains("TUNE_FEATURES", "cdx", " -mcdx", "" ,d)}"
TUNE_PKGARCH .= "${@bb.utils.contains("TUNE_FEATURES", "cdx", "-cdx", "" ,d)}"

# Architecture configuration
AVAILTUNES += "nios2 nios2eb nios2r2"

TUNEVALID[nios2] = "Nios2 R1 Little-Endian"
TUNE_FEATURES:tune-nios2 = "nios2"
PACKAGE_EXTRA_ARCHS:tune-nios2 = "${TUNE_PKGARCH}"

TUNEVALID[nios2eb] = "Nios2 R1 Big-Endian"
TUNE_FEATURES:tune-nios2eb = "bigendian"
PACKAGE_EXTRA_ARCHS:tune-nios2eb = "${TUNE_PKGARCH}"

TUNEVALID[nios2r2] = "Nios2 R2"
TUNE_FEATURES:tune-nios2r2 = "r2"
PACKAGE_EXTRA_ARCHS:tune-nios2r2 = "${TUNE_PKGARCH}"
