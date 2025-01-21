# Custom kernel recipe for Isar

## Contents

 - [Summary](#summary)
 - [Features](#features)
 - [Future](#future)
 - [Examples](#examples)

## Summary

Isar provides a recipe to build custom kernels for Debian-based distributions.
It uses templates to generate the debian meta-data (such as debian/control) and
Debian's [BuildProfiles](https://wiki.debian.org/BuildProfileSpec) to handle
some of the distro specific variations. It should be noted that Isar has moved
away from using the kernel's builddeb script since it would not generate all
the packages we need (and in particular perf).

## Features

The linux-custom recipe provides support for:

 1. Sources to the custom Linux kernel may be specified via `SRC_URI`

 2. Configure the kernel via an in-tree or an external `defconfig` via
    `KERNEL_DEFCONFIG`

 3. Integrate kernel configuration tweaks via configuration fragments (`.cfg`
    files)

 4. Patches to the linux kernel may be specified via `SRC_URI`

 5. Ensure that the Isar recipe `PV` matches the kernel release identifier
    (`KERNEL_RELEASE`)

 6. Produce a `linux-image` package that ships the kernel image and modules

 7. Allow the name of the kernel image to be changed via `KERNEL_FILE` (defaults
    to `vmlinuz`)

 8. Produce a `linux-headers` package which includes kernel headers

 9. Produce a `linux-kbuild` package for both `target` and `host` arch
    which includes kbuild scripts and tools.
    Using `linux-kbuild` provides the package for the target and when
    cross building `linux-kbuild-native` provides the package for the host.

    So the `linux-headers` package supports native and cross compiles of
    out-of-tree kernel modules. Even, when built in cross-compilation mode,
    it can be used on the target using the `linux-kbuild` package.

    Only the `host` specific package is built automatically at cross builds.

 10. Produce a `linux-libc-dev-${KERNEL_NAME}` package to support user-land builds

 11. Only build/ship the `linux-libc-dev-${KERNEL_NAME}` package if instructed to
     (`KERNEL_LIBC_DEV_DEPLOY` equals to `"1"`)

 12. Support both native and cross compiles (`ISAR_CROSS_COMPILE`)

 13. Support for the following kernel architectures:

   * arm
   * arm64
   * mips
   * x86
   * riscv

 14. Support `devshell` (kernel configuration shall be applied)

## Future

In the future, the recipe may be extended to:

 1. Package perf

 2. Support inclusion/build of dts files listed in `SRC_URI`

 3. Be compatible with Ubuntu

## Examples

The linux-custom recipe is currently used by the linux-mainline package and is
used mainline recipe may be used for some basic testing. This recipe is being
used by the following machines:

 * sifive-fu540
 * stm32mp15x
 * de0-nano-soc
 * hikey
