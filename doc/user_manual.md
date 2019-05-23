# ISAR User Manual

Copyright (C) 2016-2019, ilbers GmbH

## Contents

 - [Introduction](#introduction)
 - [Getting Started](#getting-started)
 - [Terms and Definitions](#terms-and-definitions)
 - [How Isar Works](#how-isar-works)
 - [General Isar Configuration](#general-isar-configuration)
 - [Isar Distro Configuration](#isar-distro-configuration)
 - [Custom Package Compilation](#custom-package-compilation-1)
 - [Image Type Selection](#image-type-selection)
 - [Add a New Distro](#add-a-new-distro)
 - [Add a New Machine](#add-a-new-machine)
 - [Add a New Image](#add-a-new-image)
 - [Add a New Image Type](#add-a-new-image-type)
 - [Add a Custom Application](#add-a-custom-application)
 - [Enabling Cross-compilation](#isar-cross-compilation)
 - [Create an ISAR SDK root filesystem](#create-an-isar-sdk-root-filesystem)
 - [Creation of local apt repo caching upstream Debian packages](#creation-of-local-apt-repo-caching-upstream-debian-packages)


## Introduction

Isar is a set of scripts for building software packages and repeatable generation of Debian-based root filesystems with customizations.

Isar provides:

 - Fast target image generation: About 10 minutes to get base system image for one machine.
 - Use any apt package provider, including open-source communities like `Debian`, `Raspbian`, etc. and proprietary ones created manually.
 - Native compilation: Packages are compiled in a `chroot` environment using the same toolchain and libraries that will be installed to the target filesystem.
 - Cross compilation: Could be enabled, when native compilation from the sources takes a lot of time f.e. for Linux kernel.
 - Product templates that can be quickly re-used for real projects.

---

## Getting Started

For demonstration purposes, Isar provides support for the following
configurations:

 - QEMU ARM with Debian Stretch
 - QEMU ARM with Debian Buster
 - QEMU ARM64 with Debian Stretch
 - QEMU ARM64 with Debian Buster (for host >= buster)
 - QEMU i386 with Debian Stretch
 - QEMU i386 with Debian Buster
 - QEMU amd64 with Debian Stretch
 - QEMU amd64 with Debian Buster
 - Raspberry Pi 1 Model B with Raspbian Stretch
 - Banana Pi BPI-M1
 - LeMaker HiKey
 - Terasic DE0-Nano-SoC

The steps below describe how to build the images provided by default.

### Install Host Tools

The supported host system is >= stretch.

Install the following packages:
```
binfmt-support
debootstrap
dosfstools
dpkg-dev
gettext-base
git
mtools
parted
python3
python3-distutils             # host >= buster
qemu                          # start_vm
qemu-user-static
reprepro
sudo
```

Notes:

* BitBake requires Python 3.4+.
* The python3 package is required for the correct `alternatives` setting.
* If you'd like to run bitbake in a container (chroot, docker, etc.), install
  the above in the container, and also perform `sudo apt-get install
  binfmt-support qemu-user-static` on the host that should run the container.
* If you install `binfmt-support` after `qemu-user-static`, perform `sudo
  apt-get install --reinstall qemu-user-static` to register binary formats
  handled by QEMU (check e.g. `qemu-arm` in `/usr/sbin/update-binfmts
  --display`).

### Setup Sudo

Isar requires `sudo` rights without password to work with `chroot` and `debootstrap`. To add them, use the following steps:
```
 # visudo
```
In the editor, allow the current user to run sudo without a password, e.g.:
```
 <user>  ALL=(ALL:ALL) NOPASSWD:ALL
 Defaults env_keep += "ftp_proxy http_proxy https_proxy no_proxy"
```
Replace `<user>` with your user name. Use the tab character between the user name and parameters.
The second line will make sure your proxy settings will not get lost when using `sudo`. Include it if you are in the unfortunate possition to having to deal with that.

### Check out Isar

Clone the isar repository:
```
$ git clone http://github.com/ilbers/isar.git
```

### Initialize the Build Directory

To initialize the `isar` build directory run the following commands:
```
 $ cd isar
 $ . isar-init-build-env ../build
```
`../build` is the build directory. You may use a different name here.

### Building Target Images for One Configuration

To build target images ("targets" in BitBake terms) for one configuration,
define the default configuration in `conf/local.conf` in the build directory,
e.g.:

```
MACHINE ??= "qemuarm"
DISTRO ??= "debian-stretch"
DISTRO_ARCH ??= "armhf"
```

Then, call `bitbake` with image names, e.g.:

```
bitbake multiconfig:qemuarm-stretch:isar-image-base \
        multiconfig:qemuarm-stretch:isar-image-debug
```

The following images are created:

```
tmp/deploy/images/qemuarm/isar-image-base-qemuarm-debian-stretch.ext4.img
tmp/deploy/images/qemuarm/isar-image-debug-qemuarm-debian-stretch.ext4.img
```

### Building Target Images for Multiple Configurations

Alternatively, BitBake supports building images for multiple configurations in
a single call. List all configurations in `conf/local.conf`:

```
BBMULTICONFIG = " \
    qemuarm-stretch \
    qemuarm-buster \
    qemuarm64-stretch \
    qemuarm64-buster \
    qemui386-stretch \
    qemui386-buster \
    qemuamd64-stretch \
    qemuamd64-buster \
    rpi-stretch \
"
```

The following command will produce `isar-image-base` images for all targets:

```
$ bitbake \
    multiconfig:qemuarm-stretch:isar-image-base \
    multiconfig:qemuarm-buster:isar-image-base \
    multiconfig:qemuarm64-stretch:isar-image-base \
    multiconfig:qemui386-stretch:isar-image-base \
    multiconfig:qemui386-buster:isar-image-base \
    multiconfig:qemuamd64-stretch:isar-image-base \
    multiconfig:qemuamd64-buster:isar-image-base \
    multiconfig:rpi-stretch:isar-image-base
```

Created images are:

```
tmp/deploy/images/qemuarm/isar-image-base-debian-stretch-qemuarm.ext4.img
tmp/deploy/images/qemuarm/isar-image-base-debian-buster-qemuarm.ext4.img
tmp/deploy/images/qemuarm64/isar-image-base-debian-stretch-qemuarm64.ext4.img
tmp/deploy/images/qemui386/isar-image-base-debian-stretch-qemui386.wic.img
tmp/deploy/images/qemui386/isar-image-base-debian-buster-qemui386.wic.img
tmp/deploy/images/qemuamd64/isar-image-base-debian-stretch-qemuamd64.wic.img
tmp/deploy/images/qemuamd64/isar-image-base-debian-buster-qemuamd64.wic.img
tmp/deploy/images/rpi/isar-image-base.rpi-sdimg
```

### Generate full disk image

A bootable disk image is generated if you set IMAGE_TYPE to 'wic-img'. Behind the scenes a tool called `wic` is used to assemble the images. It is controlled by a `.wks` file which you can choose with changing WKS_FILE. Some examples in the tree use that feature already.
```
 # Generate an image for the `i386` target architecture
 $ bitbake multiconfig:qemui386-stretch:isar-image-base
 # Similarly, for the `amd64` target architecture, in this case EFI
 $ bitbake multiconfig:qemuamd64-stretch:isar-image-base
```

Variables may be used in `.wks.in` files; Isar will expand them and generate a regular `.wks` file before generating the disk image using `wic`.

In order to run the EFI images with `qemu`, an EFI firmware is required and available at the following address:
https://github.com/tianocore/edk2/tree/3858b4a1ff09d3243fea8d07bd135478237cb8f7

Note that the `ovmf` package in Debian stretch/buster contains a pre-compiled firmware, but doesn't seem to be recent
enough to allow images to be testable under `qemu`.

```
# AMD64 image, EFI
qemu-system-x86_64 -m 256M -nographic -bios edk2/Build/OvmfX64/RELEASE_*/FV/OVMF.fd -hda tmp/deploy/images/qemuamd64/isar-image-base-debian-stretch-qemuamd64.wic.img
# i386 image
qemu-system-i386 -m 256M -nographic -hda tmp/deploy/images/qemui386/isar-image-base-debian-stretch-qemui386.wic.img
```

---

## Terms and Definitions

### Chroot

`chroot`(8) runs a command within a specified root directory. Please refer to GNU coreutils online help: <http://www.gnu.org/software/coreutils/> for more information.

### QEMU

QEMU is a generic and open source machine emulator and virtualizer. Please refer to <http://wiki.qemu.org/Main_Page> for more information.

### Debian

Debian is a free operating system for your machine. Please refer to <https://www.debian.org/index.en.html> for more information.

### Apt

`Apt` (for Advanced Package Tool) is a set of tools for managing Debian package repositories and applications installed on your Debian system. Please refer to <https://wiki.debian.org/Apt> for more information.

### BitBake

BitBake is a generic task execution engine for efficient execution of shell and Python tasks according to their dependencies. Please refer to <https://www.yoctoproject.org/docs/1.6/bitbake-user-manual/bitbake-user-manual.html> for more information.

---

## How Isar Works

Isar workflow consists of stages described below.
 
### Generation of  Buildchroot Filesystem

This filesystem is used as a build environment to compile custom packages. It is generated using `apt` binaries repository, selected by the user in configuration file. Please refer to distro configuration chapter for more information.

### Custom Package Generation

During this stage Isar processes custom packages selected by the user and generates binary `*.deb` packages for the target. Please refer to custom packages generation section for more information.

### Generation of Basic Target Filesystem

This filesystem is generated similarly to the `buildchroot` one using the `apt` binaries repository. Please refer to distro configuration chapter for more information.

### Install Custom Packages

At this stage, Isar populates target filesystem by custom packages that were built in previous stages.

### Target Image Packaging

Isar can generate various image types, e.g. an ext4 filesystem or a complete SD card image. The list of images to produce is set in configuration file, please refer to image type selection section.

---

## General Isar Configuration

Isar uses the following configuration files:

 - `conf/bblayers.conf`
 - `conf/local.conf`

### bblayers.conf

This file contains the list of meta layers, where `bitbake` will search for recipes, classes and configuration files. By default, Isar includes the following layers:

 - `meta` - Core Isar layer which contains basic functionality.
 - `meta-isar` - Product template layer. It demonstrates Isar's features. Also this layer can be used to create your projects.

### `local.conf`

This file contains variables that will be exported to the BitBake environment
and may be referenced in recipes.

Among other things, `local.conf` defines the configurations to generate the
images for.

If BitBake is called with image targets (e.g., `isar-image-base`), the
following variables define the default configuration to build for:

 - `MACHINE` - The board to build for (e.g., `qemuarm`, `rpi`). BitBake looks
   for conf/multiconfig/${MACHINE}.conf in every layer.

 - `DISTRO` - The distro to use (e.g. `raspbian-stretch`, `debian-stretch`).
   BitBake looks for conf/distro/${DISTRO}.conf in every layer.

 - `DISTRO_ARCH` - The Debian architecture to build for (e.g., `armhf`).

If BitBake is called with multiconfig targets (e.g.,
`multiconfig:qemuarm-stretch:isar-image-base`), the following variable defines
all supported configurations:

 - `BBMULTICONFIG` - The list of the complete configuration definition files.
   BitBake looks for conf/multiconfig/<CONFIG>.conf in every layer. Every
   configuration must define `MACHINE`, `DISTRO` and `DISTRO_ARCH`.

Some other variables include:

 - `IMAGE_INSTALL` - The list of custom packages to build and install to target image, please refer to relative chapter for more information.
 - `BB_NUMBER_THREADS` - The number of `bitbake` jobs that can be run in parallel. Please set this option according your host CPU cores number.
 - `HOST_DISTRO` - The distro to use for SDK root filesystem. This variable is optional.
 - `HOST_ARCH` - The Debian architecture of SDK root filesystem (e.g., `amd64`). By default set to current Debian host architecture. This variable is optional.
 - `HOST_DISTRO_APT_SOURCES` - List of apt source files for SDK root filesystem. This variable is optional.
 - `HOST_DISTRO_APT_PREFERENCES` - List of apt preference files for SDK root filesystem. This variable is optional.
 - `DISTRO_APT_PREMIRRORS` - The preferred mirror (append it to the default URI in the format `ftp.debian.org my.preferred.mirror`. This variable is optional.
 - `THIRD_PARTY_APT_KEYS` - List of gpg key URIs used to verify apt repos for apt installation after bootstrapping

---

## Isar Distro Configuration

In Isar, each machine can use its specific Linux distro to generate `buildchroot` and target filesystem. By default, Isar provides configuration files for the following distros:

 - debian-stretch
 - debian-buster
 - raspbian-stretch

User can select appropriate distro for specific machine by setting the following variable in machine configuration file:
```
DISTRO = "distro-name"
```

---

## Custom Package Generation

To add new package to an image, do the following:

 - Create a package recipe and put it in your `isar` layer.
 - Append `IMAGE_INSTALL` variable by this recipe name. If this package should be included for all the machines, put `IMAGE_INSTALL` to `local.conf` file. If you want to include this package for specific machine, put it to your machine configuration file.

Please refer to `Add a Custom Application` section for more information about writing recipes.

---

## Image Type Selection

Isar can generate various images types for specific machine. The type of the image to be generated may be specified through the `IMAGE_TYPE` variable. Currently, the following image types are provided:

 - `ext4` - Raw ext4 filesystem image (default option for `qemuarm` machine).
 - `rpi-sdimg` - A complete, partitioned Raspberry Pi SD card image (default option for the `rpi` machine).
 - `wic-img` - A full disk image with user-specified partitions created and populated using the wic tool.
 - `ubi-img` - A image for use on mtd nand partitions employing UBI

---

## Add a New Distro

The distro is defined by the set of the following variables:

 - `DISTRO_APT_SOURCES` - List of apt source files
 - `DISTRO_BOOTSTRAP_KEYS` - List of gpg key URIs used to verify apt bootstrap repo
 - `DISTRO_APT_PREFERENCES` - List of apt preference files
 - `DISTRO_KERNELS` - List of supported kernel suffixes

The first entry of DISTRO_APT_SOURCES is used for bootstrapping.

Below is an example for Raspbian Stretch:
```
DISTRO_APT_SOURCES += "conf/distro/raspbian-stretch.list"
DISTRO_BOOTSTRAP_KEYS += "https://archive.raspbian.org/raspbian.public.key;sha256sum=ca59cd4f2bcbc3a1d41ba6815a02a8dc5c175467a59bd87edeac458f4a5345de"
DISTRO_CONFIG_SCRIPT?= "raspbian-configscript.sh"
DISTRO_KERNELS ?= "rpi rpi2 rpi-rpfv rpi2-rpfv"
```

To add new distro, user should perform the following steps:

 - Create `distro` folder in your layer:

    ```
    $ mkdir meta-user/conf/distro
    ```

 - Create the `.conf` file in distro folder with the name of your distribution. We recommend to name distribution in the following format: `name`-`suite`, for example:

    ```
    debian-stretch
    debian-buster
    ```

 - In this file, define the variables described above.

---

## Add a New Machine

Every machine is described in its configuration file. The file defines the following variables:

 - `IMAGE_PREINSTALL` - The list of machine-specific packages, that has to be included to image. This variable must include the name of the following packages (if applicable):
   - Linux kernel.
   - U-Boot or other boot loader.
   - Machine-specific firmware.
 - `KERNEL_IMAGE` - The name of kernel binary that it installed to `/boot` folder in target filesystem. This variable is used by Isar to extract the kernel binary and put it into the deploy folder. This makes sense for embedded devices, where kernel and root filesystem are written to different flash partitions. This variable is optional.
 - `INITRD_IMAGE` - The name of `ramdisk` binary. The meaning of this variable is similar to `KERNEL_IMAGE`. This variable is optional.
 - `MACHINE_SERIAL` - The name of serial device that will be used for console output.
 - `IMAGE_TYPE` - The type of images to be generated for this machine.

Below is an example of machine configuration file for `Raspberry Pi` board:
```
IMAGE_PREINSTALL = "linux-image-rpi-rpfv \
                    raspberrypi-bootloader-nokernel"
KERNEL_IMAGE = "vmlinuz-4.4.0-1-rpi"
INITRD_IMAGE = "initrd.img-4.4.0-1-rpi"
MACHINE_SERIAL = "ttyAMA0"
IMAGE_TYPE = "rpi-sdimg"
```

To add new machine user should perform the following steps:

 - Create the `machine` directory in your layer:

    ```
    $ mkdir meta-user/conf/machine
    ```

 - Create `.conf` file in machine folder with the name of your machine.
 - Define in this file variables, that described above in this chapter.

---

## Add a New Image

Image in Isar contains the following artifacts:

 - Image recipe - Describes set of rules how to generate target image.
 - Config script - Performs some general base system configuration after all packages were installed. (locale, fstab, cleanup, etc.)

In image recipe, the following variable defines the list of packages that will be included to target image: `IMAGE_PREINSTALL`. These packages will be taken from `apt` source.

The user may use `met-isar/recipes-core-images` as a template for new image recipes creation.

---

## Add a New Image Type
### General Information
The image recipe in Isar creates a folder with target root filesystem. Its default location is:
```
tmp/work/${DISTRO}-${DISTRO_ARCH}/${MACHINE}/${IMAGE}/rootfs
```
Every image type in Isar is implemented as a `bitbake` class. The goal of these classes is to pack root filesystem folder to appropriate format.

### Create Custom Image Type

As already mentioned, Isar uses `bitbake`to accomplish the work. The whole build process is a sequence of tasks. This sequence is generated using task dependencies, so the next task in chain requires completion of previous ones.
The last task of image recipe is `do_populate`, so the class that implement new image type should continue execution from this point. According to the BitBake syntax, this can be implemented as follows:

Create a new class:
```
$ vim meta-user/classes/my-image.bbclass
```
Add these lines:
```
do_my_image() {
}
addtask my_image before do_build after do_populate
```
The content of `do_my_image` function can be implemented either in shell or in Python.

In the machine configuration file, set the following:
```
IMAGE_TYPE = "my-image"
```

### Reference Classes

Isar contains additional image type classes that can be used as reference:

 - `ext4-img`
 - `rpi-sdimg`
 - `targz-img`
 - `ubifs-img`
 - `ubi-img`
 - `wic-img`

---

## Customize and configure image

Customization and configuration of an image can be done in two ways:

 1. Creating and adding a configuration package to `IMAGE_INSTALL`, or
 2. Changing the bitbake variables of the image recipe.

In cases where configuration is not image specific, does not contain any secrets and can be shared between images, creating and adding a configuration package to `IMAGE_INSTALL` is the right option. This should be the case with most product specific configuration files.

In cases where the configuration would contain secrets like user passwords, that would be world readable in `postinst`, etc. script files, some image extensions where created, that allow customization of those options from within the image recipe using bitbake variables. (e.g. user and group management and locale settings)

### Locale configuration

Two variables can be used to configure the locale installed on a image:

 - `LOCALE_GEN` - A `\n` seperated list of `/etc/locale.gen` entries desired on the target.
 - `LOCALE_DEFAULT` - The default locale used for the `LANG` and `LANGUAGE` variable in `/etc/locale`.

### User and group configuration

Groups can be created or modified using the `GROUPS` and `GROUP_<groupname>` variable or their flags.

The `GROUPS` variable contains a space separated list of group names that should be modified or created. Each entry of this variable should have a corresponding `GROUP_<groupname>` variable.

The `GROUP_<groupname>` variable contains the settings of a group named `groupname` in its flags. The following flags can be used:

 - `gid` - The numeric group id.
 - `flags` - A list of additional flags of the group. Those are the currently recognized flags:
   - `system` - The group is created using the `--system` parameter.

The `USERS` and `USER_<username>` variable works similar to the `GROUPS` and `GROUP_<groupname>` variable. The difference are the accepted flags of the `USER_<username>` variable. It accepts the following flags:

 - `password` - The crypt(3) encrypted password. To encrypt a password use for example `mkpasswd` or `openssl passwd -6`. You can find `mkpasswd` in the `whois` package of Debian.
 - `expire` - A `YYYY-MM-DD` formatted date on which the user account will be disabled. (see useradd(8))
 - `inactive` - The number of days after a password expires until the account is permanently disabled. (see useradd(8))
 - `uid` - The numeric user id.
 - `gid` -  The numeric group id or group name of this users initial login group.
 - `comment` - This users comment field. Commonly the following format `full name,room number,work phone number,home phone number,other entry`.
 - `home` - This users home directory
 - `shell` - This users login shell
 - `groups` - A space separated list of groups this user is a member of.
 - `flags` - A list of additional flags of the user:
   - `no-create-home` - `useradd` will be called with `-M` to prevent creation of the users home directory.
   - `create-home` - `useradd` will be called with `-m` to force creation of the users home directory.
   - `system` - `useradd` will be called with `--system`.
   - `allow-empty-password` - Even if the `password` flag is empty, it will still be set. This results in a login without password.

---

## Create a Custom Image Recipe

A custom image recipe may be created to assemble packages of your choice into a root file-system image. The `image` class
implements a `do_rootfs` function to compile and configure the file-system for you. Prebuilt packages may be selected for
installation by appending them to the `IMAGE_PREINSTALL` variable while packages created by ISAR should be appended to
`IMAGE_INSTALL`. A sample image recipe follows.

### Example
```
DESCRIPTION = "Sample image recipe for ISAR"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

IMAGE_PREINSTALL = " \
    openssh-server   \
"

inherit image

```

### Additional Notes

The distribution selected via the `DISTRO` variable may need to run a post-configuration script after the root file-system
was assembled. Isar provides scripts for Debian and Raspbian. In the event where a different Debian-based distribution is
used, your custom image recipe may need to set `DISTRO_CONFIG_SCRIPT` and use `SRC_URI` and `FILESPATH` for the script to
be copied into the work directory (`WORKDIR`).

---

## Add a Custom Application

Before creating a new recipe it's highly recommended to take a look into the BitBake user manual mentioned in Terms and Definitions section.

Isar currently supports two ways of creating custom packages.

### Compilation of debianized-sources

The `deb` packages are built using `dpkg-buildpackage`, so the sources should contain the `debian` directory with necessary meta information. This way is the default way of adding software that needs to be compiled from source. The bbclass for this approach is called `dpkg`.

**NOTE:** If the sources do not contain a `debian` directory your recipe can fetch, create, or ship that.

This is also what you do if you want to rebuild/modify an upstream package.
Isar does understand `SRC_URI` entries starting with "apt://". For an example
of a customized upstream package have a look at `meta-isar/recipes-app/hello`.

#### Example
```
DESCRIPTION = "Sample application for ISAR"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "0.3-a18c14c"

SRC_URI = "git://github.com/ilbers/hello.git"
SRCREV = "a18c14cc11ce6b003f3469e89223cffb4016861d"

S = "${WORKDIR}/git"

inherit dpkg
```

The following variables are used in this recipe:

 - `DESCRIPTION` - Textual description of the package.
 - `LICENSE` - Application license file.
 - `LIC_FILES_CHKSUM` - Reference to the license file with its checksum. Isar recommends to store license files for your applications into layer your layer folder `meta-user/licenses/`. Then you may reference it in recipe using the following path:

    ```
    LIC_FILES_CHKSUM = file://${LAYERDIR_core}/licenses/...
    ```
This approach prevents duplication of the license files in different packages.

 - `PV` - Package version.
 - `SRC_URI` - The link where to fetch application source. Please check the BitBake user manual for supported download formats.
 - `S` - The directory name where application sources will be unpacked. For `git` repositories, it should be set to `git`. Please check the BitBake user manual for supported download formats.
 - `SRCREV` - Source code revision to fetch. Please check the BitBake user manual for supported download formats.

The last line in the example above adds recipe to the Isar work chain.

### Packages without source

If your customization is not about compiling from source there is a second way of creating `deb` packages. That way can be used for cases like:

 - packaging binaries/files that where built outside of Isar
 - customization of the rootfs with package-hooks
 - pulling in dependancies (meta-packages)

The bbclass for this approach is called `dpkg-raw`.

#### Example
```
DESCRIPTION = "Sample application for ISAR"
MAINTAINER = "Your name here <you@domain.com>"
DEBIAN_DEPENDS = "apt"

inherit dpkg-raw

do_install() {
....
}
```
For the variables please have a look at the previous example, the following new variables are required by `dpkg-raw` class:
 - `MAINTAINER` - The maintainer of the `deb` package we create. If the maintainer is undefined, the recipe author should be mentioned here
 - `DEBIAN_DEPENDS` - Debian packages that the package depends on

Have a look at the `example-raw` recipe to get an idea how the `dpkg-raw` class can be used to customize your image.
Note that the package will be build using the whole debian package workflow, so your package will be checked by many debhelper scripts. If those helpers point out quality issues it might be a good idea to fix them. But `example-raw` also shows how rules can still be violated.

## Isar Cross-compilation

### Motivation

binfmt is a powerful feature that makes possible to run foreign architectures like ARM on x86 hosts. But at the same the performance of
such emulation is quite low. For the cases when lots of packages should be built from sources, a cross-compilation support could be very
useful.

### Solution

Cross-compilation mode could be enabled by using the `ISAR_CROSS_COMPILE` variable. This variable could be set in both:

 - In `local.conf` to set cross-compilation mode to be the default option for the whole build.
 - In specific recipe to overwrite global settings. This could be useful when package doesn't support cross-compilation, so the following line
   should be added to its recipe: `ISAR_CROSS_COMPILE := "0"`.

The cross-building process is absolutely the same as for native compilation, no extra tasks are added and removed: newly built packages are
put into Isar apt.

### Limitation

Debian cross-compilation works out of the box starting from Debian stretch distribution. Currently the following build configurations are supported in Isar:

 - qemuarm-stretch
 - qemuarm-buster
 - qemuarm64-stretch
 - qemuarm64-buster (for host >= buster)


## Create an ISAR SDK root filesystem

### Motivation

Building applications for targets in ISAR takes a lot of time as they are built under QEMU.
SDK providing crossbuild environment will help to solve this problem.

### Approach

Create SDK root file system for host with installed cross-toolchain for target architecture and ability to install already prebuilt
target binary artifacts. Developer chroots to sdk rootfs and develops applications for target platform.

### Solution

User manually triggers creation of SDK root filesystem for his target platform by launching the task `do_populate_sdk` for target image, f.e.
`bitbake -c do_populate_sdk multiconfig:${MACHINE}-${DISTRO}:isar-image-base`.

The resulting SDK rootfs is archived into `tmp/deploy/images/${MACHINE}/sdk-${DISTRO}-${DISTRO_ARCH}.tar.xz`.
It is additionally available for direct use under `tmp/deploy/images/${MACHINE}/sdk-${DISTRO}-${DISTRO_ARCH}/`.
The SDK rootfs directory `/isar-apt` contains a copy of isar-apt repo with locally prebuilt target debian packages (for <HOST_DISTRO>).
One may chroot into the SDK and install required target packages with the help of `apt-get install <package_name>:<DISTRO_ARCH>` command.

### Example

 - Trigger creation of SDK root filesystem

```
bitbake -c do_populate_sdk multiconfig:qemuarm-stretch:isar-image-base
```

 - Mount the following directories in chroot by passing resulting rootfs as an argument to the script `mount_chroot.sh`:

```
cat scripts/mount_chroot.sh
#!/bin/sh

set -e

mount /tmp     $1/tmp                 -o bind
mount proc     $1/proc    -t proc     -o nosuid,noexec,nodev
mount sysfs    $1/sys     -t sysfs    -o nosuid,noexec,nodev
mount devtmpfs $1/dev     -t devtmpfs -o mode=0755,nosuid
mount devpts   $1/dev/pts -t devpts   -o gid=5,mode=620
mount tmpfs    $1/dev/shm -t tmpfs    -o rw,seclabel,nosuid,nodev

$ sudo scripts/mount_chroot.sh ../build/tmp/deploy/images/qemuarm/sdk-debian-stretch-armhf

```

 - chroot to isar SDK rootfs:

```
$ sudo chroot build/tmp/deploy/images/qemuarm/sdk-debian-stretch-armhf
```
 - Check that cross toolchains are installed

```
:~# dpkg -l | grep crossbuild-essential-armhf
ii  crossbuild-essential-armhf           12.3                   all          Informational list of cross-build-essential packages
```

 - Install needed prebuilt target packages.

```
:~# apt-get update
:~# apt-get install libhello-dev:armhf
```

 - Check the contents of the installed target package

```
:~# dpkg -L libhello-dev
/.
/usr
/usr/include
/usr/include/hello.h
/usr/lib
/usr/lib/arm-linux-gnueabihf
/usr/lib/arm-linux-gnueabihf/libhello.a
/usr/lib/arm-linux-gnueabihf/libhello.la
/usr/share
/usr/share/doc
/usr/share/doc/libhello-dev
/usr/share/doc/libhello-dev/changelog.gz
/usr/share/doc/libhello-dev/copyright
~#
```

## Creation of local apt repo caching upstream Debian packages

### Motivation

Cache upstream debian packages to reduce time for further downloads and to be able to work offline.

### Solution

 - Signing of local repo (optional)

By default, the local caching repo is not gpg signed. If you want to share it in a trusted way, you may sign it.
To do that, install `gpg` in your build environment, import the public and private keys,
and provide the path to the public key in `conf/local.conf`, e.g.:

```
BASE_REPO_KEY = "file://<absolute_path_to_your_pub_key_file>"'
```

 - Trigger creation of local apt caching Debian packages during image generation.

```
bitbake -c cache_base_repo multiconfig:qemuarm-stretch:isar-image-base
```

 - Set `ISAR_USE_CACHED_BASE_REPO` in `conf/local.conf`:

```
# Uncomment this to enable use of cached base repository
#ISAR_USE_CACHED_BASE_REPO ?= "1"
```
 - Remove build artifacts to use only local base-apt:

```
sudo rm -rf tmp

```

 - Trigger again generation of image (now using local caching repo):

```
bitbake multiconfig:qemuarm-stretch:isar-image-base
```

### Limitation

Files fetched with the `SRC_URI` protocol "apt://" are not yet cached.

## Add foreign packages from other repositories to the generated image

### Motivation

When building embedded systems with Isar, one might want to include packages that are not provided by debian by default. One example is docker-ce.

### Approach/Solution

Add a new sources list entry to fetch the package from, i.e. include a new apt source mirror. Then add the needed apt key for the third party repository. Add the wanted package to the IMAGE_PREINSTALL variable.

### Example

Add docker-ce from arm64:

Create a new layer containing `conf/distro/docker-stretch.list` with the following content:

```
deb [arch=arm64] https://download.docker.com/linux/debian	stretch	stable
```

Include the layer in your project.

To the local.conf add:

```
IMAGE_PREINSTALL += "docker-ce"
THIRD_PARTY_APT_KEYS_append = " https://download.docker.com/linux/debian/gpg;md5sum=1afae06b34a13c1b3d9cb61a26285a15"
DISTRO_APT_SOURCES_append = " conf/distro/docker-stretch.list"
```

And build the corresponding image target:

```
bitbake multiconfig:qemuarm64-stretch:isar-image-base
```
