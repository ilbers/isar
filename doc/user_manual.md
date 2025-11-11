# ISAR User Manual

Copyright (C) 2016-2019, ilbers GmbH

## Contents

 - [Introduction](#introduction)
 - [Getting Started](#getting-started)
 - [Terms and Definitions](#terms-and-definitions)
 - [How Isar Works](#how-isar-works)
 - [General Isar Configuration](#general-isar-configuration)
 - [Isar Distro Configuration](#isar-distro-configuration)
 - [Custom Package Generation](#custom-package-generation-1)
 - [Image Type Selection](#image-type-selection)
 - [Add a New Distro](#add-a-new-distro)
 - [Add a New Machine](#add-a-new-machine)
 - [Add a New Image](#add-a-new-image)
 - [Add a New Image Type](#add-a-new-image-type)
 - [Customize and configure image](#customize-and-configure-image)
 - [Create a Custom Image Recipe](#create-a-custom-image-recipe)
 - [Add a Custom Application](#add-a-custom-application)
 - [Build statistics collection](#build-statistics-collection)
 - [Isar Cross-compilation](#isar-cross-compilation)
 - [Examining and debugging package generation inside their schroot rootfs](#examining-and-debugging-package-generation-inside-their-schroot-rootfs)
 - [Using ccache for custom packages](#using-ccache-for-custom-packages)
 - [Using sstate-cache](#using-sstate-cache)
 - [Create an ISAR SDK root filesystem](#create-an-isar-sdk-root-filesystem)
 - [Create a containerized Isar SDK root filesystem](#create-a-containerized-isar-sdk-root-filesystem)
 - [Creation of local apt repo caching upstream Debian packages](#creation-of-local-apt-repo-caching-upstream-debian-packages)
 - [Add foreign packages from other repositories to the generated image](#add-foreign-packages-from-other-repositories-to-the-generated-image)
 - [Cache all upstream Debian source packages in local apt](#cache-all-upstream-debian-source-packages-in-local-apt)
 - [Use a custom sbuild chroot to speedup build](#use-a-custom-sbuild-chroot-to-speedup-build)


## Introduction

Isar is a set of scripts for building software packages and repeatable generation of Debian-based root filesystems with customizations.

Isar provides:

 - Fast target image generation: About 10 minutes to get base system image for one machine.
 - Use any apt package provider, including open-source communities like `Debian`, `Raspbian`, etc. and proprietary ones created manually.
 - Native compilation: Packages are compiled in a `schroot` environment using
   the same toolchain and libraries that will be installed to the target
   filesystem.
 - Cross compilation: Could be enabled, when native compilation from the sources takes a lot of time f.e. for Linux kernel.
 - Product templates that can be quickly re-used for real projects.

---

## Getting Started

For demonstration purposes, Isar provides support for the following
configurations:

 - QEMU ARM with Debian Buster
 - QEMU ARM64 with Debian Buster (for host >= buster)
 - QEMU i386 with Debian Buster
 - QEMU amd64 with Debian Buster
 - Raspberry Pi various models with Raspberry OS Bullseye
 - Banana Pi BPI-M1
 - LeMaker HiKey
 - Terasic DE0-Nano-SoC

The steps below describe how to build the images provided by default.

### Install Host Tools

The supported host system is >= bullseye for default mmdebstrap provider.

Building `debian-trixie` requires host system >= bookworm.

Install the following packages:
```
apt install \
  binfmt-support \
  bubblewrap \
  bzip2 \
  mmdebstrap \
  arch-test \
  apt-utils \
  dpkg-dev \
  gettext-base \
  git \
  python3 \
  quilt \
  qemu-user-static \
  reprepro \
  sudo \
  unzip \
  xz-utils \
  git-buildpackage \
  pristine-tar \
  sbuild \
  schroot \
  zstd
```

If your host is bullseye or bookworm, also install the following package.
```
apt install python3-distutils
```

**NOTE:** sbuild version (<=0.78.1) packaged in Debian Buster doesn't support
`$apt_keep_downloaded_packages` option which is required in Isar for
populating `${DL_DIR}/deb`. So, host `sbuild` in this case should be manually
upgraded to >=0.81.2 version from Debian Bullseye.

Next, the user who should run Isar needs to be added to `sbuild` group.
```
sudo gpasswd -a <username> sbuild
```

If you want to generate containerized SDKs, also install the following 
packages: `umoci` and `skopeo`.
Umoci is provided by Debian Buster and can be installed with 
`apt install umoci`, Skopeo is provided by Debian Bullseye/Unstable and has to 
be installed either manually downloading the DEB and installing it (no other 
packages required) or with `apt install -t bullseye skopeo` (if 
unstable/bullseye included in `/etc/apt/sources.list[.d]`).

Notes:

* BitBake requires Python 3.6+.
* The python3 package is required for the correct `alternatives` setting.
* If you'd like to run bitbake in a container (chroot, docker, etc.), install
  the above in the container, and also perform `sudo apt-get install
  binfmt-support qemu-user-static` on the host that should run the container.
* If you install `binfmt-support` after `qemu-user-static`, perform `sudo
  apt-get install --reinstall qemu-user-static` to register binary formats
  handled by QEMU (check e.g. `qemu-arm` in `/usr/sbin/update-binfmts
  --display`).

To run images built for QEMU, you also need to install the related package:
```
apt install qemu
```

### Setup Sudo

Isar requires `sudo` rights without password to work with `chroot`. To add them, use the following steps:
```
 # visudo
```
In the editor, allow the current user to run sudo without a password, e.g.:
```
 <user>  ALL=(ALL:ALL) NOPASSWD:ALL
 Defaults env_keep += "ftp_proxy http_proxy https_proxy no_proxy"
```
Replace `<user>` with your username. Use the tab character between the username and parameters.
The second line will make sure your proxy settings will not get lost when using `sudo`. Include it if you are in the unfortunate position to having to deal with that.

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
tmp/deploy/images/qemuarm/isar-image-base-qemuarm-debian-buster.ext4
tmp/deploy/images/qemuarm/isar-image-debug-qemuarm-debian-buster.ext4
```

### Building Target Images for Multiple Configurations

Alternatively, BitBake supports building images for multiple configurations in
a single call. List all configurations in `conf/local.conf`:

```
BBMULTICONFIG = " \
    qemuarm-buster \
    qemuarm64-buster \
    qemui386-buster \
    qemuamd64-buster \
"
```

The following command will produce `isar-image-base` images for all targets:

```
$ bitbake \
    mc:qemuarm-buster:isar-image-base \
    mc:qemuarm64-buster:isar-image-base \
    mc:qemui386-buster:isar-image-base \
    mc:qemuamd64-buster:isar-image-base \
```

Created images are:

```
tmp/deploy/images/qemuarm/isar-image-base-debian-buster-qemuarm.ext4
tmp/deploy/images/qemuarm64/isar-image-base-debian-buster-qemuarm64.ext4
tmp/deploy/images/qemui386/isar-image-base-debian-buster-qemui386.wic
tmp/deploy/images/qemuamd64/isar-image-base-debian-buster-qemuamd64.wic
```

### Generate full disk image

A bootable disk image is generated if `wic` is listed in IMAGE_FSTYPES.
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

Note that the `ovmf` package in Debian Buster contains a pre-compiled firmware, but doesn't seem to be recent
enough to allow images to be testable under `qemu`.

```
# AMD64 image, EFI
qemu-system-x86_64 -m 256M -nographic -bios edk2/Build/OvmfX64/RELEASE_*/FV/OVMF.fd -hda tmp/deploy/images/qemuamd64/isar-image-base-debian-buster-qemuamd64.wic
# i386 image
qemu-system-i386 -m 256M -nographic -hda tmp/deploy/images/qemui386/isar-image-base-debian-buster-qemui386.wic
```

#### Flashing such images to a physical device

wic images can be flashed in multiple ways. The most generic and easy way is probably with [ etcher ](https://etcher.io). That works on many operating systems and is relatively easy to use. On top it can decompress images on the fly, should they be compressed. It also offers some sort of protection, so you do not write to the wrong device and maybe break your machine.

If you have a unix shell there are other ways. Make sure to always double check the target device, those tools might not warn if you choose the wrong target.

`bmaptool` would be the best choice on a Linux/Unix system. It offers skipping of empty space and will flash much faster than `dd`, it also has some protection, so you do not flash over a mounted drive by accident. Unfortunately, it is not yet available on all Linux distributions.
https://github.com/intel/bmap-tools

`dd` is the most generic option, available pretty much everywhere. But here you really need to make sure to not write to the wrong target.

### Generate container image with root filesystem

A runnable container image is generated if IMAGE_FSTYPES variable includes
one of the supported container formats `oci-archive`, `docker-archive`,
`docker-daemon`, or `containers-storage`.
Getting a container image can be the main purpose of an Isar configuration, 
but not only.
A container image created from an Isar configuration meant for bare-metal or 
virtual machines can be helpful to test certain applications which
requirements (e.g. libraries) can be easily resolved in a containerized 
environment.

Container images can be generated in different formats. One or more (whitespace
separated) of following options can be given:
 - `docker-archive`: an archive containing a Docker image that can
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

### Example

 - Make the relevant environment variables available to the task

For one-shot builds (use `local.conf` otherwise):

```
export BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE IMAGE_FSTYPES"
export IMAGE_FSTYPES="docker-archive.xz"
```

 - Trigger creation of container image from root filesystem

```
bitbake mc:qemuarm-buster:isar-image-base
```

 - Load the container image into the Docker Daemon

```
docker load -i build/tmp/deploy/images/qemuarm/isar-image-base-debian-buster-armhf-1.0-r0.docker-archive.xz
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

### Schroot

Schroot allows the user to run a command in a chroot environment specified by
root directory or previously opened session.

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
 
### Generation of Schroot Filesystem

This filesystem is used as a build environment to compile custom packages. It is generated using `apt` binaries repository, selected by the user in configuration file. Please refer to distro configuration chapter for more information.

### Custom Package Generation

During this stage Isar processes custom packages selected by the user and generates binary `*.deb` packages for the target. Please refer to custom packages generation section for more information.

### Generation of Basic Target Filesystem

This filesystem is generated similarly to the `schroot` one using the `apt`
binaries repository. Please refer to distro configuration chapter for more
information.

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

 - `DISTRO` - The distro to use (e.g. `raspios-bullseye`, `debian-bookworm`).
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
 - `BB_NUMBER_THREADS` - The number of `bitbake` jobs that can be run in parallel. Please set this option according to your host CPU cores number.
 - `SOURCE_DATE_EPOCH_FALLBACK` - The unix timestamp passed to all tooling to make the results reproducible. This variable is optional.
 - `HOST_DISTRO` - The distro to use for SDK root filesystem. This variable is optional.
 - `HOST_ARCH` - The Debian architecture of SDK root filesystem (e.g., `amd64`). By default set to current Debian host architecture. This variable is optional.
 - `HOST_DISTRO_APT_SOURCES` - List of apt source files for SDK root filesystem. This variable is optional.
 - `HOST_DISTRO_APT_PREFERENCES` - List of apt preference files for SDK root filesystem. This variable is optional.
 - `HOST_DISTRO_BOOTSTRAP_KEYS` - Analogously to DISTRO_BOOTSTRAP_KEYS: List of gpg key URIs used to verify apt bootstrap repo for the host.
 - `DISTRO_APT_PREMIRRORS` - The preferred mirror (append it to the default URI in the format `ftp.debian.org my.preferred.mirror`. This variable is optional. PREMIRRORS will be used only for the build. The final images will have the sources list as mentioned in DISTRO_APT_SOURCES.
 - `ISAR_USE_APT_SNAPSHOT` - Use a frozen apt snapshot instead of the live mirror. Optional.
 - `ISAR_APT_DL_LIMIT` - Rate limit the apt fetching to n kB / s. Optional.
 - `ISAR_APT_RETRIES` - Number of apt fetching retries before giving up. Optional
 - `ISAR_APT_DELAY_MAX` - Maximum time in seconds apt performs retries. Optional
 - `DISTRO_APT_SNAPSHOT_PREMIRROR` - Similar to `DISTRO_APT_PREMIRRORS` but for a snapshot, pre-defined for supported distros.
 - `ISAR_APT_SNAPSHOT_TIMESTAMP` - Unix timestamp of the apt snapshot. Automatically derived from `SOURCE_DATE_EPOCH` if not overwritten. (Consider `ISAR_APT_SNAPSHOT_DATE` for a more user friendly format)
 - `ISAR_APT_SNAPSHOT_TIMESTAMP[security]` - Unix timestamp of the security distribution. Optional.
 - `ISAR_APT_SNAPSHOT_DATE` - Timestamp in upstream format (e.g. `20240702T082400Z`) of the apt snapshot. Overrides `ISAR_APT_SNAPSHOT_TIMESTAMP` if set. Otherwise, will be automatically derived from `ISAR_APT_SNAPSHOT_TIMESTAMP`
 - `ISAR_APT_SNAPSHOT_DATE[security]` - Timestamp in upstream format of the security distribution. Optional.
 * `ISAR_APT_CREDS` - List of of remote apt servers requiring credentials (individually configured with `ISAR_APT_CREDS_server_fqdn = "user password")`
 - `THIRD_PARTY_APT_KEYS` - List of gpg key URIs used to verify apt repos for apt installation after bootstrapping.
 - `FILESEXTRAPATHS` - The default directories BitBake uses when it processes recipes are initially defined by the FILESPATH variable. You can extend FILESPATH variable by using FILESEXTRAPATHS.
 - `FILESOVERRIDES` - A subset of OVERRIDES used by the build system for creating FILESPATH. The FILESOVERRIDES variable uses overrides to automatically extend the FILESPATH variable.
 - `IMAGER_INSTALL` -  The list of package dependencies for an imager like wic.

---

## Isar Distro Configuration

In Isar, each machine can use its specific Linux distro to generate `schroot`
and target filesystem. By default, Isar provides configuration files for the
following distros:

 - debian-buster
 - debian-bullseye
 - debian-bookworm
 - debian-trixie (host >= bookworm)
 - ubuntu-focal
 - ubuntu-jammy (requires host dpkg >= 1.21)
 - ubuntu-noble (requires host dpkg >= 1.21)
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

 - `tar` - tarball of the root file system
 - `cpio` - cpio archive
 - `ext4` - raw ext4 filesystem image (default option for `qemuarm` machine)
 - `wic` - full disk image with user-specified partitions created and populated using the wic tool
 - `ubi` - image for use on mtd nand partitions employing UBI
 - `ubifs` - raw UBI filesystem image, normally used together with UBI partitions
 - `ova` - Open Virtual Appliance: image for use on VirtualBox or VMware
 - `squashfs` - raw squashfs filesystem image
 - `fit` - FIT image as used by U-Boot
 - `oci-archive`, `docker-archive`, `docker-daemon`, `containers-storage` - see [generating container images](#generate-container-image-with-root-filesystem)

In addition, image types can be converted using suffixes, e.g. `tar.gz`.
Available conversions are `gz` and `xz`, which both provide image compression.

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

If the distribution has apt sources requiring authentication, users may add the following to e.g. `local.conf`:

    ```
    ISAR_APT_CREDS += "apt.restricted-server.com"
    ISAR_APT_CREDS_apt.restricted-server.com = "my-user-name my-password-or-token"
    ```

Consider passing these credentials via (CI-protected) environment variables and refrain from leaving your credentials in `local.conf`.

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
    debian-bullseye
    debian-bookworm
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
 - `INITRD_IMAGE` - The name of `initramfs` recipe to be built and used by the imager.
 - `MACHINE_SERIAL` - The name of serial device that will be used for console output.
 - `IMAGE_FSTYPES` - The types of images to be generated for this machine.

Below is an example of machine configuration file for `Raspberry Pi` board:
```
IMAGE_PREINSTALL = "linux-image-rpi-rpfv \
                    raspberrypi-bootloader-nokernel"
KERNEL_IMAGE = "vmlinuz-4.4.0-1-rpi"
MACHINE_SERIAL = "ttyAMA0"
IMAGE_FSTYPES = "wic"
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

### Kernel Support

A machine can be configured to select a specific kernel recipe by setting the `KERNEL_NAME` variable, and may be configured to support multiple kernels by using the `KERNEL_NAMES` variable in addition. The latter is optional, and also enables generating packages like external kernel modules for all specified kernel variants.

For example, in your machine configuration:

```bitbake
KERNEL_NAME = "armmp"
KERNEL_NAMES = "armmp mainline"
```

When `KERNEL_NAMES` is set, recipes inheriting the `per-kernel` class will generate variants for each listed kernel. Installation of each must be explicitly handled in the image.

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

The following steps are required to implement a custom image type:

Create a new class:
```
$ vim meta-user/classes/my-image.bbclass
```

Specify the command to generate the new image, and optionally image type
dependencies or required arguments:
```
IMAGE_TYPEDEP:my_image = "ext4"
IMAGE_CMD_REQUIRED_ARGS:my_image = "MY_ARG"
IMAGE_CMD_my_image() {
    INPUT="${PP_DEPLOY}/${IMAGE_FULLNAME}.ext4"
    ${SUDO_CHROOT} my_command ${MY_ARG} -i ${INPUT} -o ${IMAGE_FILE_CHROOT}
}
```
The IMAGE_CMD is a shell function, and the environment has some pre-set
variables:

 - `IMAGE_FILE_HOST` and `IMAGE_FILE_CHROOT` are the paths of the output image
   (including extension) in the host or schroot rootfs.
 - `SUDO_CHROOT` is a prefix you can use to have a command run inside the
   imager schroot rootfs.

If the code you provide in `IMAGE_CMD` requires the building and/or installation
of additional packages in the imager schroot rootfs, you can specify this:
```
IMAGER_BULID_DEPS:my_image = "my_command"
IMAGER_INSTALL:my_image = "my_command"
```

To use your custom image class, add it to `IMAGE_CLASSES` in your machine config:
```
IMAGE_CLASSES += "my-image"
```

And finally select the new image type:
```
IMAGE_FSTYPES = "my-image"
```

### Reference Classes

Isar contains additional image type classes that can be used as reference:

 - `ext4`
 - `tar.gz`
 - `ubifs`
 - `ubi`
 - `wic`

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

The `USERS` and `USER:<username>` variable works similar to the `GROUPS` and `GROUP:<groupname>` variable. The difference are the accepted flags of the `USER:<username>` variable. It accepts the following flags:

 - `password` - The clear-text or crypt(3) encrypted password. In case of clear-text password, the `clear-text-password` flag must be set. To encrypt a password use for example `mkpasswd` or `openssl passwd -6`. You can find `mkpasswd` in the `whois` package of Debian.
 - `expire` - A `YYYY-MM-DD` formatted date on which the user account will be disabled. (see useradd(8))
 - `inactive` - The number of days after a password expires until the account is permanently disabled. (see useradd(8))
 - `uid` - The numeric user id.
 - `gid` -  The numeric group id or group name of this users initial login group.
 - `comment` - This users comment field. Commonly the following format `full name,room number,work phone number,home phone number,other entry`.
 - `home` - This changes the default home directory of the user with `usermod --move-home`. Only takes effect when used together with the `create-home` flag.
 - `shell` - This users login shell
 - `groups` - A space separated list of groups this user is a member of.
 - `flags` - A list of additional flags of the user:
   - `no-create-home` - `useradd` will be called with `-M` to prevent creation of the users home directory.
   - `create-home` - `useradd` will be called with `-m` to force creation of the users home directory.
   - `system` - `useradd` will be called with `--system`.
   - `allow-empty-password` - Even if the `password` flag is empty, it will still be set. This results in a login without password.
   - `clear-text-password` - The `password` flag of the given user contains a clear-text password and not an encrypted version of it.
   - `force-passwd-change` - Force the user to change to password on first login.

#### Example

```
GROUPS += "root"
GROUP_root[gid] = "0"
GROUP_root[flags] = "system"

USERS += "root"
USER_root[password] = "$6$rounds=10000$RXeWrnFmkY$DtuS/OmsAS2cCEDo0BF5qQsizIrq6jPgXnwv3PHqREJeKd1sXdHX/ayQtuQWVDHe0KIO0/sVH8dvQm1KthF0d/"
USER_root[expire] = "180"
USER_root[inactive] = "30"
USER_root[uid] = "0"
USER_root[gid] = "0"
USER_root[comment] = "The ultimate root user"
USER_root[shell] = "/bin/sh"
USER_root[groups] = "audio video"
USER_root[flags] = "create-home system force-passwd-change"
```

Some examples can be also found in `meta-isar/conf/local.conf.sample`.

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

If the resulting image should not ship apt sources used during the build but custom ones (e.g. for end-users to point
to an external or simply different server when they "apt-get update", custom list files may be listed in `SRC_URI`:
Isar will copy them to `/etc/apt/sources.list.d/` and omit bootstrap sources. Possible use-cases:

 * image built from base-apt (which is by definition local to the build host)

 * image built from an internal mirror, not reachable by devices running the produced image

 * ship template list files for the end-user to edit (e.g. letting him uncomment `deb` or `deb-src` entries)

It should be noted that Isar will not validate or even load supplied list files: they are simply copied verbatim to
the root file-system just before creating an image out of it (loading sources from the network would make the build
non-reproducible).

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

The `deb` packages are built using `sbuild`, so the sources should contain the
`debian` directory with necessary meta information. This way is the default
way of adding software that needs to be compiled from source. The bbclass for
this approach is called `dpkg`.

For large applications that are not cross-compiled, it may be needed to extend the default build timeout of 150 minutes to a greater value: set `DPKG_BUILD_TIMEOUT` in your recipe to that effect.

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

Isar does actually contain a helper that aims to "debianize" sources for you. If your package uses a build-system that Debian knows and follows the well known "configure", "compile", "install" scheme that debianization might just fit your needs without reading Debian manuals.
If it does not fully fit your needs, it probably gives you a good starting point for your manual tuning.

The shell function `deb_debianize` creates a `debian` folder. But it will not overwrite files that already are in WORKDIR. So you can either just call it to fully generate the `debian` folder. Or you combine it with pre-existing parts.

Have a look at meta-isar/recipes-app/samefile/samefile_2.14.bb and meta/classes/debianize.bbclass for an example and the implementation.

Here ISAR's debianize class generates/adds the following files under debian directory:

 - Create control file if sources does not contain a control file
 - Create rules file if sources does not contain a rules file
 - Add the copyright if unpacked sources does not contain copyright file, as well as the recipe should supply the copyright file
 - Add the changelog and hooks( pre/post/inst/rm ) into the debian directories if WORKDIR contains the files


### Packages without source

If your customization is not about compiling from source there is a second way of creating `deb` packages. That way can be used for cases like:

 - packaging binaries/files that where built outside of Isar
 - customization of the rootfs with package-hooks
 - pulling in dependencies (meta-packages)

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

Other (optional) customization variables include:
 - `DEBIAN_PROVIDES` - declare a virtual package to satisfy dependencies
 - `DEBIAN_REPLACES` - to replace a package with another
 - `DEBIAN_BREAKS` - Packages which break other packages
 - `DEBIAN_BUILT_USING` - Used when a binary package includes parts of other source packages, f.e: by statically linking their libraries or embedding their
    code or data during the build.
    E.x: Built-Using: <name> (= <version>)
 - `DEBIAN_SECTION` - Specifies the category under which the package is classified

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
<path-to-isar>/scripts/pybootchartgui/pybootchartgui.py tmp/buildstats/20210911054429/ -f pdf -o ~/buildstats.pdf
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

Debian cross-compilation works out of the box. Currently the following build configurations are supported in Isar:

 - buster armhf
 - buster arm64 (for host >= buster)
 - buster mipsel (for host >= buster)
 - bullseye armhf
 - bullseye arm64
 - bullseye mipsel
 - bookworm armhf
 - bookworm arm64
 - bookworm mipsel
 - trixie armhf
 - trixie arm64

Experimental support for riscv64 is available as well.

### Building for a compat and/or native architecture

Some architectures, under Isar amd64 and arm64 so far, support running 32-bit
legacy applications on 64-bit kernels. Debian supports this via the multiarch
concept.

Isar can build 32-bit packages as part of a 64-bit image build and also enable
the image with the necessary packages. To activate compat support,
set `ISAR_ENABLE_COMPAT_ARCH = "1"` in `local.conf`. This will install necessary
build dependencies in the schroot rootfs.

For all dpkg package recipes, Isar automatically provides a `<package>-compat`
target that builds the package for the `COMPAT_DISTRO_ARCH`. This can be
referenced using the `DEPENDS` and `IMAGE_INSTALL` variables.

To explicitly build a package for the build host architecture (in cross build
scenarios, or when generating an SDK), Isar automatically provides a
`<package>-native` target for all dpkg package recipes.

### Using the Debian Secure Boot chain

In case no modification of the bootloader or kernel is required, you can use the
`qemuamd64-sb-bullseye` machine to create an image that can be bootet on amd64 machines
where Secure Boot (SB) with the MS keys is enabled. This works, because it implements
the Debian SB boot chain (shim -> debian grub -> debian kernel). However, none of these
components must be modified, as this would break the signatures and by that cannot be
bootet anymore.

Please note, that this workflow is just intended for prototyping. It also does not
cover SB with self-signed bootloaders or kernels. Do NOT use it for productive images, as
the key handling needs to be implemented differently (e.g. the private key needs to be
stored in a TPM).

The example consists of two parts:

- create an image using the debian SB boot chain for MOK deployment
- create and sign a custom kernel module

**Build the key deployment image:**

```bash
bitbake mc:qemuamd64-sb-bullseye:isar-image-base
```

**Start the image:** (consider adding `-enable-kvm` to get some decent performance):

```bash
start_vm -a amd64-sb -d bullseye -s
```

**Check if SB is actually enabled (detected):**

```bash
dmesg | grep -i secure
# prints something like UEFI Secureboot is enabled
```

**Try to load the example-module (it should fail):**

```bash
modprobe example-module
# this should fail as it is signed with a non trusted key
```

**Enroll our MOK and reboot into the MOK manager:**

```bash
mokutil --import /etc/sb-mok-keys/MOK/MOK.der
```

Use the previously defined password to enroll the key, then reboot.

If EFI variable access is disabled on kernel (due to high latencies under RT kernel),
enrolling will result in failure `EFI variables are not supported on this system`.
EFI variable access can be enabled by passing `efi=runtime` kernel parameter.

Similarly, in cases where EFI variables are not supported, the system will not be able
to import the keys defined on the platform in the kernel platform keyring. This will also
result in kernel modules not being verified if they are signed with one of these platform keys.

**Boot self-signed image**:

Now the image should be up again and `modprobe example-module` should work.

**Sign kernel modules with custom signer hooks**

The kernel module signing process establishes a chain of trust from the kernel to the modules, ensuring that
all components of the system are from trusted sources. If Secure Boot is enabled or the module signing
facility is enabled by kernel configuration or via `module.sig_enforce` kernel parameter, the kernel checks
the signature of the modules against the public keys from kernel system keyring and kernel platform keyring.

Please note that if the certificates you use to sign modules are not included in one of these keyrings or are
blacklisted, the signature will be rejected and the module will not be loaded by the kernel.

Many regulatory standards and compliance frameworks require the use of signing methods that are
designed to protect cryptographic keys and signing operations to ensure a high level of security.

In order to use solutions like Hardware Security Module (HSM) or server-side signing, which
are usually made available via a client, an API endpoint or a plug-in, for signing kernel modules,
Isar provides a build profile called `pkg.signwith` for kernel module recipes.

To provide a signer script that implements your custom signing solution, `SIGNATURE_SIGNWITH` variable
can be set for the script path within the module recipe together with `SIGNATURE_CERTFILE` to define the public
certificate path of the signer.

In order to choose between different signing solutions, signer recipes should provide the `module-signer`
target and package while certificate provider recipes should provide the `secure-boot-secrets` as target and package
to meet build dependencies. This way, desired signers and certificates can be configured using `PREFERRED_PROVIDER`.

Please see how `module-signer-example` hook generates a detached signature for the kernel module implemented in
`example-module-signedwith` recipe.

You can enable build-wide kernel module signing by defining `KERNEL_MODULE_SIGNATURES = "1"` globally,
in this case, `pkg.signwith` build profile is added by default in addition to
`module-signer` and `secure-boot-secrets` target and package dependencies to the kernel module recipes.

### Cross Support for Imagers

If `ISAR_CROSS_COMPILE = "1"`, the imager and optional compression tasks
run in the host schroot rootfs instead of the target one.
This gives a significant speedup when compressing the generated image,
as the compression is not emulated.

In case your setup does not support cross-imaging, you can disable this
just for the particular image by adding `ISAR_CROSS_COMPILE = "0"` to your
image recipe.

## Examining and debugging package generation inside their schroot rootfs

Just like OpenEmbedded, Isar supports a devshell target for all dpkg package
recipes. This target opens a terminal inside the schroot rootfs that runs the
package build. To invoke it, just call
`bitbake mc:${MACHINE}-${DISTRO}:<package_name> -c devshell`.

To debug build dependency issues, there is also the devshell_nodeps target. It
skips any failing dependency installation, allowing to run them manually in the
schroot.


## Using ccache for custom packages

While base system is created from binary Debian repositories, some user
packages are built from sources. It's possible to reduce build time
for such packages by enabling ccache.

To enable global ccache functionality, `USE_CCACHE = "1"` can be added
to `local.conf`. If some package requires ccache to be always disabled,
`USE_CCACHE = "0"` can be used in the recipe despite global setup.

By default, ccache directory is created inside `TMPDIR`, but it can be
adjusted by `CCACHE_TOP_DIR` variable in `local.conf`. Ccache directory
`CCACHE_DIR` default value is
`"${CCACHE_TOP_DIR}/${DISTRO}-${DISTRO_ARCH}-${BUILD_ARCH}"`, that means
caches for different distros and architectures are not overlapped.

The ccache debug mode can be enabled by setting `CCACHE_DEBUG = "1"`
in the `local.conf`.
The debug artifacts will be placed in `${CCACHE_DIR}/debug`.


## Using sstate-cache

Isar supports caching of bitbake task artifacts using the sstate-cache
feature known from OpenEmbedded. Isar caches

  * the Debian bootstrap (`isar-mmdebstrap` recipe)
  * Debian packages (built with the `dpkg` or `dpkg-raw` classes)
  * root file systems (schroot and image rootfs)

The location of the sstate-cache is controlled by the variable `SSTATE_DIR`
and defaults to `${TMPDIR}/sstate-cache`.

Note that cached rootfs artifacts (bootstrap and schroot rootfs) have a limited
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
SDK providing cross build environment will help to solve this problem.

### Approach

Create SDK root file system for host with installed cross-toolchain for target architecture and ability to install already prebuilt
target binary artifacts. Developer chroots to sdk rootfs and develops applications for target platform.

### Solution

User manually triggers creation of SDK root filesystem for his target platform by launching the task `do_populate_sdk` for target image, f.e.
`bitbake -c do_populate_sdk mc:${MACHINE}-${DISTRO}:isar-image-base`.
Packages that should be additionally installed into the SDK can be appended to `SDK_PREINSTALL` (external repositories) and `SDK_INSTALL` (self-built).

The resulting SDK rootfs is archived into `tmp/deploy/images/${MACHINE}/${IMAGE_FULLNAME}.tar.xz`.
Once you untar the compressed file, the content will be extracted into the ${IMAGE_FULLNAME} sub folder.
The SDK rootfs directory `/isar-apt` contains a copy of isar-apt repo with locally prebuilt target debian packages (for <HOST_DISTRO>).
One may chroot into the SDK and install required target packages with the help of `apt-get install <package_name>:<DISTRO_ARCH>` command.

### Example

 - Enable isar-apt include in `conf/local.conf`:

```
SDK_INCLUDE_ISAR_APT = "1"
```

 - Set ISAR_CROSS_COMPILE by 1 for foreign architectures

```
ISAR_CROSS_COMPILE = "1"
```

 - Trigger creation of SDK root filesystem

```
bitbake -c do_populate_sdk mc:qemuarm-bullseye:isar-image-base
```

 - Unpack generated SDK:

```
sudo tar xf tmp/deploy/images/qemuarm/isar-image-base-sdk-debian-bullseye-qemuarm.tar.xz -C tmp/deploy/images/qemuarm
```

 - Mount the following directories in chroot by passing resulting rootfs as an argument to the script `mount_chroot.sh`:

```
cat <path-to-isar>/scripts/mount_chroot.sh
#!/bin/sh

set -e

mount /tmp     $1/tmp                 -o bind
mount proc     $1/proc    -t proc     -o nosuid,noexec,nodev
mount sysfs    $1/sys     -t sysfs    -o nosuid,noexec,nodev
mount devtmpfs $1/dev     -t devtmpfs -o mode=0755,nosuid
mount devpts   $1/dev/pts -t devpts   -o gid=5,mode=620
mount tmpfs    $1/dev/shm -t tmpfs    -o rw,seclabel,nosuid,nodev

sudo <path-to-isar>/scripts/mount_chroot.sh tmp/deploy/images/qemuarm/isar-image-base-sdk-debian-bullseye-qemuarm

```

 - chroot to isar SDK rootfs:

```
sudo chroot tmp/deploy/images/qemuarm/isar-image-base-sdk-debian-bullseye-qemuarm
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

Note that you may need to copy `/etc/resolv.conf` from the host or use any
public nameserver like:

```
:~# echo "nameserver 8.8.8.8" > /etc/resolv.conf
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

 - Unmount rootfs paths:

```
sudo <path-to-isar>/scripts/umount_chroot.sh tmp/deploy/images/qemuarm/isar-image-base-sdk-debian-bullseye-qemuarm
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
`tmp/deploy/images/${MACHINE}/isar-image-base-sdk-${DISTRO}-${DISTRO_ARCH}-${sdk_format}.tar.xz`
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
export BB_ENV_PASSTHROUGH_ADDITIONS="$BB_ENV_EXTRAWHITE SDK_FORMATS"
export SDK_FORMATS="docker-archive"
```

 - Trigger creation of SDK root filesystem

```
bitbake -c do_populate_sdk mc:qemuarm-bullseye:isar-image-base
```

 - Load the SDK container image into the Docker Daemon

```
docker load -i build/tmp/deploy/images/qemuarm/isar-image-base-sdk-debian-bullseye-armhf-1.0-r0-docker-archive.tar.xz
```

 - Run a container using the SDK container image (following commands starting 
   with `#~:` are to be run in the container)

```
docker run --rm -ti --volume "$(pwd):/build" isar-image-base-sdk-debian-bullseye-armhf:1.0-r0
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
THIRD_PARTY_APT_KEYS:append = " https://download.docker.com/linux/debian/gpg;md5sum=1afae06b34a13c1b3d9cb61a26285a15"
DISTRO_APT_SOURCES:append = " conf/distro/docker-buster.list"
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

With the current base-apt implementation, we already cache all the binary
packages that we download and install onto the target rootfs and schroot
rootfs. This is then used to generate a local-apt for offline build.

Use rootfs postprocessing to parse through the list of deb files in ${DEBDIR}
and download the corresponding Debian source file using "apt-get source"
command. This caches the sources of all the Debian packages that are downloaded
and installed onto the target rootfs and schroot rootfs.

By default, the Debian source caching is not enabled.
To enable it, add the below line to your local.conf file.
```
BASE_REPO_FEATURES = "cache-deb-src"
```

## Use a custom sbuild chroot to speedup build

### Motivation

There are use-cases, where many packages need to be compiled but all of them
need a similar base of build dependencies. In case the baseline is quite big,
this adds a significant overhead as the build dependencies are installed individually
for each and every package.

### Solution

By creating a dedicated sbuild chroot for this use-case, the baseline can be installed
first and then all package builds of this type can use it. For that, create a
new recipe with the name `sbuild-chroot-<host|target>-<flavor>`. In that recipe,
define the following:

```
require recipes-devtools/sbuild-chroot/sbuild-chroot-<host|target>.bb

SBUILD_FLAVOR = "<your flavor, e.g. clang>"
SBUILD_CHROOT_PREINSTALL_EXTRA += "<base packages>"
```

Then, in the dpkg recipe of your package, simply set `SBUILD_FLAVOR = "<your flavor>"`.
To install additional packages into the sbuild chroot, add them to `SBUILD_CHROOT_PREINSTALL_EXTRA`.

## Pre-install container images

If an isar-generated image shall provide a container runtime, it may also be
desirable to pre-install container images to avoid having to download them on
first boot or because they may not be accessible outside of the build
environment. Isar supports this scenario via two services, a container fetcher
and a container loader.

### Bitbake fetcher for containers

The bitbake fetching protocol "docker://" allows to download pre-built images
from container registries. The URL consists of the image path, followed by
a recommended digest in the form `digest=sha256:<sha256sum>` and an optional
tag in the form `tag=<tag>`. A digest is preferred over a tag to identify an
image when fetching because it also allows to validate its integrity. If a tag
is not specified, `latest` is used as tag name.

In case a multi-arch image is specified, the fetcher will only pull for the
package architecture of the requesting recipe (`PACKAGE_ARCH`). The fetched
images are stored as zstd-compressed in docker-archive format in the
`WORKDIR` of the recipe. The name of the image is derived from the container
image name, replacing all `/` with `.` and appending `:<tag>.zst`. Example:
`docker://debian;tag=bookworm` will be saved as `debian:bookworm.zst`.

### Container loader helpers

To create a Debian package which can carry container images and load them into
local storage of docker or podman, there is a set of helpers available. To use
them in an own recipe, add
`require recipes-support/container-loader/docker-loader.inc` when using docker
and `require recipes-support/container-loader/podman-loader.inc` when using
podman. The loader will try to transfer the packaged image into the container
runtime storage on boot, but only if no container image of the same name and
tag is present already.

Unless `CONTAINER_DELETE_AFTER_LOAD` is set to `1`, the source container images
remain by default available and may be used again for loading the storage after
it may have been emptied later on (factory reset).

Source container images may either be fetched as binaries from a registry, see
above, or built via isar as well.

### Example

This creates a debian package which will download, package and then load the
`debian:bookworm-20240701-slim` container image into the docker container
storage. The package will depend on `docker.io`, insuring that that basic
runtime services are installed on the target as well. The packaged image will
be deleted from the target device's rootfs after successful import.

```
require recipes-support/container-loader/docker-loader.inc

CONTAINER_DELETE_AFTER_LOAD = "1"

SRC_URI += "docker://debian;digest=sha256:f528891ab1aa484bf7233dbcc84f3c806c3e427571d75510a9d74bb5ec535b33;tag=bookworm-20240701-slim"
```


## Switch from initramfs-tools to dracut

To build a Isar image with dracut as the initramfs generator instead
of initramfs-tools in Debian 13(trixie) or previous versions add dracut
as a package to the image:

```
IMAGE_PREINSTALL +=  "dracut"
```

An dracut based initrd contains the file `/usr/lib/initrd-release`. In
case of trixie the file has the following content:

```bash
NAME=dracut
ID=dracut
VERSION_ID="106-6"
ANSI_COLOR="0;34"
```


## Customize the initramfs

Isar supports the customization of initramfs images by providing an
infrastructure for quickly creating hooks in case of `initramfs-tools`
or modules for `dracut` by allowing to replace the Debian-generated
image with a separately built one.

### Creating initramfs-tools hooks

To create an initramfs hook that adds tools or modules to the image and may
also run custom scripts during boot, use the include file
`recipes-initramfs/initramfs-hook/hook.inc`. It is controlled via a number of
variables:

 - `HOOK_PREREQ` defines the prerequisites for running the hook script.
 - `HOOK_ADD_MODULES` passes the provided modules names to the
   `manual_add_modules` function during initramfs creation.
 - `HOOK_COPY_EXECS` identifies the source of the passed executables on the
   rootfs that runs mkinitramfs and passes that to `copy_exec`. If an
   executable is not found, an error thrown, and the creation fails.
 - `SCRIPT_PREREQ` defines the prerequisites for running the boot script(s).

If the generated hook script is not sufficient, you can append an own
bottom-half script by providing a `hook` file in `${WORKDIR}`. It will be
appended to the `hook-header` that the helper generates.

For running a custom script during boot-up, provide a bottom-half file in
`${WORKDIR}`. Its name defines where it is hooked up with the initramfs boot
process: `init-top`, `init-premount`, `local-top`, `nfs-top`, `local-block`,
`local-premount`, `nfs-premount`, `local-bottom`, `nfs-bottom`, `init-bottom`.
If you do not benefit from the script header with its static `SCRIPT_PREREQ`,
you may instead provide `init-top-complete`, `init-premount-complete` etc. to
still use automatic installation while defining the boot script completely
yourself.

See https://manpages.debian.org/stable/initramfs-tools-core/initramfs-tools.7.en.html
for further details.

The hook recipe should follow the naming convention `initramfs-<hook-name>-hook`
so that its scripts will then be called `<hook-name>` in the generated
initramfs.

See `initramfs-example` for an exemplary hook recipe.

### Creating dracut modules

To create a custom dracut module that adds tools, kernel-modules or services
to the initrd, use the class `dracut-module`.
It is controlled by following variables:

- `DRACUT_REQUIRED_BINARIES` defines the binaries required by the module.
- `DRACUT_MODULE_DEPENDENCIES` defines dependencies to other dracut modules.
- `DRACUT_MODULE_NO` defines the module number which prefixes the module name
to define the execution order.The default is `50`.
- `DRACUT_MODULE_NAME` the name of the module which is used to install the
module in the initrd or as a dependency to other modules. It defaults to
`${PN}` without the prefix `dracut-`.
- `DRACUT_MODULE_PATH` contains the path to the installed module. It is set
to `${D}/usr/lib/dracut/modules.d/${DRACUT_MODULE_NO}${DRACUT_MODULE_NAME}/`

The `install()` function is added by storing the file `install.sh` in the
files directory of the dracut module.

Other files can by added to the module by coping them to the Module folder
with:
```bash
install -m 666 ${WORKDIR}/lighttpd.service ${DRACUT_MODULE_PATH}
```

See `dracut-example-lighttpd` for an exemplary hook recipe.

### Creating an initramfs image aside the rootfs

To avoid shipping all tools and binaries needed to generate an initramfs, isar
provides the initramfs class. It creates a temporary Debian rootfs with all
those dependencies and generates the initramfs from there, rather than the
target's rootfs.

This initramfs class should be pulled in by an image recipe. Said recipe
specifies all dependencies of the initramfs via `INITRAMFS_INSTALL` for
self-built packages and `INITRAMFS_PREINSTALL` for prebuilt ones, analogously
to the respective `IMAGE_*` variables. Note that the kernel is automatically
added to `INITRAMFS_INSTALL` if `KERNEL_NAME` is set.

See `isar-initramfs` or `isar-dracut` for an example recipes.

#### dracut config

A dracut initramfs can be configured by the command line or a configuration file.
The use configuration files is preferred:
 - Debian provides dracut-config-* packages
 - It is easier to upstream and to maintain.

The configuration file can be chosen with the variable `DRACUT_CONFIG_PATH`. This variable
contains the absolut path to the used configuration in the root file system.

Still there are some use cases like debugging to add modules via the command line.
For this the recipe meta/classes/initrd-dracut.bbclass provides the following options:
 - `DRACUT_EXTRA_DRIVERS` add extra drivers to the dracut initrd
 - `DRACUT_EXTRA_MODULES` add extra modules to the dracut initrd
