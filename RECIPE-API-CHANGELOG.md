Recipe API Changelog
====================

Baseline: Release v0.5

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

Changes in v0.7
---------------

### dpkg-raw recipes build method changed

These packages are now built using the whole dpkg-buildpackage workflow, and
not just packaged as before.

 - all files will be owned by root:root before it might have been 1000:1000
   use postinst to change that (see example-raw)
 - a lot of debhelpers will help .. or complain
   fix the issues or override the helpers (see example-raw)

### Set LAYERSERIES_COMPAT_*  when an own layer is defined

When defining an own layer LAYERSERIES_COMPAT_mylayer_root_name has to be set,
the possible values are listed in the variable LAYERSERIES_CORENAMES.

If you need to express the fact that your layer requires the
layer version higher than existing release corename, use the value 'next'.

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

### Append kernel name to custom module and u-boot-script packages

These packages depend on a specific kernel. Its identification is now appended
to the binary package names in the form "-${KERNEL_NAME}".

### PRESERVE_PERMS needed with dpkg-raw for implicit file permission setting

In order to use the same file permissions for an input file to a dpkg-raw
package on the build machine as well as on the target, its absolute target path
needs to be listed in the PRESERVE_PERMS variable (space-separated list of
files). Otherwise, default permissions are used.

### Reduce requirements on custom module makefiles

It's now sufficient to provide only kbuild rules. Makefile targets like modules
or modules_install as well as KDIR and DESTDIR evaluation are no longer needed.

### Remove setting of root passwords in custom packages

Custom packages that are not installed via the IMAGE_TRANSIENT_PACKAGES and set
a root password, leak that password via its script in /var/lib/dpkg/info.

Instead set the CFG_ROOT_PW variable to the encrypted password and use the
transient 'isar-cfg-rootpw' package (now installed as transient package per
default).

Changes in v0.8
---------------

### `apt://` SRC_URIs where added and briefly changed their version picking way

Recipes that use SRC_URIs with `apt://` and choose a version with `=` had a
partial matching feature for a short time between 0.7 and 0.8. In 0.8 the
version has to be the exact upsteam match.
It is probably best to not specify a version if you can.

### `isar-image.bbclass` class will be deprecated in future version of isar

The content of `isar-image.bbclass` was moved to the `image.bbclass` file.
Recipes that inherit `isar-image` should be modified to inherit from `image`
instead.

### Transient package support was removed

The `LOCALE_GEN` and `LOCALE_DEFAULT` variables are now handled by the
`image-locales-extension` class within the image recipe.

Setting of the root password can now be done by the `image-account-extension`
class within the image recipe. To set the root password to empty, you can
use this code snippet:

```
USERS += "root"
USER_root[password] = ""
USER_root[flags] = "allow-empty-password"
```

Otherwise set a encrypted root password like this:

```
USERS += "root"
USER_root[password] = "$6$rounds=10000$RXeWrnFmkY$DtuS/OmsAS2cCEDo0BF5qQsizIrq6jPgXnwv3PHqREJeKd1sXdHX/ayQtuQWVDHe0KIO0/sVH8dvQm1KthF0d/"
```

### Use FILESEXTRAPATHS to add custom paths to FILESPATH

Direct modification of FILESPATH variable is discouraged. Use FILESEXTRAPATHS
instead to add a custom search path for files and patches. This makes overriding
files and patches using bbappend a lot easier.

For example:
```
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
```

### multiconfig build targets were renamed

bitbake was upgraded to version 1.44.0 where "multiconfig" build targets were
renamed "mc". As an example, builds for the qemuarm-stretch machine should now
be done as follows:

```
bitbake mc:qemuarm-stretch:isar-image-base
```

The old syntax is no longer supported and will produce an error:

```
bitbake multiconfig:qemuarm-stretch:isar-image-base
```

### Support for kernel config fragments

Kernels built via linux-custom.inc will now get configuration fragments listed
in SRC_URI automatically applied. Config fragment files need to end on .cfg.
If such a file should not by applied, append `;apply=no` to the respective
SRC_URI entry.

### Control over kernel's LOCALVERSION via LINUX_VERSION_EXTENSION

In order to get a LOCALVERSION appendix into both the kernel config and the
version information of the self-built packages, the LINUX_VERSION_EXTENSION is
now available. It remains empty by default unless a recipe sets it. The
appended version usually starts with a "-".

### Image task `cache_base_repo` was removed

That task used to be at the end of a cache-warming build, a follow-up build
with `ISAR_USE_CACHED_BASE_REPO` did use that. Now we cache all downloads
anyway, if `ISAR_USE_CACHED_BASE_REPO` is set a build will use all the
downloads from previous builds for the cache.

### Renamed DTB_FILE to DTB_FILES, adding support for multiple entries

DTB_FILES now allows to specify multiple DTBs that should be deployed for
consumption by imaging classes.

### Add DEBIAN_BUILD_DEPENDS as deb_debianize parameter

Additional build dependencies of auto-debianized packages can now be defined
by setting DEBIAN_BUILD_DEPENDS.

### Add DEBIAN_STANDARDS_VERSION as a deb_debianize parameter

By default, the Standards-Version field in the debian/control file is automatically
set based on the corresponding Debian suite.
If you need to override this default value, you can do so by defining
the DEBIAN_STANDARDS_VERSION variable in your recipe.

E.x: `DEBIAN_STANDARDS_VERSION:<suite-name> = <version>`

### Separation of ${S} and ${D} in dpkg-raw

${S} can now be used for checking out sources without being linked implicitly
with ${D} which needs to be filled explicitly in do_install as before.

### Remove ISARROOT from bitbake environment

ISARROOT variable is now removed from the bitbake environment. It is unset
after the initial setup. It is replaced with dedicated variables like
BITBAKEDIR, SCRIPTSDIR and TESTSUITEDIR.

### Wic adds /boot mountpoint to fstab

In the older version of wic, any mount point named /boot is skipped from adding
into the fstab entry.

With the latest wic, this is not the case. /boot mount point, if any, is added
to /etc/fstab for automount.

Any wks file which assumed that /boot would be skipped from /etc/fstab should
now be corrected. Otherwise, it might conflict with the original /boot contents,
i.e kernel initrd & config files will be unavailable after boot.

Below is an example wks entry that might cause an issue.
The efi partition created using bootimg-efi-isar plugin has only the efi stub in
it. The kernel and initrd are present in the root(/) partition.
Now with the latest wic which adds the /boot mount point to fstab, the /boot
contents of "part /" would be unavailable after boot. This would break the
kernel updates done via apt-get.

```
part /boot --source bootimg-efi-isar --sourceparams "loader=grub-efi" --ondisk sda --label efi --part-type EF00 --align 1024
part / --source rootfs --ondisk sda --fstype ext4 --label platform --align 1024 --use-uuid
```
In this case we can either drop the /boot mountpoint or use some other mountpoint
like /boot/efi to avoid such issues.

### Deprecate BUILD_DEPENDS in u-boot-custom.inc

Use DEBIAN_BUILD_DEPENDS instead, to align with deb_debianize.

### Default to PATCHTOOL ?= "git" for dpkg-gbp

Migrate your patches so they can be applied with "git am", or
"unset PATCHTOOL" to get old behaviour.

### Change kernel image name for arm64

Kernel image name for arm64 platforms is vmlinux now. Image format was
not changed (uncompressed executable) but now it is named correctly.

### wic plugins for efi and pcbios use seperate /boot partition

It used to depend on the bootloader whether stuff was in in the root partition or in the boot partition, now it will always be in the boot partition.

Kernel update with "apt-get" will not work since bootloader configuration will
not be updated. It used to "kind of work" for grub and efi, that hack is gone.

When using the plugins it is advised to name the partition "/boot" and to exclude boot from the follwing rootfs to not waste space.

### Rename IMAGE_TYPE to IMAGE_FSTYPES

The variable is renamed to get closer to OE/Poky variables naming. The old naming
will still also work, but with deprecation warning shown.

### Change default "NAME:TAG" when building container images

The "NAME" used to be rather static and the TAG was always "latest", now the values are derived from recipe variables PN, PV, PR.

### Renamed variable CONTAINER_FORMATS to CONTAINER_IMAGE_FORMATS

The meaning remains the same, just the name changed.

### Changed location of deployed *.dpkg_status and *.manifest files

Now, parallel multiconfigs for different machines with same architectures don't
share the same location for image *.manifest and *.dpkg_status files, so they
are not owerwritten by last build ones anymore.

Output file names now include distro name and architecture/machine name parts.

### Using custom package name for linux kernel and headers

Isar assumes that linux kernel is provided by linux-image-${KERNEL_NAME}
package, while headers are provided by linux-headers-${KERNEL_NAME} package.
This naming may be different in other distributions like Raspberry Pi OS.

KERNEL_IMAGE_PKG and KERNEL_HEADERS_PKG variables allow to use custom package
names for kernel/headers.

Changes in v0.9
---------------

### Introduce debian build profiles

All recipes that inherit from dpkg and dpkg-base can utilize the variables `DEB_BUILD_PROFILES` and `DEB_BUILD_OPTIONS`.
The bitbake variable defines the respective environment variable which is available in `do_install_builddeps` and `do_dpkg_build`.
When cross compiling, `cross` is added to the `DEB_BUILD_PROFILES` environment variable.
Please note, that manually exported versions of the variables are overwritten.

For a list of well-known Debian build profiles and common practices, we refer to Debian's BuildProfileSpec.

### `rpi-sdimg.bbclass` class is now deprecated and will be removed soon

It was replaced by WIC and no more needed.
Machines that use `rpi-sdimg` image type should be modified to use `wic` type
with `rpi-sdimg` wks file instead.

### Changes to image types

The way different image types are handled has changed to be closer to the
implementation in OE.

Changes when using the built-in types:
  * Image recipes no longer inherit their image type class.
  * Names of image types, as defined using IMAGE_FSTYPES, no longer have the
    suffix `-img`, i.e., `wic-img` becomes `wic`, `ext4-img` becomes `ext4`,
    and so on.
  * Image types defined in IMAGE_FSTYPES can be suffixed with conversions.
    To get a compressed image, set IMAGE_FSTYPES to `wic.xz`, `ext4.gz`, etc.
    That also means that the type of the previous `targz-img` is now `tar.gz`.
  * Container types (previously CONTAINER_IMAGE_FORMATS) are now
    first class image types (oci, oci-archive, docker-archive,
    docker-daemon, containers-storage)
  * The VM image now has type `ova` (instead of `vm-img`)

Changes when defining custom image classes:
  * Custom image classes that only add a compression step should be removed
    and replaced by an image conversion (see below).
  * Instead of providing a do_image_mytype task, custom image classes should
    now provide IMAGE_CMD_mytype
  * Imager dependencies are set as IMAGER_INSTALL_mytype
  * Required arguments (variables that must be set) are modelled by
    IMAGE_CMD_REQUIRED_ARGS_mytype = "A B C"
  * When extending an existing image type, instead of inheriting the base
    image class, IMAGE_TYPEDEP_mytype can be set to define dependencies
    between image types.
  * In the IMAGE_CMD_mytype function:
    - image_do_mounts is inserted automatically
    - a final chown is inserted automatically
    - variables IMAGE_FILE_HOST and IMAGE_FILE_CHROOT are
      set to reference the image
    - variable SUDO_CHROOT contains the chroot command needed to run in the
      build changeroot
  * Custom image classes need to be added to IMAGE_CLASSES (e.g., in local.conf
    or machine config) so Isar will include them.

New conversions can be added by defining CONVERSION_CMD_type.
  * Dependencies that need to be installed are given as CONVERSION_DEP_type.
  * New conversions must be added to CONVERSION_TYPES before they can be used.
  * In conversion commands
    - the input file is named ${IMAGE_FULLNAME}.${type}
    - the conversions appends its own type, e.g. the output file of a conversion `xz`
      would be ${IMAGE_FULLNAME}.${type}.xz
    - a final chown is appended automatically

### Handling of variables USERS and GROUPS is moved to image post processing

The user and groups defined by the variables `USERS` and `GROUPS`
was moved from image configuration to image post processing. The users and
groups are now created after all packages are installed.

Changes in v0.10
----------------

### Buildchroot no longer used for package building

Packages are now built with sbuild which takes care of dependency
installation.
The task do_install_builddeps has been removed.

The migration to sbuild also means that all changes in the rootfs made during
package building will not be shared between the build sessions of different
packages and will be lost after a given build session finishes.

Any package build requirements for the rootfs should be satisfied in the
Debian way via package dependencies.

### Individual WIC partitions are no longer automatically deployed

We used to copy all temporary WIC files, like the partitions, into the deploy directory.
That was intended actually only for compressed wic images where wic itself would do the compression.
It was never intended to also deploy those partitions, so that will also not be done (automatically) anymore.
To explicitly deploy the individual partition files (e.g. for swupdate), set `WIC_DEPLOY_PARTITIONS = "1"`.

For compressed wic images `IMAGE_FSTYPES` should simply be extended with a compressed wic format, like "wic.xz".

### Introduce mechanism to forward bitbake variables into sbuild environment

All recipes that inherit from dpkg can use the bitbake variable `SBUILD_PASSTHROUGH_ADDITIONS` to forward
specific bitbake variables as environment variables into the sbuild environment.
The motivation behind it is to allow the use of external mirrors for programming languages with builtin
package managers (like rust and go). By that, the variables are also excluded from the bitbake signatures.
This helps in areas where default mirrors can either not be reached or provide only little throughput.
Please note, the forwarded variables do not have to exist. While they are not forwarded in case they do not
exist, empty variables are forwarded.

**Note about reproducibility**: the forwarded variables must not have any influence on the generated package.
This mechanism must also not be used to inject build configurations. For these cases, templates should be used.

### Override syntax changes

Using `_` in override syntax was changed to `:`.
All the recipes should be changed manually or with helper script:

```
$ python3 scripts/contrib/convert-overrides.py <layer_path>
```

The script should be adopted to the downstream layer by adding all new
overrides like machine names or custom distro names.

### SRC_URI should always have some branch specified

All the recipes with git fetcher now should have branch name in SRC_URI because
"master" is no longer the default.

### SRCREV must always be a hash

Tag/branch names, including the pattern `SRCREV = "v${PV}"`, are no longer
allowed.

### Network usage tasks should be marked

With the new bitbake version all the tasks need network access should be marked
with the flag [network] = '1'.

### Sstate artifacts are now packed with ZStandard

Share State cache compression was moved from Gzip to ZStandard (zstd) in
Bitbake 2.0 for better performance. It also requires isar-sstate script to be
migrated to zstd.
Mixing old Gzip-based and new ZStandatd-based sstate cache is not recommended
and should be avoid for correct compatibility.

### Working with a custom initramfs

The existing `INITRD_IMAGE` variable is defaulted to the empty string and used to
control if a custom initrd is requrested. Only if this variable is empty, the
default one is deployed. By that, the variable cannot be used to get the name of
the images initramfs. Instead, the variable `INITRD_DEPLOY_FILE` is provided which
always povides the name of the initrd file (also when the default one is used).

### The `compat-arch` override was removed

Recipes inheriting dpkg-base now automatically have a bitbake target
`<foo>-compat`, if `ISAR_ENABLE_COMPAT_ARCH == "1"`, and if a compat architecture
exists for the current `DISTRO_ARCH`.
In that case the compat package can be built by adding `<foo>-compat`
to `DEPENDS` or `IMAGE_INSTALL`.

### Introduce meta-test layer

Some CI-related recipes and images moves to meta-test from meta-isar, so if
a downstream used them, they should update their layers.conf accordingly.

### Cleanup machine configs and multiconfigs from irrelevant packages

Machine configs and multiconfigs should not include any IMAGE_INSTALL and
IMAGE_PREINSTALL entries that doesn't refers to machine configuration, such as
`expand-on-first-boot` or `sshd-regen-keys`.
The configs are cleaned up now and this fact may force downstreams to modify
their configuration if they relied on these packages.

### Imager is now executed inside schroot

Buildchroot is completely removed and can't be used any more.
To execute imager code new `imager_run` API was created.

So older style call:
```
sudo chroot --userspec=$( id -u ):$( id -g ) ${BUILDCHROOT_DIR} cmd_to_execute
```
Can now be performed by:
```
imager_run -p -d ${PP_WORK} cmd_to_execute
```
If privileged execution is required `-u root` option can be added.

`image_do_mounts` is removed, additional mountpoints can be added like:
```
SCHROOT_MOUNTS += "${OUT_PATH1}:${IN_PATH1} ${OUT_PATH2}"
```

### Building source package tasks were separated

Two new tasks are introduced: do_dpkg_source and do_deploy_source. The first
one builds source package, second one adds this package to isar_apt.
They are placed between do_prepare_build and do_dpkg_build.
Now all source modifications should be done inside do_prepare_build task, in
some cases dpkg_runbuild:prepend should be replaced by do_dpkg_source:prepend.

### Local copy of isar-apt creation task was separated

We need local copy of isar-apt to have build dependencies reachable. Now is
prepared in separate task: do_local_isarapt.
This task depends of do_deploy_deb of all build dependency recipes.

### Skipping source package cleanup

By default Isar filter out control files and directories of the most common
revision control systems, backup and swap files and Libtool build output
directories from the source package.
Now this can be overriden by setting DPKG_SOURCE_EXTRA_ARGS value in recipe.

Default value is '-I' which sets filter to:

*.a -I*.la -I*.o -I*.so -I.*.sw? -I*/*~ -I,,* -I.[#~]* -I.arch-ids
-I.arch-inventory -I.be -I.bzr -I.bzr.backup -I.bzr.tags -I.bzrignore
-I.cvsignore -I.deps -I.git -I.gitattributes -I.gitignore -I.gitmodules
-I.gitreview -I.hg -I.hgignore -I.hgsigs -I.hgtags -I.mailmap -I.mtn-ignore
-I.shelf -I.svn -ICVS -IDEADJOE -IRCS -I_MTN -I_darcs -I{arch}

### WIC_IMAGER_INSTALL is deprecated

Use `IMAGER_INSTALL:wic` instead of `WIC_IMAGER_INSTALL`. The latter is still
supported, but a warning is issued when it is used. Future versions will drop
`WIC_IMAGER_INSTALL` completely.

### Add MODULE_DIR to decouple sources dir from modules dir in custom-module

When building a custom kernel module, the `KBuild` file might be located in
a subdirectory. To support this use-case, set `MODULE_DIR=$(PWD)/subdir` in
the module build recipe.

### Function debianize:deb_compat is removed

Remove all uses of the function deb_compat. The functionality was replaced with
a dependency to the package debhelper-compat.

Changes in v0.11
---------------

### Change OPTEE_BINARIES default ###0

Since OP-TEE 3.21, tee-raw.bin is produced for all platforms and is considered
the better default option. `OPTEE_BINARIES` now uses this as default as well.

### Automatically disable cross for kmod builds against distro kernels

Cross compiling kernel modules for distro kernels is not supported in debian.
To simplify downstream kernel module builds, we automatically turn of cross
compilation for a user-provided module when building it for a distro kernel.


### Build against debian snapshot mirror

To build against a distributions snapshot mirror, set `ISAR_USE_APT_SNAPSHOT="1"`.
The mirror to use is specified in `DISTRO_APT_SNAPSHOT_PREMIRROR` and usually
pre-defined in the distro config.

### Use OE interface to set timestamp for reproducible builds

The `SOURCE_DATE_EPOCH` (SDE) should not be set globally, but on a per-recipe basis
and to meaningful values. As a global fallback, set the `SOURCE_DATE_EPOCH_FALLBACK`
bitbake variable to the desired unix timestamp.

### Split up binaries from kernel headers to kbuild package for linux-custom

Swap out the binaries from the kernel headers
into kernel kbuild package.

  * Split up binaries from kernel headers to kbuild package:
    Introduce specific kernel kbuild packages that
    ship the "scripts" and "tools" binaries.
    The kernel headers fulfill this using symlinks to point
    to the "scripts" and "tools" of the kernel kbuild package.

  * Provide target and host specific kernel kbuild packages:
    Introduce target and host specific kernel kbuild packages that
    ship the "scripts" and "tools" binaries.

    The "-kbuildtarget" and "-native" multiarch bitbake targets are useable to
    run additional target or host specific builds for kbuild scripts and tools.

    Using the "-kbuildtarget" bitbake target enables the build of
    a target specific kbuild package at cross builds.
    So using "linux-kbuild" provides the package for the target platform.

    Using the "-native" bitbake target enables the build of
    a host specific kbuild package at cross builds.
    When cross building using "linux-kbuild-native"
    provides the package for the host platform.

    Only the "host" specific package is built automatically at cross builds.

  * Support emulated module build with cross-compiled kernel for linux-module

### Rate-Limit apt fetching

When downloading from debian snapshot mirrors, rate limits might apply.
To limit the amount of parallel fetching to n kB / s, you can set `ISAR_APT_DL_LIMIT="<n>`.

### Custom directories in vendor kernels

Some vendor kernels come with additional directories to be included in the
linux-headers package in order to support building of their out-of-tree
drivers. `HEADERS_INSTALL_EXTRA` may be set to a list of directories relative
to ${S} in any kernel recipes that includes `linux-custom.inc`. A l4t kernel
recipe would use the following setting:

```
HEADERS_INSTALL_EXTRA += "nvidia"
```

### Architecture for dpkg-raw packages

The primary use-case of the dpkg-raw class is to easily package configuration
and data files into a Debian package: the target architecture will now default
to "all". It may also be used to package binaries that were built outside of
Isar: such recipes may still override `DPKG_ARCH` to `"any"` or a specific
architecture matching binaries to be included in the payload of the package.

This change fixes an issue where a `dpkg` package is built for `-compat` or
`-native` and `DEPENDS` on a `dpkg-raw` package with `DPKG_ARCH` set to `"all"`.
Some issues remain with `dpkg-raw` packages targetting a specific architecture:
Isar will advertise -native and -compat variants even though such recipes can
only produce packages for that architecture and not what could possibly expect
for -native or -compat. If we consider a dpkg-raw recipe generating an `arm64`
package on an `amd64` host: you would expect the -native variant to produce
an `amd64` package and -compat an 'armhf` package: it will however remain
`arm64` and build of dependent recipes (image or dpkg) may fail because of
the architecture mismatch.

### Changes in cleanup handler

Bitbake BuildCompleted event handler is now executed only once per build and
always outputs a warning if mounts are left behind after the build.

Bitbake exit status depends on ISAR_FAIL_ON_CLEANUP bitbake variable:
 - 0 or unset: Output a warning, unmount, build succeeds (default).
 - 1: Output a warning, keep mounts left behind, build fails.

### Stricter rootfs mounts management

rootfs_do_umounts is not called from do_rootfs_finalize anymore.

Every individual task that does mounting must also do the umounting at its end.

### Default boostrap recipe changed to mmdebstrap

New virtual packages bootstrap-host and bootstrap-target are introduced.
There are two providers of bootstrap-host/-target currently:
  * isar-mmdebstrap: deafult one using mmdebstrap to prepare rootfs
  * isar-bootstrap: previous bootstrap implementation left for compatibility

So default bootstrap procedure is now performing with mmdebstrap.
Previous implementation still can be selected by setting in local.conf:

PREFERRED_PROVIDER_bootstrap-host ?= "isar-bootstrap-host"
PREFERRED_PROVIDER_bootstrap-target ?= "isar-bootstrap-target"

### Cross-compilation is enabled by default

Default ISAR_CROSS_COMPILE value was changed to "1".
There is no more need to set global ISAR_CROSS_COMPILE = "1" in local.conf to
enable cross-compilation. Otherwize ISAR_CROSS_COMPILE = "0" now should be set
in local.conf to disable cross-compilation for all the recipes.
Sample local.conf from meta-isar used by isar-init-build-env is also changed
to enable cross-compilation by default.

### Enable linux-libc-dev package with KERNEL_NAME

By default linux-libc-dev and linux-libc-dev-${DISTRO_ARCH}-cross package
was generated for architecture it builds for.

This change helps to generate the `linux-libc-dev-${KERNEL_NAME}` and
`linux-libc-dev-${DISTRO_ARCH}-cross-${KERNEL_NAME}`.
For example, If `KERNEL_NAME` is configured as `foo` for arm64, now
`linux-libc-dev-foo` and `linux-libc-dev-arm64-cross-foo` package will be
generated. This will help to have multiple versions of linux-libc-dev packages
available for respective bsps in apt feeds.

### ISAR APT Repository

Optional fields of the isar-apt repo can be controlled by adding to the
`ISAR_APT_OPT_FIELD` map. Example: `ISAR_APT_OPT_FIELD[Origin]="isar"`.

Changes in next
---------------

### Drop unused container image format `oci`

This was never documented and never had practical relevance. `oci-archive` is
the useful OCI image format that can be imported, e.g., by podman.

### Control tee-supplicant userspace service usage

Set `TEE_SUPPLICANT_IN_USERLAND` to 0 if you are using a kernel that supports
`CONFIG_RPMB` and you only need the daemon for RPMB access. Default is 1, but
this will eventually be changed to 0. Therefore, explicitly set the variable
to 1 to stay compatible.

### Support for new optee_ftpm

By setting `MS_TPM_20_REF_DIR` in an optee-ftpm recipe, it is now possible to
use the new optee_ftpm code base from the OP-TEE project. That variable has to
point to a subdir in `WORKDIR` which contains the unpacked ms-tpm-20-ref source
code.

### Configure Locale Exports Using LOCALE_DEFAULT

The LOCALE_DEFAULT variable is now used to export LANG, LANGUAGE, and LC_ALL
in the rootfs.bbclass, replacing the previous hardcoded "C" values. It is
weakly assigned a default value of "C". This value can be overridden by image
recipes via the image-locales-extension class (inherited by the image class),
for example, to set it to "en_US.UTF-8".

This enables configuring the default locale and keyboard layout at build time.
Additionally, if console-setup is installed in the rootfs during the build, it
will be configured based on the locale exports.

To set a locale other than "C" or "en_US.UTF-8" (generated by default), define
the following variables in your image recipe. For example, to use German, add:

```
LOCALE_GEN = "de_DE.UTF-8 UTF-8\n"
LOCALE_DEFAULT = "de_DE.UTF-8"
```

### Require bubblewrap to run non-privileged commands with bind-mounts

Isar occasionally needs to run commands within root file-systems that it
builds and with several bind-mounts (e.g. /isar-apt). bubblewrap may be
used in Isar classes instead of `sudo chroot` to avoid unecessary privilege
elevations (when we "just" need to chroot but do not require root). It is
pre-installed in kas-container version 4.8 (or later).

### Revert enabling of linux-libc-dev package with KERNEL_NAME

The change "Enable linux-libc-dev package with KERNEL_NAME" turned out to be
incompatible with how Debian selects dependencies. It is therefore necessary
to only enable `KERNEL_LIBC_DEV_DEPLOY` for a single kernel in case multiples
are configured via `KERNEL_NAMES`.

### Allow setting Rules-Requires-Root

Recipes based on the `debianize` class can now set the
`DEBIAN_RULES_REQUIRES_ROOT` variable to control the value of the
`Rules-Requires-Root` setting in the `debian/control` file. If this variable is
unset (the default), `Rules-Requires-Root` will not be added. Otherwise,
`Rules-Requires-Root` will be added and set to the value of the variable.

### Avoid unnecessary use of fakeroot

Set `Rules-Requires-Root: no` in `debian/control` files to prevent unnecessary
invocation of fakeroot during package builds. This follows Debian guidelines
recommending not to use fakeroot when no privileged operations (e.g., `chown`,
root file modifications) are required. 

### Add opensbi class to simplify custom OpenSBI builds

A new class called `opensbi` has been introduced that shall help writing
shorter recipes for custom OpenSBI builds. Usage examples can be found in
`meta-isar/recipes/bsp/opensbi`.
root file modifications) are required.

### Populate systemd units based on presets during image postprocessing

By default population of the presets is automatically done by systemd
on first-boot.

There were several issues with that:

1. The rootfs we get as a build artifact does not reflect the actual
system running in the field.

2. For setups without writeable /etc this fails. With that addition
it happens already at build time.

**Note**: Additional services are enabled only. Services already enabled
during the package installation won't be changed.

Opt-out: `ROOTFS_FEATURES:remove = "populate-systemd-preset"`

### Rework `no-generate-initrd` rootfs feature

This negative feature is being replaced with a positive one:
`generate-initrd`. The default behavior remains unchanged, as `generate-initrd`
is now a default rootfs feature. Disabling initrd creation can be done in the
following way:
```
ROOTFS_FEATURE:remove = "generate-initrd"
```
instead of
```
ROOTFS_FEATURE += "no-generate-initrd"
```
