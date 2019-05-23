# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2019

ROOTFS_ARCH ?= "${DISTRO_ARCH}"
ROOTFS_DISTRO ?= "${DISTRO}"
ROOTFS_PACKAGES ?= ""

# Features of the rootfs creation:
# available features are:
# 'deploy-package-cache' - copy the package cache ${WORKDIR}/apt_cache
# 'clean-package-cache' - delete package cache from rootfs
# 'finalize-rootfs' - delete files needed to chroot into the rootfs
ROOTFS_FEATURES ?= ""

ROOTFS_APT_ARGS="install --yes -o Debug::pkgProblemResolver=yes"

ROOTFS_CLEAN_FILES="/etc/hostname /etc/resolv.conf"

# Useful environment variables:
export E = "${@ bb.utils.export_proxies(d)}"
export DEBIAN_FRONTEND = "noninteractive"
# To avoid Perl locale warnings:
export LANG = "C"
export LANGUAGE = "C"
export LC_ALL = "C"

rootfs_do_mounts[weight] = "3"
rootfs_do_mounts() {
    sudo -s <<'EOSUDO'
        mountpoint -q '${ROOTFSDIR}/dev' || \
            mount --rbind /dev '${ROOTFSDIR}/dev'
        mount --make-rslave '${ROOTFSDIR}/dev'
        mountpoint -q '${ROOTFSDIR}/proc' || \
            mount -t proc none '${ROOTFSDIR}/proc'
        mountpoint -q '${ROOTFSDIR}/sys' || \
            mount --rbind /sys '${ROOTFSDIR}/sys'
        mount --make-rslave '${ROOTFSDIR}/sys'

        # Mount isar-apt if the directory does not exist or if it is empty
        # This prevents overwriting something that was copied there
        if [ ! -e '${ROOTFSDIR}/isar-apt' ] || \
           [ "$(find '${ROOTFSDIR}/isar-apt' -maxdepth 1 -mindepth 1 | wc -l)" = "0" ]
        then
            mkdir -p '${ROOTFSDIR}/isar-apt'
            mountpoint -q '${ROOTFSDIR}/isar-apt' || \
                mount --bind '${REPO_ISAR_DIR}/${DISTRO}' '${ROOTFSDIR}/isar-apt'
        fi

        # Mount base-apt if 'ISAR_USE_CACHED_BASE_REPO' is set
        if [ "${@repr(bb.utils.to_boolean(d.getVar('ISAR_USE_CACHED_BASE_REPO')))}" = 'True' ]
        then
            mkdir -p '${ROOTFSDIR}/base-apt'
            mountpoint -q '${ROOTFSDIR}/base-apt' || \
                mount --bind '${REPO_BASE_DIR}' '${ROOTFSDIR}/base-apt'
        fi

EOSUDO
}

rootfs_do_qemu() {
    if [ '${@repr(d.getVar('ROOTFS_ARCH') == d.getVar('HOST_ARCH'))}' = 'False' ]
    then
        test -e '${ROOTFSDIR}/usr/bin/qemu-${QEMU_ARCH}-static' || \
            sudo cp '/usr/bin/qemu-${QEMU_ARCH}-static' '${ROOTFSDIR}/usr/bin/qemu-${QEMU_ARCH}-static'
    fi
}

BOOTSTRAP_SRC = "${DEPLOY_DIR_BOOTSTRAP}/${ROOTFS_DISTRO}-${ROOTFS_ARCH}-${DISTRO_ARCH}"
BOOTSTRAP_SRC_${ROOTFS_ARCH} = "${DEPLOY_DIR_BOOTSTRAP}/${ROOTFS_DISTRO}-${ROOTFS_ARCH}"

rootfs_prepare[weight] = "25"
rootfs_prepare(){
    sudo cp -Trpfx '${BOOTSTRAP_SRC}/' '${ROOTFSDIR}'
}

ROOTFS_CONFIGURE_COMMAND += "rootfs_configure_isar_apt"
rootfs_configure_isar_apt[weight] = "2"
rootfs_configure_isar_apt() {
    sudo -s <<'EOSUDO'

    mkdir -p '${ROOTFSDIR}/etc/apt/sources.list.d'
    echo 'deb [trusted=yes] file:///isar-apt ${DEBDISTRONAME} main' > \
        '${ROOTFSDIR}/etc/apt/sources.list.d/isar-apt.list'

    mkdir -p '${ROOTFSDIR}/etc/apt/preferences.d'
    cat << EOF > '${ROOTFSDIR}/etc/apt/preferences.d/isar'
Package: *
Pin: release n=${DEBDISTRONAME}
Pin-Priority: 1000
EOF
EOSUDO
}

ROOTFS_INSTALL_COMMAND += "rootfs_install_pkgs_update"
rootfs_install_pkgs_update[weight] = "5"
rootfs_install_pkgs_update() {
    sudo -E chroot '${ROOTFSDIR}' /usr/bin/apt-get update \
        -o Dir::Etc::sourcelist="sources.list.d/isar-apt.list" \
        -o Dir::Etc::sourceparts="-" \
        -o APT::Get::List-Cleanup="0"
}

ROOTFS_INSTALL_COMMAND += "rootfs_install_resolvconf"
rootfs_install_resolvconf[weight] = "1"
rootfs_install_resolvconf() {
    sudo cp -rL /etc/resolv.conf '${ROOTFSDIR}/etc'
}

ROOTFS_INSTALL_COMMAND += "rootfs_install_pkgs_download"
rootfs_install_pkgs_download[weight] = "600"
rootfs_install_pkgs_download() {
    sudo -E chroot '${ROOTFSDIR}' \
        /usr/bin/apt-get ${ROOTFS_APT_ARGS} --download-only ${ROOTFS_PACKAGES}
}

ROOTFS_INSTALL_COMMAND_BEFORE_CLEAN ??= ""
ROOTFS_INSTALL_COMMAND += "${ROOTFS_INSTALL_COMMAND_BEFORE_CLEAN}"

ROOTFS_INSTALL_COMMAND += "${@ 'rootfs_install_clean_files' if (d.getVar('ROOTFS_CLEAN_FILES') or '').strip() else ''}"
rootfs_install_clean_files[weight] = "2"
rootfs_install_clean_files() {
    sudo -E chroot '${ROOTFSDIR}' \
        /bin/rm -f ${ROOTFS_CLEAN_FILES}
}

ROOTFS_INSTALL_COMMAND += "rootfs_install_pkgs_install"
rootfs_install_pkgs_install[weight] = "8000"
rootfs_install_pkgs_install() {
    sudo -E chroot "${ROOTFSDIR}" \
        /usr/bin/apt-get ${ROOTFS_APT_ARGS} ${ROOTFS_PACKAGES}
}

do_rootfs_install[root_cleandirs] = "${ROOTFSDIR}"
do_rootfs_install[vardeps] = "${ROOTFS_CONFIGURE_COMMAND} ${ROOTFS_INSTALL_COMMAND}"
do_rootfs_install[depends] = "isar-bootstrap-${@'target' if d.getVar('ROOTFS_ARCH') == d.getVar('DISTRO_ARCH') else 'host'}:do_build isar-apt:do_cache_config"
do_rootfs_install[deptask] = "do_deploy_deb"
python do_rootfs_install() {
    configure_cmds = (d.getVar("ROOTFS_CONFIGURE_COMMAND", True) or "").split()
    install_cmds = (d.getVar("ROOTFS_INSTALL_COMMAND", True) or "").split()

    # Mount after configure commands, so that they have time to copy
    # 'isar-apt' (sdkchroot):
    cmds = ['rootfs_prepare'] + configure_cmds + ['rootfs_do_mounts'] + install_cmds

    stage_weights = [int(d.getVarFlag(i, 'weight', True) or "20")
                     for i in cmds]

    progress_reporter = bb.progress.MultiStageProgressReporter(d, stage_weights)

    for cmd in cmds:
        progress_reporter.next_stage()
        bb.build.exec_func(cmd, d)
    progress_reporter.finish()
}
addtask rootfs_install before do_rootfs_postprocess after do_unpack

ROOTFS_POSTPROCESS_COMMAND += "${@bb.utils.contains('ROOTFS_FEATURES', 'copy-package-cache', 'rootfs_postprocess_copy_package_cache', '', d)}"
rootfs_postprocess_copy_package_cache() {
    mkdir -p '${WORKDIR}/apt_cache'
    sudo find '${ROOTFSDIR}/var/cache/apt/archives' \
        -maxdepth 1 -name '*.deb' -execdir /bin/mv -t '${WORKDIR}/apt_cache' '{}' '+'
    me="$(id -u):$(id -g)"
    sudo chown -R "$me" '${WORKDIR}/apt_cache'
}

ROOTFS_POSTPROCESS_COMMAND += "${@bb.utils.contains('ROOTFS_FEATURES', 'clean-package-cache', 'rootfs_postprocess_clean_package_cache', '', d)}"
rootfs_postprocess_clean_package_cache() {
    sudo -E chroot '${ROOTFSDIR}' \
        /usr/bin/apt-get clean
    sudo rm -rf "${ROOTFSDIR}/var/lib/apt/lists/"*
}

ROOTFS_POSTPROCESS_COMMAND += "${@bb.utils.contains('ROOTFS_FEATURES', 'finalize-rootfs', 'rootfs_postprocess_finalize', '', d)}"
rootfs_postprocess_finalize() {
    sudo -s <<'EOSUDO'
        test -e "${ROOTFSDIR}/chroot-setup.sh" && \
            "${ROOTFSDIR}/chroot-setup.sh" "cleanup" "${ROOTFSDIR}"
        rm -f "${ROOTFSDIR}/chroot-setup.sh"

        test ! -e "${ROOTFSDIR}/usr/share/doc/qemu-user-static" && \
            find "${ROOTFSDIR}/usr/bin" \
                -maxdepth 1 -name 'qemu-*-static' -type f -delete

        mountpoint -q '${ROOTFSDIR}/isar-apt' && \
            umount -l ${ROOTFSDIR}/isar-apt
        rmdir --ignore-fail-on-non-empty ${ROOTFSDIR}/isar-apt

        mountpoint -q '${ROOTFSDIR}/base-apt' && \
            umount -l ${ROOTFSDIR}/base-apt
        rmdir --ignore-fail-on-non-empty ${ROOTFSDIR}/base-apt

        mountpoint -q '${ROOTFSDIR}/dev' && \
            umount -l ${ROOTFSDIR}/dev
        mountpoint -q '${ROOTFSDIR}/sys' && \
            umount -l ${ROOTFSDIR}/proc
        mountpoint -q '${ROOTFSDIR}/sys' && \
            umount -l ${ROOTFSDIR}/sys

        rm -f "${ROOTFSDIR}/etc/apt/apt.conf.d/55isar-fallback.conf"

        rm -f "${ROOTFSDIR}/etc/apt/sources.list.d/isar-apt.list"
        rm -f "${ROOTFSDIR}/etc/apt/sources.list.d/base-apt.list"

        mv "${ROOTFSDIR}/etc/apt/sources-list" \
            "${ROOTFSDIR}/etc/apt/sources.list.d/bootstrap.list"

        rm -f "${ROOTFSDIR}/etc/apt/sources-list"
EOSUDO
}

do_rootfs_postprocess[vardeps] = "${ROOTFS_POSTPROCESS_COMMAND}"
python do_rootfs_postprocess() {
    # Take care that its correctly mounted:
    bb.build.exec_func('rootfs_do_mounts', d)
    # Take care that qemu-*-static is available, since it could have been
    # removed on a previous execution of this task:
    bb.build.exec_func('rootfs_do_qemu', d)

    cmds = d.getVar("ROOTFS_POSTPROCESS_COMMAND")
    if cmds is None or not cmds.strip():
        return
    cmds = cmds.split()
    for cmd in cmds:
        bb.build.exec_func(cmd, d)
}
addtask rootfs_postprocess before do_rootfs

python do_rootfs() {
    """Virtual task"""
    pass
}
addtask rootfs before do_build
