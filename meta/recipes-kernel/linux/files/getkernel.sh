#!/bin/sh -e

deb_cache="/var/cache/apt/archives"

kernel="$(realpath -q /vmlinu[xz])"
if [ ! -f "${kernel}" ]; then
    kernel="$(realpath -q /boot/vmlinu[xz])"
fi

pkg="$(dpkg -S ${kernel} | cut -d':' -f1)"
if [ -z "${pkg}" ]; then
    echo "No package providing ${kernel} found!"
    exit 1
fi

ver=$(dpkg-query -W -f='${Version}\n' "${pkg}")
arch=$(dpkg-query -W -f='${Architecture}\n' "${pkg}")

deb_path="$(find ${deb_cache} -name "${pkg}_${ver}_${arch}.deb" 2>/dev/null | head -n1)"
if [ ! -f "${deb_path}" ]; then
    echo "Package ${pkg}_${ver}_${arch}.deb not found in ${deb_cache}!"
    exit 1
fi

echo "${deb_path}"
