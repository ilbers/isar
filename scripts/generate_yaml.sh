#!/usr/bin/env bash

# This software is a part of ISAR.
# Copyright (c) 2023 ilbers GmbH
# Authors:
#  Uladzimir Bely <ubely@ilbers.de>

#
# Script to generate yaml files for kas configuration
#

set -e

cd "$(dirname "$0")/.."

HEADER="\
# This software is a part of ISAR.
# Copyright (C) 2023 ilbers GmbH

header:
  version: 14"

# Scan for distro configs, except "debian-common" used only for including

DISTROS=$(find {meta,meta-isar}/conf/distro -iname *.conf -printf "%f\n" \
  | sed -e 's/.conf$//' | grep -v "debian-common" | sort)

for distro in ${DISTROS}
do
  cat << _EOF_ > kas/distro/${distro}.yaml
${HEADER}

distro: ${distro}
_EOF_
done

# Scan for image recipes

IMAGES=$(find {meta,meta-isar}/recipes-core/images -iname *.bb -printf "%f\n" \
  | sed -e 's/.bb$//' | sort)

for image in ${IMAGES}
do
  cat << _EOF_ > kas/image/${image}.yaml
${HEADER}

target: ${image}
_EOF_
done

# Scan for machine configs, except "rpi-common" used only for including

MACHINES=$(find meta-isar/conf/machine -iname *.conf -printf "%f\n" \
  | sed -e 's/.conf$//' | grep -v "rpi-common" | sort)

for machine in ${MACHINES}
do
  cat << _EOF_ > kas/machine/${machine}.yaml
${HEADER}

machine: ${machine}
_EOF_
done

# Generate configs for fixed list of Isar packages

PKGS=" \
  cowsay \
  enable-fsck \
  example-module \
  example-prebuilt \
  example-raw \
  expand-on-first-boot \
  hello-isar \
  hello \
  isar-disable-apt-cache \
  isar-exclude-docs \
  kselftest \
  samefile \
  sshd-regen-keys \
"
for pkg in ${PKGS}
do
  package=${pkg}

  if [ "${pkg}" == "example-module" ]; then
    package=${pkg}-\$\{KERNEL_NAME\}
  fi

  cat << _EOF_ > kas/package/pkg_${pkg}.yaml
${HEADER}

local_conf_header:
  package-${pkg}: |
    IMAGE_INSTALL:append = " ${package}"
_EOF_
done
