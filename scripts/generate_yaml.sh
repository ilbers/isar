#!/usr/bin/env bash

# This software is a part of Isar.
# Copyright (c) 2023-2024 ilbers GmbH
# Authors:
#  Uladzimir Bely <ubely@ilbers.de>

#
# Script to generate yaml files for kas configuration
#

set -e

cd "$(dirname "$0")/.."

HEADER="\
# This software is a part of Isar.
# Copyright (C) $(date +%Y) ilbers GmbH

header:
  version: 14"

update_yaml() {
  yaml=${1}

  printf "%-45s | " ${yaml}

  # Use temporary file if old one not exists
  if [ ! -f "${yaml}" ]; then
    echo "Not existed before, saving"
    mv ${yaml}_tmp ${yaml}
    return
  fi

  # Compare "pure" contents, without comments (e.g., copyrights, year)
  old=$(grep -v "^#" ${yaml})
  new=$(grep -v "^#" ${yaml}_tmp)

  if [ "${new}" = "${old}" ]; then
    echo "No real changes, keeping  "
    rm ${yaml}_tmp
  else
    echo "File changed, saving"
    mv ${yaml}_tmp ${yaml}
  fi
}

make_yaml() {
  dir=${1}
  name=${2}
  value=${3}

  yaml="kas/${dir}/${value}.yaml"

  # Generate temporary file
  cat << _EOF_ > ${yaml}_tmp
${HEADER}

${name}: ${value}
_EOF_

  update_yaml ${yaml}
}


# Scan for distro configs, except:
# - "debian-common" used only for including
# - "debian-sid-ports" not used currently

DISTROS=$(find {meta,meta-isar}/conf/distro -iname *.conf -printf "%f\n" \
  | sed -e 's/.conf$//' | grep -v "debian-common\|debian-sid-ports" | sort)

for distro in ${DISTROS}
do
  make_yaml "distro" "distro" "${distro}"
done

# Scan for image recipes, except:
# - "isar-image-installer" having more complex structure

IMAGES=$(find {meta,meta-isar}/recipes-core/images -iname *.bb -printf "%f\n" \
  | sed -e 's/.bb$//' | grep -v "isar-image-installer"| sort)

for image in ${IMAGES}
do
  make_yaml "image" "target" "${image}"
done

# Scan for machine configs, except:
# - "rpi-common" used only for including

MACHINES=$(find meta-isar/conf/machine -iname *.conf -printf "%f\n" \
  | sed -e 's/.conf$//' | grep -v "rpi-common" | sort)

for machine in ${MACHINES}
do
  make_yaml "machine" "machine" "${machine}"
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

  yaml="kas/package/pkg_${pkg}.yaml"

  cat << _EOF_ > ${yaml}_tmp
${HEADER}

local_conf_header:
  package-${pkg}: |
    IMAGE_INSTALL:append = " ${package}"
_EOF_

  update_yaml ${yaml}
done
