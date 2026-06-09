#!/bin/bash -e

deb_cache="/var/cache/apt/archives"

paths="/vmlinu[xz] /boot/vmlinu[xz]"
if [ -n "$1" ]; then
    paths="/$1 /boot/$1 $paths"
fi

# Lookup for the kernel file
for path in ${paths}; do
    kernel="$(realpath -q ${path})"
    if [ -f "${kernel}" ]; then
        break
    fi
done

# Obtain package name for the kernel file
pkg="$(dpkg -S ${kernel} | cut -d':' -f1)"
if [ -z "${pkg}" ]; then
    >&2 echo "No package providing ${kernel} found!"
    exit 1
fi

# Query for deb filename
deb_name=$(dpkg-query -W -f='${Package}_${Version}_${Architecture}.deb\n' ${pkg})

# Take care about special symbols
deb_name="${deb_name//%/%25}"
deb_name="${deb_name//:/%3a}"
deb_name="${deb_name//~/%7e}"

# Search for deb in cache dir
deb_path="$(find ${deb_cache} -name "${deb_name}" 2>/dev/null | head -n1)"
if [ ! -f "${deb_path}" ]; then
    >&2 echo "Package ${deb_name} not found in ${deb_cache}!"
    exit 1
fi

echo "${deb_path}"
