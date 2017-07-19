# Building Tianocore UEFI Firmware

## Install Build Dependencies

Install the following packages with `sudo apt-get install`:

```
uuid-dev      # /usr/include/uuid/uuid.h
acpica-tools  # /usr/bin/iasl
```

## Build BaseTools

* `BaseTools/Source/C/Makefiles/header.makefile`: Remove `-Werror`
* `make -C BaseTools`


## Initialize Build Environment

`. edksetup.sh`

## Build IA32 Firmware

* `Conf/target.txt`: Edit as follows:
```
ACTIVE_PLATFORM       = OvmfPkg/OvmfPkgIa32.dsc
TARGET                = RELEASE
TARGET_ARCH           = IA32
TOOL_CHAIN_TAG        = GCC49
MAX_CONCURRENT_THREAD_NUMBER = 8
```
* `build`

## Build X64 Firmware

* `Conf/target.txt`: Edit as follows:
```
ACTIVE_PLATFORM       = OvmfPkg/OvmfPkgX64.dsc
TARGET                = RELEASE
TARGET_ARCH           = X64
TOOL_CHAIN_TAG        = GCC49
MAX_CONCURRENT_THREAD_NUMBER = 8
```
* `build`
