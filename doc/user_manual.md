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
 - [Build statistics collection](#build-statistics-collection)
 - [Enabling Cross-compilation](#isar-cross-compilation)
 - [Using ccache for custom packages](#using-ccache-for-custom-packages)
 - [Using sstate-cache](#using-sstate-cache)
 - [Create an ISAR SDK root filesystem](#create-an-isar-sdk-root-filesystem)
 - [Create a containerized Isar SDK root filesystem](#create-a-containerized-isar-sdk-root-filesystem)
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
 - Raspberry Pi various models with Raspberry OS Bullseye
 - Banana Pi BPI-M1
 - LeMaker HiKey
 - Terasic DE0-Nano-SoC

The steps below describe how to build the images provided by default.

### Install Host Tools

The supported host system is >= stretch.

Install the following packages:
```
apt install \
  binfmt-support \
  debootstrap \
  dosfstools \
  dpkg-dev \
  gettext-base \
  git \
  mtools \
  parted \
  python3 \
  quilt \
  qemu \
  qemu-user-static \
  reprepro \
  sudo
```

If your host is >= buster, also install the following package.
```
apt install python3-distutils
```

If you want to generate containerized SDKs, also install the following 
packages: `umoci` and `skopeo`.
Umoci is provided by Debian Buster and can be installed with 
`apt install umoci`, Skopeo is provided by Debian Bullseye/Unstable and has to 
be installed either manually downloading the DEB and installing it (no other 
packages required) or with `apt install -t bullseye skopeo` (if 
unstable/bullseye included in `/etc/apt/sources.list[.d]`).

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
DISTRO ??= "debian-buster"
DISTRO_ARCH ??= "armhf"
```

Then, call `bitbake` with image names, e.g.:

```
bitbake mc:qemuarm-buster:isar-image-base \
        mc:qemuarm-buster:isar-image-debug
```

The following images are created:

```
tmp/deploy/images/qemuarm/isar-image-base-qemuarm-debian-buster.ext4.img
tmp/deploy/images/qemuarm/isar-image-debug-qemuarm-debian-buster.ext4.img
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
    mc:qemuarm-stretch:isar-image-base \
    mc:qemuarm-buster:isar-image-base \
    mc:qemuarm64-stretch:isar-image-base \
    mc:qemui386-stretch:isar-image-base \
    mc:qemui386-buster:isar-image-base \
    mc:qemuamd64-stretch:isar-image-base \
    mc:qemuamd64-buster:isar-image-base \
    mc:rpi-stretch:isar-image-base
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
tmp/deploy/images/rpi/isar-image-base-raspbian-stretch-rpi.wic.img
```

### Generate full disk image

A bootable disk image is generated if `wic-img` is listed in IMAGE_FSTYPES.
Behind the scenes a tool called `wic` is used to assemble the images.
It is controlled by a `.wks` file which you can choose with changing WKS_FILE.
Some examples in the tree use that feature already.
```
 # Generate an image for the `i386` target architecture
 $ bitbake mc:qemui386-buster:isar-image-base
 # Similarly, for the `amd64` target architecture, in this case EFI
 $ bitbake mc:qemuamd64-buster:isar-image-base
```

Variables may be used in `.wks.in` files; Isar will expand them and generate a regular `.wks` file before generating the disk image using `wic`.

In order to run the EFI images with `qemu`, an EFI firmware is required and available at the following address:
https://github.com/tianocore/edk2/tree/3858b4a1ff09d3243fea8d07bd135478237cb8f7

Note that the `ovmf` package in Debian stretch/buster contains a pre-compiled firmware, but doesn't seem to be recent
enough to allow images to be testable under `qemu`.

```
# AMD64 image, EFI
qemu-system-x86_64 -m 256M -nographic -bios edk2/Build/OvmfX64/RELEASE_*/FV/OVMF.fd -hda tmp/deploy/images/qemuamd64/isar-image-base-debian-buster-qemuamd64.wic.img
# i386 image
qemu-system-i386 -m 256M -nographic -hda tmp/deploy/images/qemui386/isar-image-base-debian-buster-qemui386.wic.img
```

#### Flashing such images to a physical device

wic images can be flashed in multiple ways. The most generic and easy way is probably with [ etcher ](https://etcher.io). That works on many operating systems and is relatively easy to use. On top it can decompress images on the fly, should they be compressed. It also offers some sort of protection so you do not write to the wrong device and maybe break your machine.

If you have a unix shell there are other ways. Make sure to always double check the target device, those tools might not warn if you choose the wrong target.

`bmaptool` would be the best choice on a Linux/Unix system. It offers skipping of empty space and will flash much faster than `dd`, it also has some protection so you do not flash over a mounted drive by accident. Unfortunately it is not yet available on all Linux distributions.
https://github.com/intel/bmap-tools

`dd` is the most generic option, available pretty much everywhere. But here you really need to make sure to not write to the wrong target.

### Generate container image with root filesystem

A runnable container image is generated if IMAGE_FSTYPES variable includes
'container-img'.
Getting a container image can be the main purpose of an Isar configuration, 
but not only.
A container image created from an Isar configuration meant for bare-metal or 
virtual machines can be helpfull to test certain applications which 
requirements (e.g. libraries) can be easily resolved in a containerized 
environment.

Container images can be generated in different formats, selected with the 
variable `CONTAINER_IMAGE_FORMATS`. One or more (whitespace separated) of following 
options can be given:
 - `docker-archive`: (default) an archive containing a Docker image that can 
   be imported with [`docker load`](https://docs.docker.com/engine/reference/commandline/load)
 - `docker-daemon`: resulting container image is made available on the local 
   Docker Daemon
 - `containers-storage`: resulting container image is made available to tools 
   using containers/storage back-end (e.g. Podman, CRIO, buildah,...)
 - `oci-archive`: an archive containing an OCI image, mostly for archiving as 
   seed for any of the above formats

Following formats don't work if running `bitbake ...` (to build the image) 
from inside of a container (e.g. using `kas-container`): `docker-daemon` and 
`containers-storage`.
It's technically possible, but requires making host resources (e.g. the 
Docker Daemon socket) accessible in the container, which can endanger the 
stability and security of the host.

The resulting container image archives (only for `docker-archive` and 
`oci-archive`) are made available as 
`tmp/deploy/images/${MACHINE}/${DISTRO}-${DISTRO_ARCH}-${container_format}.tar.xz` 
(being `container_format` each one of the formats specified in 
`CONTAINER_IMAGE_FORMATS`).

### Example

 - Make the relevant environment variables available to the task

For one-shot builds (use `local.conf` otherwise):

```
export BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE IMAGE_TYPE CONTAINER_IMAGE_FORMATS"
export IMAGE_FSTYPES="container-img"
export CONTAINER_IMAGE_FORMATS="docker-archive"
```

 - Trigger creation of container image from root filesystem

```
bitbake mc:qemuarm-buster:isar-image-base
```

 - Load the container image into the Docker Daemon

```
docker load -i build/tmp/deploy/images/qemuarm/isar-image-base-debian-buster-armhf-1.0-r0-docker-archive.tar.xz
```

 - Run a container using the container image (following commands starting with 
   `#~:` are to be run in the container)

```
docker run --rm -ti --volume "$(pwd):/build" isar-image-base-debian-buster-armhf:1.0-r0
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
`mc:qemuarm-buster:isar-image-base`), the following variable defines
all supported configurations:

 - `BBMULTICONFIG` - The list of the complete configuration definition files.
   BitBake looks for `conf/multiconfig/<CONFIG>.conf` in every layer. Every
   configuration must define `MACHINE`, `DISTRO` and `DISTRO_ARCH`.

Some other variables include:

 - `IMAGE_INSTALL` - The list of custom packages to build and install to target image, please refer to relative chapter for more information.
 - `BB_NUMBER_THREADS` - The number of `bitbake` jobs that can be run in parallel. Please set this option according your host CPU cores number.
 - `HOST_DISTRO` - The distro to use for SDK root filesystem. This variable is optional.
 - `HOST_ARCH` - The Debian architecture of SDK root filesystem (e.g., `amd64`). By default set to current Debian host architecture. This variable is optional.
 - `HOST_DISTRO_APT_SOURCES` - List of apt source files for SDK root filesystem. This variable is optional.
 - `HOST_DISTRO_APT_PREFERENCES` - List of apt preference files for SDK root filesystem. This variable is optional.
 - `HOST_DISTRO_BOOTSTRAP_KEYS` - Analogously to DISTRO_BOOTSTRAP_KEYS: List of gpg key URIs used to verify apt bootstrap repo for the host.
 - `DISTRO_APT_PREMIRRORS` - The preferred mirror (append it to the default URI in the format `ftp.debian.org my.preferred.mirror`. This variable is optional. PREMIRRORS will be used only for the build. The final images will have the sources list as mentioned in DISTRO_APT_SOURCES.
 - `THIRD_PARTY_APT_KEYS` - List of gpg key URIs used to verify apt repos for apt installation after bootstrapping
 - `FILESEXTRAPATHS` - The default directories BitBake uses when it processes recipes are initially defined by the FILESPATH variable. You can extend FILESPATH variable by using FILESEXTRAPATHS.
 - `FILESOVERRIDES` - A subset of OVERRIDES used by the build system for creating FILESPATH. The FILESOVERRIDES variable uses overrides to automatically extend the FILESPATH variable.
 - `IMAGER_INSTALL` -  The list of package dependencies for an imager like wic.

---

## Isar Distro Configuration

In Isar, each machine can use its specific Linux distro to generate `buildchroot` and target filesystem. By default, Isar provides configuration files for the following distros:

 - debian-stretch
 - debian-buster
 - raspbian-stretch
 - raspios-bullseye

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

Isar can generate various images types for specific machine. The type of the
image to be generated may be specified through the `IMAGE_FSTYPES` variable.
Currently, the following image types are provided:

 - `ext4` - Raw ext4 filesystem image (default option for `qemuarm` machine).
 - `wic-img` - A full disk image with user-specified partitions created and populated using the wic tool.
 - `ubi-img` - A image for use on mtd nand partitions employing UBI
 - `vm-img` - A image for use on VirtualBox or VMware

There are several image types can be listed in `IMAGE_FSTYPES` divided by space.

Instead of setting multiple image types in one target, user can also use
[multiconfig](#building-target-images-for-multiple-configurations) feature and specify
different image types in different multiconfigs (use qemuamd64-buster-cpiogz.conf
and qemuamd64-buster-tgz.conf as examples). The only requirement is that image types
from different multiconfigs for the same machine/distros should not overlap.

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

For RaspiOS a different DISTRO_KERNELS list is used:
 - `kernel` - for Raspberry Pi 1, Pi Zero, Pi Zero W, and Compute Module
 - `kernel7` - for Raspberry Pi 2, Pi 3, Pi 3+, and Compute Module 3
 - `kernel7l` - for Raspberry Pi 4 (32 bit OS)
 - `kernel8` - for Raspberry Pi 4 (64 bit OS)

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
 - `IMAGE_FSTYPES` - The types of images to be generated for this machine.

Below is an example of machine configuration file for `Raspberry Pi` board:
```
IMAGE_PREINSTALL = "linux-image-rpi-rpfv \
                    raspberrypi-bootloader-nokernel"
KERNEL_IMAGE = "vmlinuz-4.4.0-1-rpi"
INITRD_IMAGE = "initrd.img-4.4.0-1-rpi"
MACHINE_SERIAL = "ttyAMA0"
IMAGE_FSTYPES = "wic-img"
WKS_FILE = "rpi-sdimg"
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

The user may use `meta-isar/recipes-core/images` as a template for new image recipes creation.

---

## Add a New Image Type
### General Information
The image recipe in Isar creates a folder with target root filesystem. Its default location is:
```
tmp/work/${DISTRO}-${DISTRO_ARCH}/${PN}-${MACHINE}-${IMAGE_FSTYPES}/${PV}-${PR}/rootfs
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
IMAGE_FSTYPES = "my-image"
```

### Reference Classes

Isar contains additional image type classes that can be used as reference:

 - `ext4-img`
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
   - `clear-text-password` - The `password` flag of the given user contains a clear-text password and not an encrypted version of it.

#### Home directory contents prefilling

To cover all users simply use `/etc/skel`. Files in there will be available in every home directory under correct permissions.
If you have just one user you might end up abusing this for large content, that is a waste of space.

To place content into specific homes drop those files into position and create the user and possibly group in `postinst`. Now you can chown the contents because the user is known.
If you want that user to have the prefilled content combined with `/etc/skel` you need to either create the user in `preinst` or combine in `postinst`.

The regular user and group configuration will still apply later, it will just change an existing user.

meta-isar/recipes-app/example-raw contains an example

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

### Compilation of upstream sources

Isar does understand `SRC_URI` entries starting with "apt://". For an example
of a customized upstream package have a look at `meta-isar/recipes-app/hello`.
This is what you do if you want to rebuild/modify an upstream package.

### apt:// options
With apt:// you can specify the version of package you want to fetch by one of the below methods.

 - Specify the right ${PV} in the recipe name or inside the recipe.
```
inherit dpkg

PV=2.10

SRC_URI = "apt://${PN}"
```
 - You could also specify the version in SRC_URI as below
```
inherit dpkg

SRC_URI="apt://hello=2.10"
```
 - You can also specify the distribution instead of the package version.
```
inherit dpkg

SRC_URI="apt://hello/buster"
```
 - You can also ignore the ${PV} or distribution name and let apt resolve the version at build time.

Recipe filename: hello.bb
```
inherit dpkg

SRC_URI="apt://hello"
```

When you use the last two methods, apt will pull the latest source package available for that particular
distribution. This might be different than the latest binary package version available for that particular
architecture.

This happens when new source package is available via the debian security feeds, but builds are only available
for the major architectures like amd64, i386 and arm.

Please see https://www.debian.org/security/faq#archismissing for details.

If the user wants to make sure that he builds the right binary package available for their architecture,
please set ${PV}, so that the right source package is pulled for that architecture.

Below are some of the packages with this scenario at the time of writing this.

1. https://packages.debian.org/stretch/zstd
2. https://packages.debian.org/stretch/hello
3. https://packages.debian.org/stretch/apt
4. https://packages.debian.org/stretch/busybox

### Compilation of debianized-sources

The `deb` packages are built using `dpkg-buildpackage`, so the sources should contain the `debian` directory with necessary meta information. This way is the default way of adding software that needs to be compiled from source. The bbclass for this approach is called `dpkg`.

**NOTE:** If the sources do not contain a `debian` directory your recipe can fetch, create, or ship that. You might want to read the the next section before returning here.

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

### Compilation of sources from gbp-compatible repository

gbp or git-buildpackage is a utility that supports maintaining a Debian/Ubuntu package in git. Such kind of repositories can be found on salsa. They might be useful for building unreleased or older packages and patching them. The bbclass for this approach is called `dpkg-gbp`.

#### Example
```
inherit dpkg-gbp

SRC_URI = "git://salsa.debian.org/debian/cowsay.git;protocol=https"
SRC_URI += "file://isar.patch"
SRCREV = "756f0c41fbf582093c0c1dff9ff77734716cb26f"
```

For these packages `git` is used as a PATCHTOOL. This means that custom patches should be in format that allows to apply them by `git am` command.

### Compilation of sources missing the debian/-directory

The `debian` directory contains meta information on how to build a package from source. This is roughly speaking "configure", "compile", "install" all described in a Debian-specific way.
Isar expects your sources to contain the `debian` folder and the above steps need to be described in it, not in a task in a recipe.

So once you have sources you always need to combine them with a `debian` folder before Isar can build a package for you.
You might be able to find a debianization for a component on the internet, i.e. Ubuntu does package an open source component while Debian does not. Your recipe could download the `debian` folder from Ubuntu and the sources from the open source project.

You can write it yourself, which can be pretty easy but requires a bit of studying. <https://www.debian.org/doc/debian-policy/index.html>

Isar does actually contain a helper that aims to "debianize" sources for your. If your package uses a build-system that Debian knows and follows the well known "configure", "compile", "install" scheme that debianization might just fit your needs without reading Debian manuals.
If it does not fully fit your needs, it probably gives you a good starting point for your manual tuning.

The shell function `deb_debianize` creates a `debian` folder. But it will not overwrite files that already are in WORKDIR. So you can either just call it to fully generate the `debian` folder. Or you combine it with pre-existing parts.

Have a look at meta-isar/recipes-app/samefile/samefile_2.14.bb and meta/classes/debianize.bbclass for an example and the implementation.

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

### Prebuilt .deb packages from somewhere

In some cases you might find yourself having a `.deb` that someone else built,
but not a proper debian repository to add to `DISTRO_APT_SOURCES` to get it
from which would be the better way.

Such single debs can be included if need be. You just need to write a recipe
that just fetches those debs to its `WORKDIR` and deploys them. They can then
be installed via `IMAGE_INSTALL`. Have a look at `prebuilt-deb`.

---

## Build statistics collection

While isar is building the system, build statistics is collected in
`tmp/buildstats/<timestamp>` directory. This functionality is implemented in
`buildstats` class, and is enabled by `USE_BUILDSTATS= "1"` in `local.conf`.

The collected statistics can be represented visually by using
`pybootchartgui.py` script (borrowed from OpenEmbedded):
```
../scripts/pybootchartgui/pybootchartgui.py tmp/buildstats/20210911054429/ -f pdf -o ~/buildstats.pdf
```

NOTE: `python3-cairo` package is required for `pybootchartgui.py` to work:
```
sudo apt-get install python3-cairo
```

---

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

 - stretch armhf
 - stretch arm64
 - stretch mipsel
 - buster armhf
 - buster arm64 (for host >= buster)
 - buster mipsel (for host >= buster)

Experimental support for riscv64 is available as well.

### Cross-building for a compat architecture

Some architectures, under Isar amd64 and arm64 so far, support running 32-bit
legacy applications on 64-bit kernels. Debian supports this via the multiarch
concept.

Isar can build 32-bit packages as part of a 64-bit image build and also enable
the image with the necessary packages. To activate the compat mode of a build,
set `ISAR_ENABLE_COMPAT_ARCH = "1"` in `local.conf`. Packages that shall be
built for the compat arch need to be tagged individually by setting
`PACKAGE_ARCH = "${COMPAT_DISTRO_ARCH}"` in the package recipe. Non-tagged
packages will continue to be built for the primary target architecture.


## Examining and debugging package generation inside their buildchroot

Just like OpenEmbedded, Isar supports a devshell target for all dpkg package
recipes. This target opens a terminal inside the buildchroot that runs the
package build. To invoke it, just call
`bitbake mc:${MACHINE}-${DISTRO}:<package_name> -c devshell`.


## Using ccache for custom packages

While base system is created from binary Debian repositories, some user
packages are built from sources. It's possible to reduce build time
for such packages by enabling ccache.

To enable global ccache functionality, `USE_CCACHE = "1"` can be added
to `local.conf`. If some package requires ccache to be always disabled,
`USE_CCACHE = "0"` can be used in the recipe despite global setup.

By default, ccache directory is created inside `TMPDIR`, but it can be
adjusted by `CCACHE_TOP_DIR` variable in `local.conf`. Ccache directory
`CCACHE_DIR` default value is `"${CCACHE_TOP_DIR}/${DISTRO}-${DISTRO_ARCH}"`,
that means caches for different distros and architectures are not overlapped.


## Using sstate-cache

Isar supports caching of bitbake task artifacts using the sstate-cache
feature known from OpenEmbedded. Isar caches

  * the Debian bootstrap (`isar-bootstrap` recipe)
  * Debian packages (built with the `dpkg` or `dpkg-raw` classes)
  * root file systems (buildchroot and image rootfs)

The location of the sstate-cache is controlled by the variable `SSTATE_DIR`
and defaults to `${TMPDIR}/sstate-cache`.

Note that cached rootfs artifacts (bootstrap and buildchroot) have a limited
"lifetime": Isar updates their package lists for the upstream package sources
only once, when they are initially created. So as packages on the upstream
mirrors change, those lists will be out-of-date and the rootfs becomes useless.
To avoid this, it is recommended to regularly delete the contents of the
sstate-cache.

To build without using any sstate caching, you can use the bitbake argument
`--no-setscene`.


## Create an ISAR SDK root filesystem

### Motivation

Building applications for targets in ISAR takes a lot of time as they are built under QEMU.
SDK providing crossbuild environment will help to solve this problem.

### Approach

Create SDK root file system for host with installed cross-toolchain for target architecture and ability to install already prebuilt
target binary artifacts. Developer chroots to sdk rootfs and develops applications for target platform.

### Solution

User manually triggers creation of SDK root filesystem for his target platform by launching the task `do_populate_sdk` for target image, f.e.
`bitbake -c do_populate_sdk mc:${MACHINE}-${DISTRO}:isar-image-base`.
Packages that should be additionally installed into the SDK can be appended to `SDK_PREINSTALL` (external repositories) and `SDK_INSTALL` (self-built).

The resulting SDK rootfs is archived into `tmp/deploy/images/${MACHINE}/sdk-${DISTRO}-${DISTRO_ARCH}.tar.xz`.
It is additionally available for direct use under `tmp/deploy/images/${MACHINE}/sdk-${DISTRO}-${DISTRO_ARCH}/`.
The SDK rootfs directory `/isar-apt` contains a copy of isar-apt repo with locally prebuilt target debian packages (for <HOST_DISTRO>).
One may chroot into the SDK and install required target packages with the help of `apt-get install <package_name>:<DISTRO_ARCH>` command.

### Example

 - Trigger creation of SDK root filesystem

```
bitbake -c do_populate_sdk mc:qemuarm-buster:isar-image-base
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

$ sudo scripts/mount_chroot.sh ../build/tmp/deploy/images/qemuarm/sdk-debian-buster-armhf

```

 - chroot to isar SDK rootfs:

```
$ sudo chroot build/tmp/deploy/images/qemuarm/sdk-debian-buster-armhf
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

## Create a containerized Isar SDK root filesystem

### Motivation

Distributing and using the SDK root filesystem created following the 
instructions in 
"[Create an Isar SDK root filesystem](#create-an-isar-sdk-root-filesystem)" 
becomes easier using container images (at least for those using containers 
anyway).
A "containerized" SDK adds to those advantages of a normal SDK root filesystem 
the comfort of container images.

### Approach

Create container image with SDK root filesystem with installed cross-toolchain 
for target architecture and ability to install already prebuilt target binary 
artifacts.
Developer:
 - runs a container based on the resulting container image mounting the source 
   code to be built,
 - develops applications for target platform on the container and
 - leaves the container getting the results on the mounted directory.

### Solution

User specifies the variable `SDK_FORMATS` providing a space-separated list of 
SDK formats to generate.

Supported formats are:
 - `tar-xz`: (default) is the non-containerized format that results from 
   following the instructions in 
   "[Create an ISAR SDK root filesystem](#create-an-isar-sdk-root-filesystem)"
 - `docker-archive`: an archive containing a Docker image that can be imported 
   with 
   [`docker load`](https://docs.docker.com/engine/reference/commandline/load)
 - `docker-daemon`: resulting container image is made available on the local 
   Docker Daemon
 - `containers-storage`: resulting container image is made available to tools 
   using containers/storage back-end (e.g. Podman, CRIO, buildah,...)
 - `oci-archive`: an archive containing an OCI image, mostly for archiving as 
   seed for any of the above formats

User manually triggers creation of SDK formats for his target platform by 
launching the task `do_populate_sdk` for target image, f.e.
`bitbake -c do_populate_sdk mc:${MACHINE}-${DISTRO}:isar-image-base`.
Packages that should be additionally installed into the SDK can be appended to 
`SDK_PREINSTALL` (external repositories) and `SDK_INSTALL` (self-built).

Following formats don't work if running `bitbake -c do_populate_sdk ...` (to 
generate the containerized SDK) from inside of a container (e.g. using 
`kas-container`): `docker-daemon` and `containers-storage`.
It's technically possible, but requires making host resources (e.g. the Docker 
Daemon socket) accessible in the container.
What can endanger the stability and security of the host.

The resulting SDK formats are archived into 
`tmp/deploy/images/${MACHINE}/sdk-${DISTRO}-${DISTRO_ARCH}-${sdk_format}.tar.xz` 
(being `sdk_format` each one of the formats specified in `SDK_FORMATS`).
The SDK container directory `/isar-apt` contains a copy of isar-apt repo with 
locally prebuilt target debian packages (for <HOST_DISTRO>).
One may get into an SDK container and install required target packages with 
the help of `apt-get install <package_name>:<DISTRO_ARCH>` command.
The directory with the source code to develop on should be mounted on the 
container (with `--volume <host-directory>:<container-directory>`) to be able 
to edit files in the host with an IDE and build in the container.

### Example

 - Make the SDK formats to generate available to the task

For one-shot builds (use `local.conf` otherwise):

```
export BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE SDK_FORMATS"
export SDK_FORMATS="docker-archive"
```

 - Trigger creation of SDK root filesystem

```
bitbake -c do_populate_sdk mc:qemuarm-buster:isar-image-base
```

 - Load the SDK container image into the Docker Daemon

```
docker load -i build/tmp/deploy/images/qemuarm/sdk-isar-image-base-debian-buster-armhf-1.0-r0-docker-archive.tar.xz
```

 - Run a container using the SDK container image (following commands starting 
   with `#~:` are to be run in the container)

```
docker run --rm -ti --volume "$(pwd):/build" sdk-isar-image-base-debian-buster-armhf:1.0-r0
```

 - Check that cross toolchains are installed

```
:~# dpkg -l | grep crossbuild-essential-armhf
ii  crossbuild-essential-armhf           12.3                   all          Informational list of cross-build-essential packages
```

## Creation of local apt repo caching upstream Debian packages

### Motivation

Cache upstream debian packages to reduce time for further downloads and to be able to work offline.

### Solution

 - Signing of local repo (optional)

By default, the local caching repo is not gpg signed. If you want to share it
in a trusted way, you may sign it. To do that, install `gpg` in your build
environment, import the public and private keys (see
https://theprivacyguide.org/tutorials/gpg.html for details), and provide the
path to the public key in `conf/local.conf`, e.g.:

```
BASE_REPO_KEY = "file://<absolute_path_to_your_pub_key_file>"'
```

 - Trigger the download and caching of all required files by doing a warm-up build.

```
bitbake mc:qemuarm-buster:isar-image-base
```

 - Set `ISAR_USE_CACHED_BASE_REPO` in `conf/local.conf`:

```
# Uncomment this to enable use of cached base repository
#ISAR_USE_CACHED_BASE_REPO ?= "1"
#BB_NO_NETWORK ?= "1"
```
 - Remove build artifacts to use only local base-apt, in fact toggling ISAR_USE_CACHED_BASE_REPO should trigger a full rebuild as well. This is just the way to be extra sure that only the download cache is used.

```
sudo rm -rf tmp

```

 - Trigger the generation of your image again (now a local repo will be created out of the download cache from the last run):

```
bitbake mc:qemuarm-buster:isar-image-base
```

## Add foreign packages from other repositories to the generated image

### Motivation

When building embedded systems with Isar, one might want to include packages that are not provided by debian by default. One example is docker-ce.

### Approach/Solution

Add a new sources list entry to fetch the package from, i.e. include a new apt source mirror. Then add the needed apt key for the third party repository. Add the wanted package to the IMAGE_PREINSTALL variable.

### Example

Add docker-ce from arm64:

Create a new layer containing `conf/distro/docker-buster.list` with the following content:

```
deb [arch=arm64] https://download.docker.com/linux/debian	buster	stable
```

Include the layer in your project.

To the local.conf add:

```
IMAGE_PREINSTALL += "docker-ce"
THIRD_PARTY_APT_KEYS_append = " https://download.docker.com/linux/debian/gpg;md5sum=1afae06b34a13c1b3d9cb61a26285a15"
DISTRO_APT_SOURCES_append = " conf/distro/docker-buster.list"
```

And build the corresponding image target:

```
bitbake mc:qemuarm64-buster:isar-image-base
```
## Cache all upstream Debian source packages in local apt

### Motivation

OSS license compliance: Some licenses require to provide the corresponding sources code,
other require copyright attributions that may be best provided via the source code. In
addition, you may want to archive the code locally in order to ensure reproducibility (and
modifiability) in the future.

Currently the local-apt generated has only Debian binary packages. Extend the local-apt
to have Debian source packages as well.

### Solution

 - Trigger download of Debian source packages as part of rootfs postprocess.

With the current base-apt implementation, we already cache all the binary packages that
we download and install onto the target rootfs and buildchroot. This is then used to
generate a local-apt for offline build.

Use rootfs postprocessing to parse through the the list of deb files in ${DEBDIR} and
download the corresponding Debian source file using "apt-get source" command.
This caches the sources of all the Debian packages that are downloaded and installed onto
the target rootfs and buildchroots.

By default, the Debian source caching is not enabled.
To enable it, add the below line to your local.conf file.
```
BASE_REPO_FEATURES = "cache-deb-src"
```
