# This software is a part of Isar.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT
#
# This class extends the image.bbclass for setting locales and purging unneeded
# ones.

LOCALE_GEN ?= "en_US.UTF-8 UTF-8\n\
               en_US ISO-8859-1\n"
LOCALE_DEFAULT ?= "en_US.UTF-8"
# set locale used during package installation, which is visible to
# maintainer scripts (e.g. used in console-setup)
export LANG = "${LOCALE_DEFAULT}"
export LANGUAGE = "${LOCALE_DEFAULT}"
export LC_ALL = "${LOCALE_DEFAULT}"

def get_locale_gen(d, sep='\n'):
    locale_gen = d.getVar("LOCALE_GEN") or ""
    return sep.join(sorted(set(i.strip()
                               for i in locale_gen.split('\\n')
                               if i.strip())))

def get_locale_dirs(d):
    # Directory names below /usr/share/locale that shall be kept, derived from
    # the language and language_territory parts of LOCALE_GEN.
    locale_gen = d.getVar("LOCALE_GEN") or ""
    return sorted(set(i
                      for j in locale_gen.split('\\n')
                      if j.strip()
                      for i in (j.split()[0].split("_")[0],
                                j.split()[0].split(".")[0])))

def get_locale_path_include(d):
    lines = []
    for name in get_locale_dirs(d):
        lines.append("path-include=/usr/share/locale/%s" % name)
        lines.append("path-include=/usr/share/locale/%s/*" % name)
    return "\n".join(lines)

# Configure dpkg to only unpack the requested locales, so unneeded locale files
# are never installed. This runs before any package is installed into the image.
# Locale files that the bootstrap already installed are cleaned up here as well.
ROOTFS_CONFIGURE_COMMAND += "image_configure_locale_filter"
image_configure_locale_filter[weight] = "5"
image_configure_locale_filter() {
    cat<<__EOF__ > ${WORKDIR}/locale.dpkg-filter
path-exclude=/usr/share/locale/*
path-include=/usr/share/locale/locale.alias
${@get_locale_path_include(d)}
__EOF__

    run_privileged_heredoc <<'EOSUDO'
        set -e

        mkdir -p '${ROOTFSDIR}/etc/dpkg/dpkg.cfg.d'
        cat '${WORKDIR}/locale.dpkg-filter' \
            > '${ROOTFSDIR}/etc/dpkg/dpkg.cfg.d/50isar-locales'

        # Drop locale files the bootstrap installed that are not requested.
        if [ -d '${ROOTFSDIR}/usr/share/locale' ]; then
            keep=' locale.alias ${@' '.join(get_locale_dirs(d))} '
            for entry in '${ROOTFSDIR}'/usr/share/locale/*; do
                [ -e "$entry" ] || continue
                name=$(basename "$entry")
                case "$keep" in
                    *" $name "*) ;;
                    *) rm -rf "$entry" ;;
                esac
            done
        fi
EOSUDO
}

# Preseed the debconf selection and generate the requested locales up front,
# before any package is installed, so package maintainer scripts find working
# locales.
ROOTFS_CONFIGURE_COMMAND += "image_configure_locale_debconf"
image_configure_locale_debconf[weight] = "5"
image_configure_locale_debconf() {
    cat<<__EOF__ > ${WORKDIR}/locale.debconf
locales     locales/locales_to_be_generated    multiselect ${@get_locale_gen(d, ', ')}
locales     locales/default_environment_locale select      ${LOCALE_DEFAULT}
__EOF__
    cat<<__EOF__ > ${WORKDIR}/locale.gen
${@get_locale_gen(d)}
__EOF__
    cat<<__EOF__ > ${WORKDIR}/locale.default
LANG=${LOCALE_DEFAULT}
__EOF__

    run_privileged_heredoc <<'EOSUDO'
        set -e

        ${@insert_isar_mounts(d, d.getVar('ROOTFSDIR'), '')}

        cat '${WORKDIR}/locale.default' > '${ROOTFSDIR}/etc/default/locale'
        cat '${WORKDIR}/locale.debconf' > '${ROOTFSDIR}/tmp/locale.debconf'

        # Enable the requested locales by uncommenting them in /etc/locale.gen
        while read -r locale; do
            [ -n "$locale" ] || continue
            sed -i "/$locale/s/^# *//" '${ROOTFSDIR}/etc/locale.gen'
        done < '${WORKDIR}/locale.gen'

        chroot '${ROOTFSDIR}' /bin/sh <<'EOSH'
            set -e

            debconf-set-selections /tmp/locale.debconf
            rm -f /tmp/locale.debconf
EOSH
EOSUDO
}

# The systemd locale.conf symlink can only be created once systemd is installed.
ROOTFS_INSTALL_COMMAND += "image_configure_locales"
image_configure_locales[weight] = "100"
image_configure_locales() {
    run_privileged_heredoc <<'EOSUDO'
        set -e

        ${@insert_isar_mounts(d, d.getVar('ROOTFSDIR'), '')}

        chroot '${ROOTFSDIR}' /bin/sh <<'EOSH'
            set -e

            SYSTEMD_VERSION=$(dpkg-query \
                --showformat='${source:Upstream-Version}' \
                --show systemd || echo "0" )

            if dpkg --compare-versions "$SYSTEMD_VERSION" "ge" "251"; then
                if dpkg --compare-versions "$SYSTEMD_VERSION" "lt" "253"; then
                    ln -s /etc/default/locale /etc/locale.conf
                fi
            fi

            echo 'reconfigure locales'
            dpkg-reconfigure -f noninteractive locales
EOSH
EOSUDO
}
