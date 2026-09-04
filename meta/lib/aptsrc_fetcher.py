# This software is a part of Isar.
# Copyright (c) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

from bb.fetch2 import FetchError
from bb.fetch2 import FetchMethod
from bb.fetch2 import logger
from bb.fetch2 import runfetchcmd
import os

class AptSrc(FetchMethod):
    @classmethod
    def create(cls, d):
        if d.getVar('ISAR_CHROOT_MODE') == 'unshare':
            return AptSrcUnshare()
        return AptSrcSchroot()

    def supports(self, ud, d):
        return ud.type in ['apt']

    def urldata_init(self, ud, d):
        ud.src_package = ud.url[len('apt://'):]
        ud.host = ud.host.replace('=', '_')

        base_distro = d.getVar('BASE_DISTRO')
        codename = d.getVar('BASE_DISTRO_CODENAME')
        ud.localfile='deb-src/' + base_distro + '-' + codename + '/' + ud.host

    def clean(self, ud, d):
        bb.utils.remove(ud.localpath, recurse=True)


class AptSrcSchroot(AptSrc):
    def download(self, ud, d):
        bb.utils.exec_flat_python_func('isar_export_proxies', d)
        bb.build.exec_func('schroot_create_configs', d)

        sbuild_chroot = d.getVar('SBUILD_CHROOT')
        session_id = runfetchcmd(f'schroot -q -b -c {sbuild_chroot}', d).strip()
        logger.info(f'Started session: {session_id}')

        repo_isar_dir = d.getVar('REPO_ISAR_DIR')
        lockfile = bb.utils.lockfile(f'{repo_isar_dir}/isar.lock')

        debrepo_target_dir = d.getVar('DEBREPO_TARGET_DIR')
        isar_prefetch_base_apt = d.getVar('ISAR_PREFETCH_BASE_APT')
        repo_base_dir = d.getVar('REPO_BASE_DIR')
        scriptsdir = d.getVar('SCRIPTSDIR')

        try:
            runfetchcmd(f'''
                set -e

                schroot -r -c {session_id} -d / -u root -- \
                    rm /etc/apt/sources.list.d/isar-apt.list /etc/apt/preferences.d/isar-apt

                if [ "{isar_prefetch_base_apt}" = "1" ]; then
                    {scriptsdir}/deb-repo --workdir={debrepo_target_dir} --srcmode "{ud.src_package}"
                else
                    schroot -r -c {session_id} -d / -- \
                        sh -c '
                            set -e
                            mkdir -p /downloads/{ud.localfile}
                            cd /downloads/{ud.localfile}
                            apt-get -y -o Debug::NoLocking=1 --download-only --only-source source {ud.src_package}
                            '
                fi
                ''', d)
        except (OSError, FetchError):
            raise
        finally:
            bb.utils.unlockfile(lockfile)
            runfetchcmd(f'schroot -q -f -e -c {session_id}', d)
            bb.build.exec_func('schroot_delete_configs', d)

    def unpack(self, ud, rootdir, d):
        bb.build.exec_func('schroot_create_configs', d)

        sbuild_chroot = d.getVar('SBUILD_CHROOT')
        session_id = runfetchcmd(f'schroot -q -b -c {sbuild_chroot}', d).strip()
        logger.info(f'Started session: {session_id}')

        pp = d.getVar('PP')
        pps = d.getVar('PPS')

        isar_prefetch_base_apt = d.getVar('ISAR_PREFETCH_BASE_APT')
        repo_base_dir = d.getVar('REPO_BASE_DIR')

        try:
            runfetchcmd(f'''
                set -e
                if [ "{isar_prefetch_base_apt}" = "1" ]; then
                    flock -x "{repo_base_dir}/repo.lock" -c "
                    schroot -r -c {session_id} -d / -u root -- \
                        sh -c 'apt-get -y update -o Dir::Etc::SourceList=\"sources.list.d/base-apt.list\" -o Dir::Etc::SourceParts=\"-\" '
                    "
                fi
                schroot -r -c {session_id} -d / -u root -- \
                    rm /etc/apt/sources.list.d/isar-apt.list /etc/apt/preferences.d/isar-apt
                schroot -r -c {session_id} -d / -- \
                    sh -c '
                        set -e
                        dscfile=$(apt-get -y -qq --print-uris --only-source source {ud.src_package} | \
                                  cut -d " " -f2 | grep -E "\.dsc")

                        if [ "{isar_prefetch_base_apt}" = "1" ]; then
                            temp_dir=$(mktemp -d)
                            cd "$temp_dir"
                            apt-get -y -o Debug::NoLocking=1 --download-only --only-source source {ud.src_package}
                            # Getting rid of links
                            cp -L "$temp_dir"/* {pp}
                        else
                            cp /downloads/{ud.localfile}/* {pp}
                        fi
                        cd {pp}
                        mv -f {pps} {pps}.prev
                        dpkg-source -x "$dscfile" {pps}
                        find {pps}.prev -mindepth 1 -maxdepth 1 -exec mv {{}} {pps}/ \;
                        rmdir {pps}.prev
                        '
                ''', d)
        except (OSError, FetchError):
            raise
        finally:
            runfetchcmd(f'schroot -q -f -e -c {session_id}', d)
            bb.build.exec_func('schroot_delete_configs', d)


class AptSrcUnshare(AptSrc):
    def _setup_chroot(self, rootfsdir, d):
        sbuild_chroot = d.getVar('SBUILD_CHROOT')
        unshare_cmd = d.getVar('RUN_PRIVILEGED_CMD')

        runfetchcmd(
                f'''
{unshare_cmd} /bin/bash -s <<EOF
    mkdir -p {rootfsdir}
    tar -xf {sbuild_chroot} -C {rootfsdir}
    cp /etc/resolv.conf {os.path.join(rootfsdir, 'etc/resolv.conf')}
    rm -f {rootfsdir}/etc/apt/sources.list.d/isar-apt.list \
          {rootfsdir}/etc/apt/preferences.d/isar-apt
EOF
        ''', d)
        logger.info(f'rootfs extracted to: {rootfsdir}')

    def _teardown_chroot(self, rootfsdir, d):
        unshare_cmd = d.getVar('RUN_PRIVILEGED_CMD')
        runfetchcmd(f'{unshare_cmd} rm -rf {rootfsdir}', d)

    def download(self, ud, d):
        bb.utils.exec_flat_python_func('isar_export_proxies', d)

        workdir = d.getVar('WORKDIR')
        rootfsdir = os.path.join(workdir, 'rootfs-fetcher')
        unshare_cmd = d.getVar('RUN_PRIVILEGED_CMD')

        if not os.path.exists(os.path.join(rootfsdir, 'etc')):
            self._setup_chroot(rootfsdir, d)

        repo_isar_dir = d.getVar('REPO_ISAR_DIR')
        lockfile = bb.utils.lockfile(f'{repo_isar_dir}/isar.lock')
        os.makedirs(self.localpath(ud, d))

        try:
            runfetchcmd(f'''
set -e
{unshare_cmd} /bin/bash -s <<'EOF' | tar -C {self.localpath(ud, d)} -x
    chroot {rootfsdir} /bin/bash -c '
        set -e
        TMPDIR=$(mktemp -d)
        mkdir -p $TMPDIR/{ud.localfile}
        cd $TMPDIR/{ud.localfile}
        apt-get -y -o Debug::NoLocking=1 --download-only --only-source source {ud.src_package} >/dev/null;
        tar -c --owner=0 --group=0 --numeric-owner .
        '
EOF
            ''', d)
        except (OSError, FetchError):
            raise
        finally:
            bb.utils.unlockfile(lockfile)
            self._teardown_chroot(rootfsdir, d)

    def unpack(self, ud, rootdir, d):
        workdir = d.getVar('WORKDIR')
        rootfsdir = os.path.join(workdir, 'rootfs-fetcher')
        extractto = f'{d.getVar("S")}.dpkg'
        bb.utils.remove(extractto, recurse=True)

        try:
            runfetchcmd(f'''
                set -e
                find {self.localpath(ud, d)} -print -type f -name '*.dsc' -exec dpkg-source -su -x {{}} {extractto} \\;
                find {extractto} -mindepth 1 -maxdepth 1 -exec mv {{}} {d.getVar('S')}/ \\;
            ''', d)
        except (OSError, FetchError):
            raise
        finally:
            bb.utils.remove(extractto, recurse=True)
            self._teardown_chroot(rootfsdir, d)
