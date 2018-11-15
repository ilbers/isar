Recipe API Changelog
====================

Baseline: Release v0.5

Upcoming changes (v0.7)
-----------------------

### dpkg-raw recipes build method changed

These packages are now built using the whole dpkg-buildpackage workflow, and
not just packaged as before.

 - all files will be owned by root:root before it might have been 1000:1000
   use postinst to change that (see example-raw)
 - a lot of debhelpers will help .. or complain
   fix the issues or override the helpers (see example-raw)

### location of image artifacts

Align with OpenEmbedded and place image artifacts in a per-machine folder placed
in tmp/deploy (to avoid collisions among other things).

### more consistent artifact names

multiconfig image artifacts are all placed in tmp/deploy/images. They include
kernel, initrd and ext4/wic images. A consistent naming scheme is now used:
`IMAGE-DISTRO-MACHINE.TYPE`. This scheme was already used for ext4/wic images
so no visible changes there. Kernel and initrd images are however affected; for
instance:

```
vmlinuz-4.9.0-8-armmp_debian-stretch-qemuarm
```

is now

```
isar-image-base-debian-stretch-qemuarm.vmlinuz-4.9.0-8-armmp
```

It should be noted that the `KERNEL_IMAGE` and `INITRD_IMAGE` variables were
updated hence recipes using them shouldn't be impacted per se.

Changes in v0.6
---------------

### Separate do_prepare_build task

All Debianizations of source trees and any further programmatic patching has to
be moved from the dpkg_runbuild() task to this new task.

### ISAR_CROSS_COMPILE support

Isar now supports cross-compilation. When enabled via `ISAR_CROSS_COMPILE = "1"`
in a global configuration file, all recipes that do not overwrite this variable
will build cross-compiled.

If a recipe is not cross-compatible, it should set `ISAR_CROSS_COMPILE = "0"`.
Then also all its dependencies that are built by Isar must opt out from
cross-building.

### wic image type, removal of manual wic invocation

Images that are described by wic files are now generated during the build by
setting `IMAGE_TYPE = "wic-img"`. The manual invocation of wic after the
bitbake run is no longer needed nor supported.

### Optional kernel installation

The installation of a Linux kernel into the isar-image-base can be skipped by
setting `KERNEL_NAME = ""`.

### Corrected semantic of `S`

The `S` variable is now defined as NOT including `WORKDIR`, like in OE, Gentoo
and others. If it was set to, e.g., `S = "sources"` in a recipe so far, it must
be defined as `S = ${WORKDIR}/sources` from now on.

### DISTRO and DISTRO_ARCH are available as OVERRIDES

Bitbake variables can now also refer to the DISTRO as well as the DISTRO_ARCH
for overrides.

### Set ISAR_RELEASE_CMD in own top-layer

Isar now populates /etc/os-release with information about the image. In order
to identify the revision of the top layer that controlled the image build with
all its dependencies, set ISAR_RELEASE_CMD so that it picks up the required
information.

If the top-layer is managed in git, set `LAYERDIR_mylayer = "${LAYERDIR}"` in
`conf/layer.conf` and add something along

    ISAR_RELEASE_CMD = "git -C ${LAYERDIR_mylayer} describe --tags --dirty \
                            --match 'v[0-9].[0-9]*'"

in the image recipe (or `isar-image-base.bbappend`) of that layer.

### ROOTFS_DEV and ROOTFS_TYPE no longer needed

These variables can be removed from own machine.conf or multiconfig files.

If you want to enable support for QEMU in your config (start_vm), specify the
`QEMU_ROOTFS_DEV` and `QEMU_DISK_ARGS` instead.

### KERNEL_NAME_PROVIDED replaces KERNEL_FLAVOR in custom kernels

The matching logic for custom kernel recipes to the selected kernel was
reworked and simplified. If your kernel recipe is called `linux-foo_4.18.bb`,
you now have to set `KERNEL_NAME = "foo"` in order to select that kernel.
Alternatively, a recipe with a different naming scheme can set
`KERNEL_NAME_PROVIDED = "foo"` in order to match as well.
