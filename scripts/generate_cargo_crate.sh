#!/bin/bash
# This software is a part of ISAR.
# Copyright (C) 2026 Siemens AG

usage() {
    echo "This script generates a scaffold for rust crates from crates.io."
    echo "It uses debcargo to download and generate the debian folder."
    echo "USAGE: $0 <CRATE_NAME> [CRATE_VERSION]"
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi
case $1 in
    -h|--help)
            usage
            exit 0
            ;;
    *)
        true
        ;;
esac

package_name=$1
package_version=
if [ $# -gt 1 ]; then
    package_version=$2
fi

export NAME="isar-users isar"

for dep in jq debcargo curl; do
    if ! command -v "$dep" ;then
        echo "Could not find tool dependency $dep !"
        exit 1
    fi
done

source_name="rust-$package_name"
mkdir -p "$source_name/files"
# generate in the current directory to avoid the following
# debcargo error:
# Invalid cross-device link (os error 18)
TMP_DIR="$(mktemp -d -p "$(pwd)")"
pushd "$source_name" || exit 1
debcargo package "$package_name" "$package_version" --directory "$TMP_DIR"
cp -r "${TMP_DIR}"/debian files/
if [ -z "$package_version" ]; then
    package_version=$(grep -oP "X-Cargo-Crate-Version:\K.*" "${TMP_DIR}"/debian/control | tr -d "[:blank:]")
fi
tarball_checksum="$(curl --silent "https://crates.io/api/v1/crates/${package_name}/${package_version}" | jq ".version.checksum" )"
if [ "${tarball_checksum}" = "null" ] ; then
    echo "$package_name in $package_version could not be found in crates.io"
    exit 1
fi
cat << EOF > "${source_name}_${package_version}".bb
# Created by generate_cargo_crate.sh.
# SPDX-License-Identifier: MIT-0

inherit dpkg

SRC_URI = "crate://crates.io/${package_name}/\${PV};downloadfilename=\${PN}_\${PV}.tar.gz"
SRC_URI += "file://debian"

BP = "${package_name}-\${PV}"

SRC_URI[${package_name}-${package_version}.sha256sum] = ${tarball_checksum}

S = "\${WORKDIR}/${package_name}-\${PV}"

# In most cases we want to package a library crate from crates.io
PROVIDES += "librust-${package_name}-dev"

do_prepare_build() {
    cp -r \${WORKDIR}/debian \${S}/
    cd \${WORKDIR}
    tar cJf \${PN}_\${PV}.orig.tar.xz \${TAR_REPRO_OPTS} ${package_name}-\${PV}
}
EOF


popd || exit 1
# clean up
find . -iname "$source_name*.orig.tar.*" -exec rm {} \;
 -rf "$TMP_DIR"

echo "Finished generating isar scaffold for package $package_name in version $package_version"
echo ""
echo "Next steps:"
echo "  - Check if the package builds and add the necessary patches, e.g. relax dependencies to the debian folder."
echo "  - Also add the package to Debian by following https://rust-team.pages.debian.net/book/"
