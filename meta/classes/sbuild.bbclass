# This software is a part of ISAR.
# Copyright (C) 2021 ilbers GmbH

SCHROOT_CONF ?= "/etc/schroot"

SCHROOT_MOUNTS ?= ""

python __anonymous() {
    import pwd
    d.setVar('SCHROOT_USER', pwd.getpwuid(os.geteuid()).pw_name)

    mode = d.getVar('ISAR_CROSS_COMPILE', True)
    distro_arch = d.getVar('DISTRO_ARCH')
    if mode == "0" or d.getVar('HOST_ARCH') ==  distro_arch or \
       (d.getVar('HOST_DISTRO') == "debian-stretch" and distro_arch == "i386"):
        d.setVar('SBUILD_HOST_ARCH', distro_arch)
        d.setVar('SCHROOT_DIR', d.getVar('SCHROOT_TARGET_DIR'))
        dep = "sbuild-chroot-target:do_build"
    else:
        d.setVar('SBUILD_HOST_ARCH', d.getVar('HOST_ARCH'))
        d.setVar('SCHROOT_DIR', d.getVar('SCHROOT_HOST_DIR'))
        dep = "sbuild-chroot-host:do_build"
    d.setVar('SCHROOT_DEP', dep)
}

SBUILD_CHROOT ?= "${DEBDISTRONAME}-${SCHROOT_USER}-${@os.getpid()}"

SBUILD_CONF_DIR ?= "${SCHROOT_CONF}/${SBUILD_CHROOT}"
SCHROOT_CONF_FILE ?= "${SCHROOT_CONF}/chroot.d/${SBUILD_CHROOT}"

SBUILD_CONFIG="${WORKDIR}/sbuild.conf"

schroot_create_configs() {
    sudo -s <<'EOSUDO'
        set -e

        cat << EOF > "${SCHROOT_CONF_FILE}"
[${SBUILD_CHROOT}]
type=directory
directory=${SCHROOT_DIR}
profile=${SBUILD_CHROOT}
users=${SCHROOT_USER}
groups=root,sbuild
root-users=${SCHROOT_USER}
root-groups=root,sbuild
source-root-users=${SCHROOT_USER}
source-root-groups=root,sbuild
union-type=overlay
preserve-environment=true
EOF

        # Prepare mount points
        cp -rf "${SCHROOT_CONF}/sbuild" "${SBUILD_CONF_DIR}"
        sbuild_fstab="${SBUILD_CONF_DIR}/fstab"

        fstab_baseapt="${REPO_BASE_DIR} /base-apt none rw,bind 0 0"
        grep -qxF "${fstab_baseapt}" ${sbuild_fstab} || echo "${fstab_baseapt}" >> ${sbuild_fstab}

        fstab_pkgdir="${WORKDIR} /home/builder/${PN} none rw,bind 0 0"
        grep -qxF "${fstab_pkgdir}" ${sbuild_fstab} || echo "${fstab_pkgdir}" >> ${sbuild_fstab}

        if [ -d ${DL_DIR} ]; then
            fstab_downloads="${DL_DIR} /downloads none rw,bind 0 0"
            grep -qxF "${fstab_downloads}" ${sbuild_fstab} || echo "${fstab_downloads}" >> ${sbuild_fstab}
        fi
EOSUDO
}

schroot_delete_configs() {
    sudo -s <<'EOSUDO'
        set -e
        if [ -d "${SBUILD_CONF_DIR}" ]; then
            rm -rf "${SBUILD_CONF_DIR}"
        fi
        rm -f "${SCHROOT_CONF_FILE}"
EOSUDO
}

sbuild_add_env_filter() {
    [ -w ${SBUILD_CONFIG} ] || touch ${SBUILD_CONFIG}

    if ! grep -q "^\$environment_filter =" ${SBUILD_CONFIG}; then
        echo "\$environment_filter = [" >> ${SBUILD_CONFIG}
        echo "];" >> ${SBUILD_CONFIG}
    fi

    FILTER=${1}

    sed -i -e "/'\^${FILTER}\\$/d" \
        -e "/^\$environment_filter =.*/a '^${FILTER}\$'," ${SBUILD_CONFIG}
}

sbuild_export() {
    [ -w ${SBUILD_CONFIG} ] || touch ${SBUILD_CONFIG}

    if ! grep -q "^\$build_environment =" ${SBUILD_CONFIG}; then
        echo "\$build_environment = {" >> ${SBUILD_CONFIG}
        echo "};" >> ${SBUILD_CONFIG}
    fi

    VAR=${1}; shift
    VAR_LINE="'${VAR}' => '${@}',"

    sed -i -e "/^'${VAR}' =>/d" ${SBUILD_CONFIG} \
        -e "/^\$build_environment =.*/a ${VAR_LINE}" ${SBUILD_CONFIG}
}

insert_mounts() {
    sudo -s <<'EOSUDO'
        set -e
        for mp in ${SCHROOT_MOUNTS}; do
            FSTAB_LINE="${mp%%:*} ${mp#*:} none rw,bind 0 0"
            grep -qxF "${FSTAB_LINE}" ${SBUILD_CONF_DIR}/fstab || \
                echo "${FSTAB_LINE}" >> ${SBUILD_CONF_DIR}/fstab
        done
EOSUDO
}

remove_mounts() {
    sudo -s <<'EOSUDO'
        set -e
        for mp in ${SCHROOT_MOUNTS}; do
            FSTAB_LINE="${mp%%:*} ${mp#*:} none rw,bind 0 0"
            sed -i "\|${FSTAB_LINE}|d" ${SBUILD_CONF_DIR}/fstab
        done
EOSUDO
}

schroot_configure_ccache() {
    sudo -s <<'EOSUDO'
        set -e

        sbuild_fstab="${SBUILD_CONF_DIR}/fstab"

        install --group=sbuild --mode=2775 -d ${CCACHE_DIR}
        fstab_ccachedir="${CCACHE_DIR} /ccache none rw,bind 0 0"
        grep -qxF "${fstab_ccachedir}" ${sbuild_fstab} || echo "${fstab_ccachedir}" >> ${sbuild_fstab}

        (flock 9
        [ -w ${CCACHE_DIR}/sbuild-setup ] || cat << END > ${CCACHE_DIR}/sbuild-setup
#!/bin/sh
export PATH="\$PATH_PREPEND:\$PATH"
exec "\$@"
END
        chmod a+rx ${CCACHE_DIR}/sbuild-setup
        ) 9>"${CCACHE_DIR}/sbuild-setup.lock"

        echo "command-prefix=/ccache/sbuild-setup" >> "${SCHROOT_CONF_FILE}"
EOSUDO
}
