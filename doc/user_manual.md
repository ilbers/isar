# ISAR User Manual

Copyright (C) 2016-2017, ilbers GmbH

## Contents

 - [Introduction](https://github.com/ilbers/isar/blob/master/doc/user_manual.md#introduction)
 - [Getting Started](https://github.com/ilbers/isar/blob/master/doc/user_manual.md#getting-started)
 - [Terms and Definitions](https://github.com/ilbers/isar/blob/master/doc/user_manual.md#terms-and-definitions)
 - [How Isar Works](https://github.com/ilbers/isar/blob/master/doc/user_manual.md#how-isar-works)
 - [General Isar Configuration](https://github.com/ilbers/isar/blob/master/doc/user_manual.md#general-isar-configuration)
 - [Isar Distro Configuration](https://github.com/ilbers/isar/blob/master/doc/user_manual.md#isar-distro-configuration)
 - [Custom Package Compilation](https://github.com/ilbers/isar/blob/master/doc/user_manual.md#custom-package-compilation-1)
 - [Image Type Selection](https://github.com/ilbers/isar/blob/master/doc/user_manual.md#image-type-selection)
 - [Add a New Distro](https://github.com/ilbers/isar/blob/master/doc/user_manual.md#add-a-new-distro)
 - [Add a New Machine](https://github.com/ilbers/isar/blob/master/doc/user_manual.md#add-a-new-machine)
 - [Add a New Image](https://github.com/ilbers/isar/blob/master/doc/user_manual.md#add-a-new-image)
 - [Add a New Image Type](https://github.com/ilbers/isar/blob/master/doc/user_manual.md#add-a-new-image-type)
 - [Add a Custom Application](https://github.com/ilbers/isar/blob/master/doc/user_manual.md#add-a-custom-application)

## Introduction

Isar is a set of scripts for building software packages and repeatable generation of Debian-based root filesystems with customizations.

Isar provides:

 - Fast target image generation: About 10 minutes to get base system image for one machine.
 - Use any apt package provider, including open-source communities like `Debian`, `Raspbian`, etc. and proprietary ones created manually.
 - Native compilation: Packages are compiled in a `chroot` environment using the same toolchain and libraries that will be installed to the target filesystem.
 - Product templates that can be quickly re-used for real projects.

---

## Getting Started

For demonstration purposes, Isar provides support for the following
configurations:

 - QEMU ARM with Debian Wheezy
 - QEMU ARM with Debian Jessie
 - QEMU ARM with Debian Stretch (builds but fails to run, see #22)
 - QEMU i386 with Debian Jessie
 - QEMU i386 with Debian Stretch
 - QEMU amd64 with Debian Jessie
 - QEMU amd64 with Debian Stretch
 - Raspberry Pi 1 Model B with Raspbian Jessie (see #23)

The steps below describe how to build the images provided by default.

### Install Host Tools

Install the following packages:
```
dosfstools
e2fsprogs/jessie-backports  # wic: e2fsprogs -d
gdisk                       # wic
git
grub-efi-amd64-bin          # wic UEFI: /usr/lib/grub/x86_64-efi/moddep.lst
grub-efi-ia32-bin           # wic UEFI: /usr/lib/grub/i386-efi/moddep.lst
mtools                      # wic FAT: mcopy
multistrap
parted
python
python3                     # wic
qemu
qemu-user-static
rxvt-unicode                # build_parallel
binfmt-support
sudo
reprepro
```

Notes:

* BitBake requires Python 3.4+.
* The python3 package is required for the correct `alternatives` setting.
* QEMU 2.8+ is required to run Stretch images locally in QEMU. This version is available in Stretch and Jessie backports apts.
* e2fsprogs v1.42- required for building Wheezy images.

### Setup Sudo

Isar requires `sudo` rights without password to work with `chroot` and `multistrap`. To add them, use the following steps:
```
 # visudo
```
In the editor, allow the current user to run sudo without a password, e.g.:
```
 <user>  ALL=NOPASSWD: ALL
```
Replace `<user>` with your user name. Use the tab character between the user name and parameters.

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
DISTRO ??= "debian-jessie"
DISTRO_ARCH ??= "armhf"
```

Then, call `bitbake` with image names, e.g.:

```
bitbake isar-image-base isar-image-debug
```

The following images are created:

```
tmp/deploy/images/isar-image-base-qemuarm-debian-jessie.ext4.img
tmp/deploy/images/isar-image-debug-qemuarm-debian-jessie.ext4.img
```

### Building Target Images for Multiple Configurations

Alternatively, BitBake supports building images for multiple configurations in
a single call. List all configurations in `conf/local.conf`:

```
BBMULTICONFIG = " \
    qemuarm-wheezy \
    qemuarm-jessie \
    qemuarm-stretch \
    qemui386-jessie \
    qemui386-stretch \
    qemuamd64-jessie \
    qemuamd64-stretch \
    rpi-jessie \
"
```

The following command will produce `isar-image-base` images for all targets:

```
$ bitbake multiconfig:qemuarm-wheezy:isar-image-base \
    multiconfig:qemuarm-jessie:isar-image-base \
    multiconfig:qemuarm-stretch:isar-image-base \
    multiconfig:qemui386-jessie:isar-image-base \
    multiconfig:qemui386-stretch:isar-image-base \
    multiconfig:qemuamd64-jessie:isar-image-base \
    multiconfig:qemuamd64-stretch:isar-image-base \
    multiconfig:rpi-jessie:isar-image-base
```

Created images are:

```
tmp/deploy/images/isar-image-base-debian-wheezy-qemuarm.ext4.img
tmp/deploy/images/isar-image-base-debian-jessie-qemuarm.ext4.img
tmp/deploy/images/isar-image-base-debian-stretch-qemuarm.ext4.img
tmp/deploy/images/isar-image-base-debian-jessie-qemui386.ext4.img
tmp/deploy/images/isar-image-base-debian-stretch-qemui386.ext4.img
tmp/deploy/images/isar-image-base-debian-jessie-qemuamd64.ext4.img
tmp/deploy/images/isar-image-base-debian-stretch-qemuamd64.ext4.img
tmp/deploy/images/isar-image-base.rpi-sdimg
```

The BitBake revision included with Isar seems to serialize multiconfig builds.
The following script may be used from the project directory (`isar`) to build
multiple configurations in different build directories faster:

```
scripts/build_parallel ../build multiconfig:qemuarm-wheezy:isar-image-base \
    multiconfig:qemuarm-jessie:isar-image-base \
    multiconfig:qemuarm-stretch:isar-image-base \
    multiconfig:qemui386-jessie:isar-image-base \
    multiconfig:qemui386-stretch:isar-image-base \
    multiconfig:qemuamd64-jessie:isar-image-base \
    multiconfig:qemuamd64-stretch:isar-image-base \
    multiconfig:rpi-jessie:isar-image-base
```

Created images are:

```
../build-1/tmp/deploy/images/isar-image-base-debian-wheezy-qemuarm.ext4.img
../build-2/tmp/deploy/images/isar-image-base-debian-jessie-qemuarm.ext4.img
../build-3/tmp/deploy/images/isar-image-base-debian-stretch-qemuarm.ext4.img
../build-4/tmp/deploy/images/isar-image-base-debian-jessie-qemui386.ext4.img
../build-5/tmp/deploy/images/isar-image-base-debian-stretch-qemui386.ext4.img
../build-6/tmp/deploy/images/isar-image-base-debian-jessie-qemuamd64.ext4.img
../build-7/tmp/deploy/images/isar-image-base-debian-stretch-qemuamd64.ext4.img
../build-8/tmp/deploy/images/isar-image-base.rpi-sdimg
```

### Generate EFI disk images

Once the image artifacts have been built (c.f. previous section), full EFI disk images can be generated using the `wic` utility.
Currently, only the `i386` and `amd64` target architectures are supported:
```
 # Generate an EFI image for the `i386` target architecture
 $ wic create -D sdimage-efi -o . -e multiconfig:qemui386-stretch:isar-image-base
 # Similarly, for the `amd64` target architecture
 $ wic create -D sdimage-efi -o . -e multiconfig:qemuamd64-stretch:isar-image-base
```

In order to run the images with `qemu`, an EFI firmware is required and available at the following address:
https://github.com/tianocore/edk2/tree/3858b4a1ff09d3243fea8d07bd135478237cb8f7

Note that the `ovmf` package in Debian jessie/stretch/sid contains a pre-compiled firmware, but doesn't seem to be recent
enough to allow images to be testable under `qemu`.

```
# AMD64 image
qemu-system-x86_64 -m 256M -nographic -bios edk2/Build/OvmfX64/RELEASE_*/FV/OVMF.fd -hda ./sdimage-*
# i386 image
qemu-system-i386 -m 256M -nographic -bios edk2/Build/OvmfIa32/RELEASE_*/FV/OVMF.fd -hda ./sdimage-*
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

 - `DISTRO` - The distro to use (e.g., `debian-wheezy`, `raspbian-jessie`).
   BitBake looks for conf/distro/${DISTRO}.conf in every layer.

 - `DISTRO_ARCH` - The Debian architecture to build for (e.g., `armhf`).

If BitBake is called with multiconfig targets (e.g.,
`multiconfig:qemuarm-jessie:isar-image-base`), the following variable defines
all supported configurations:

 - `BBMULTICONFIG` - The list of the complete configuration definition files.
   BitBake looks for conf/multiconfig/<CONFIG>.conf in every layer. Every
   configuration must define `MACHINE`, `DISTRO` and `DISTRO_ARCH`.

Some other variables include:

 - `IMAGE_INSTALL` - The list of custom packages to build and install to target image, please refer to relative chapter for more information.
 - `BB_NUMBER_THREADS` - The number of `bitbake` jobs that can be run in parallel. Please set this option according your host CPU cores number.

---

## Isar Distro Configuration

In Isar, each machine can use its specific Linux distro to generate `buildchroot` and target filesystem. By default, Isar provides configuration files for the following distros:

 - debian-wheezy
 - debian-jessie
 - debian-stretch
 - raspbian-jessie

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

Isar can generate various images types for specific machine. The `IMAGE_TYPE` variable contains the list of image types to generate. Currently, the following image types are provided:

 - `ext4` - Raw ext4 filesystem image (default option for `qemuarm` machine).
 - `rpi-sdimg` - A complete, partitioned Raspberry Pi SD card image (default option for the `rpi` machine).
 
---

## Add a New Distro

The distro is defined by the set of the following variables:

 - `DISTRO_SUITE` - Repository suite like stable, jessie, wheezy etc.
 - `DISTRO_COMPONENTS` - Repository components like main, contrib, non-free etc.
 - `DISTRO_APT_SOURCE` - Repository URL.
 - `DISTRO_CONFIG_SCRIPT` - Target filesystem finalization script. This script is called after `multistrap` has unpacked the base system packages. It is designed to finalize filesystem, for example to add `fstab` according to machine hardware configuration. The script should be placed to `files` folder in image recipe folder.

Below is an example for Raspbian Jessie:
```
DISTRO_SUITE = "jessie"
DISTRO_COMPONENTS = "main contrib non-free firmware"
DISTRO_APT_SOURCE = "http://archive.raspbian.org/raspbian"
DISTRO_CONFIG_SCRIPT = "raspbian-configscript.sh"
```

To add new distro, user should perform the following steps:

 - Create `distro` folder in your layer:

    ```
    $ mkdir meta-user/conf/distro
    ```

 - Create the `.conf` file in distro folder with the name of your distribution. We recommend to name distribution in the following format: `name`-`suite`, for example:

    ```
    debian-wheezy
    debian-jessie
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
 - `Multistrap` configuration file - Contains information about distro, suite, `apt` source etc.
 - `Multistrap` setup script - Performs pre-install filesystem configuration.
 - `Multistrap` config script - Performs post-install filesystem configuration.

In image recipe, the following variable defines the list of packages that will be included to target image: `IMAGE_PREINSTALL`. These packages will be taken from `apt` source.

The user may use `met-isar/recipes-core-images` as a template for new image recipes creation.

---

## Add a New Image Type
### General Information
The image recipe in Isar creates a folder with target root filesystem. The default its location is:
```
tmp/work/${IMAGE}/${MACHINE}/rootfs
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

Isar contains two image type classes that can be used as reference:

 - `ext4-img`
 - `rpi-sdimg`

---

## Add a Custom Application

Before creating a new recipe it's highly recommended to take a look into the BitBake user manual mentioned in Terms and Definitions section.

Isar currently supports two ways of creating custom packages.

### Compilation of debianized-sources

The `deb` packages are built using `dpkg-buildpackage`, so the sources should contain the `debian` directory with necessary meta information. This way is the default way of adding software that needs to be compiled from source. The bbclass for this approach is called `dpkg`.

**NOTE:** If the sources do not contain a `debian` directory your recipe can fetch, create, or ship that.


#### Example
```
DESCRIPTION = "Sample application for ISAR"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

SRC_URI = "git://github.com/ilbers/hello.git"
SRCREV = "ad7065ecc4840cc436bfcdac427386dbba4ea719"

S = "git"

inherit dpkg
```

The following variables are used in this recipe:

 - `DESCRIPTION` - Textual description of the package.
 - `LICENSE` - Application license file.
 - `LIC_FILES_CHKSUM` - Reference to the license file with its checksum. Isar recommends to store license files for your applications into layer your layer folder `meta-user/licenses/`. Then you may reference it in recipe using the following path:

    ```
    LIC_FILES_CHKSUM = file://${LAYERDIR_isar}/licenses/...
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

do_populate_package() {
....
}
```
For the variables please have a look at the previous example, the following new variables are required by `dpkg-raw` class:
 - `MAINTAINER` - The maintainer of the `deb` package we create. If the maintainer is undefined, the recipe author should be mentioned here
 - `DEBIAN_DEPENDS` - Debian packages that the package depends on

Have a look at the `example-raw` recipe to get an idea how the `dpkg-raw` class can be used to customize your image.
