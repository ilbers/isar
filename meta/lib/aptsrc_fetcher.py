# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

from bb.fetch2 import FetchError
from bb.fetch2 import FetchMethod
from bb.fetch2 import logger
from bb.fetch2 import runfetchcmd

class AptSrc(FetchMethod):
    def supports(self, ud, d):
        return ud.type in ['apt']

    def urldata_init(self, ud, d):
        ud.src_package = ud.url[len('apt://'):]
        ud.host = ud.host.replace('=', '_')

        base_distro = d.getVar('BASE_DISTRO')
        codename = d.getVar('BASE_DISTRO_CODENAME')
        ud.localfile='deb-src/' + base_distro + '-' + codename + '/' + ud.host

    def download(self, ud, d):
        bb.utils.exec_flat_python_func('isar_export_proxies', d)
        bb.build.exec_func('schroot_create_configs', d)

        sbuild_chroot = d.getVar('SBUILD_CHROOT')
        session_id = runfetchcmd(f'schroot -q -b -c {sbuild_chroot}', d).strip()
        logger.info(f'Started session: {session_id}')

        repo_isar_dir = d.getVar('REPO_ISAR_DIR')
        lockfile = bb.utils.lockfile(f'{repo_isar_dir}/isar.lock')

        try:
            runfetchcmd(f'''
                set -e
                schroot -r -c {session_id} -d / -u root -- \
                    rm /etc/apt/sources.list.d/isar-apt.list /etc/apt/preferences.d/isar-apt
                schroot -r -c {session_id} -d / -- \
                    sh -c '
                        set -e
                        mkdir -p /downloads/{ud.localfile}
                        cd /downloads/{ud.localfile}
                        apt-get -y --download-only --only-source source {ud.src_package}
                        '
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
        try:
            runfetchcmd(f'''
                set -e
                schroot -r -c {session_id} -d / -u root -- \
                    rm /etc/apt/sources.list.d/isar-apt.list /etc/apt/preferences.d/isar-apt
                schroot -r -c {session_id} -d / -- \
                    sh -c '
                        set -e
                        dscfile=$(apt-get -y -qq --print-uris --only-source source {ud.src_package} | \
                                  cut -d " " -f2 | grep -E "\.dsc")
                        cp /downloads/{ud.localfile}/* {pp}
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

    def clean(self, ud, d):
        bb.utils.remove(ud.localpath, recurse=True)
