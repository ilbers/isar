# This software is a part of ISAR.
#
# Copyright (C) 2003  Chris Larson
# Copyright (C) 2015-2025 ilbers GmbH
# Copyright (C) 2017-2025 Siemens AG
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

THISDIR = "${@os.path.dirname(d.getVar('FILE'))}"
FILESPATH = "${@base_set_filespath(["${FILE_DIRNAME}/${PF}", "${FILE_DIRNAME}/${P}", "${FILE_DIRNAME}/${PN}", "${FILE_DIRNAME}/files", "${FILE_DIRNAME}"], d)}"

OE_IMPORTS += "os sys time oe.path oe.patch oe.reproducible oe.sstatesig oe.utils"
OE_IMPORTS[type] = "list"

def oe_import(d):
    import sys

    bbpath = d.getVar("BBPATH").split(":")
    sys.path[0:0] = [os.path.join(dir, "lib") for dir in bbpath]

    def inject(name, value):
        """Make a python object accessible from the metadata"""
        if hasattr(bb.utils, "_context"):
            bb.utils._context[name] = value
        else:
            __builtins__[name] = value

    import oe.data
    for toimport in oe.data.typed_value("OE_IMPORTS", d):
        try:
            imported = __import__(toimport)
            inject(toimport.split(".", 1)[0], imported)
        except AttributeError as e:
            bb.error("Error importing OE modules: %s" % str(e))
    return ""

# We need the oe module name space early (before INHERITs get added)
OE_IMPORTED := "${@oe_import(d)}"

def get_deb_host_arch():
    import subprocess
    host_arch = subprocess.check_output(
        ["dpkg", "--print-architecture"]
    ).decode('utf-8').strip()
    return host_arch
# immediately evaluate to avoid costly process call
HOST_ARCH := "${@get_deb_host_arch()}"
HOST_DISTRO ??= "${DISTRO}"

# Inject the PREFERRED_PROVIDERs for multiarch variants. This corresponds to
# the multiarch_virtclass_handler logic in multiarch.bbclass, but needs to be
# done prior to recipe parsing.
def inject_preferred_providers(provider, suffix, d):
    PP_PREFIX = 'PREFERRED_PROVIDER_'
    if provider.endswith(suffix):
        return
    prefp_value = d.getVar(PP_PREFIX + provider)
    if prefp_value and not d.getVar(PP_PREFIX + provider + suffix):
        d.setVar(PP_PREFIX + provider + suffix, prefp_value + suffix)

python multiarch_preferred_providers_handler() {
    if d.getVar('HOST_ARCH') == d.getVar('DISTRO_ARCH'):
        return

    pref_vars = {var: e.data.getVar(var)
                 for var in e.data.keys()
                 if var.startswith('PREFERRED_PROVIDER_')}
    for p in pref_vars:
        inject_preferred_providers(p.replace('PREFERRED_PROVIDER_', ''), '-native', e.data)
}
addhandler multiarch_preferred_providers_handler
multiarch_preferred_providers_handler[eventmask] = "bb.event.ConfigParsed"

die() {
	bbfatal "$*"
}

inherit logging
inherit template

# Derived from bitbake: bitbake/classes/base.bbclass
addtask showdata
do_showdata[nostamp] = "1"
python do_showdata() {
    for e in d.keys():
        if d.getVarFlag(e, 'python'):
            code = d.getVar(e)
            if code.startswith("def"):
                bb.plain("\n" + code + "\n")
            else:
                bb.plain(
                    "\npython {name} () {{\n{code}}}\n".format(
                        name=e, code=code
                    )
                )
}

# Derived from Open Embedded: openembedded-core/meta/classes/utility-tasks.bbclass
addtask listtasks
do_listtasks[nostamp] = "1"
python do_listtasks() {
    tasks = {}
    maxlen = 0
    for e in d.keys():
        if d.getVarFlag(e, 'task'):
            maxlen = max(maxlen, len(e))
            if e.endswith('_setscene'):
                tasks[e] = (
                    d.getVarFlag(e[:-9], 'doc') or ''
                ) + " (setscene version)"
            else:
                tasks[e] = d.getVarFlag(e, 'doc') or ''

    for name, desc in sorted(tasks.items()):
        bb.plain("{0:{len}}  {1}".format(name, desc, len=maxlen))
}

root_cleandirs() {
    ROOT_CLEANDIRS_DIRS_PY="${@d.getVar("ROOT_CLEANDIRS_DIRS") or ""}"
    ROOT_CLEANDIRS_DIRS="${ROOT_CLEANDIRS_DIRS-${ROOT_CLEANDIRS_DIRS_PY}}"
    TMPDIR_PY="${@d.getVar("TMPDIR") or ""}"
    TMPDIR="${TMPDIR-${TMPDIR_PY}}"
    for i in $ROOT_CLEANDIRS_DIRS; do
        awk '{ print $2 }' /proc/mounts | grep -q "^${i}\(/\|\$\)" && \
            die "Could not remove $i, because subdir is mounted"
    done
    for i in $ROOT_CLEANDIRS_DIRS; do
        [ -d "$TMPDIR$i" ] || continue
        find "$TMPDIR$i" \( ! -user "$(whoami)" -type d -prune \) -exec ${RUN_PRIVILEGED_CMD} rm -rf --one-file-system {} \;
        rm -rf --one-file-system "$TMPDIR$i"
        mkdir -p "$TMPDIR$i"
    done
}

python() {
    import re

    needsrcrev = False
    srcuri = d.getVar('SRC_URI')
    for uri_string in srcuri.split():
        if not uri_string.startswith("apt://"):
            uri = bb.fetch.URI(uri_string)
            if uri.scheme in ("svn", "git", "gitsm", "hg", "p4", "repo"):
                needsrcrev = True

    if needsrcrev:
        d.setVar("SRCPV", "${@bb.fetch2.get_srcrev(d)}")

    for e in d.keys():
        flags = d.getVarFlags(e)
        if flags and flags.get('task'):
            rcleandirs = flags.get('root_cleandirs')
            if rcleandirs:
                tmpdir = os.path.normpath(d.getVar("TMPDIR"))
                rcleandirs = list(
                    os.path.normpath(d.expand(i)) for i in rcleandirs.split()
                )

                for i in rcleandirs:
                    if not i.startswith(tmpdir):
                        bb.fatal(
                            "root_cleandirs entry {} is not contained in TMPDIR {}".format(
                                i, tmpdir
                            )
                        )

                if flags.get('python'):
                    cleandir_code = (
                        "{ws}d.setVar('ROOT_CLEANDIRS_DIRS', '{dirlist}')\n"
                        "{ws}bb.build.exec_func('root_cleandirs', d)\n"
                    )
                else:
                    cleandir_code = (
                        "{ws}ROOT_CLEANDIRS_DIRS='{dirlist}'\n"
                        "{ws}root_cleandirs\n"
                    )

                ws = re.match(r"^\s*", d.getVar(e, False)).group()
                # remove prefix ${TMPDIR}, so we don't have absolute paths in variable e
                dirs = [dir[len(tmpdir):] for dir in rcleandirs]
                d.prependVar(
                    e, cleandir_code.format(ws=ws, dirlist=" ".join(dirs))
                )

    need_machine = d.getVar('COMPATIBLE_MACHINE')
    if need_machine and not d.getVar('PARSE_ALL_RECIPES', False):
        compat_machines = (d.getVar('MACHINEOVERRIDES') or "").split(":")
        for m in compat_machines:
            if re.match(need_machine, m):
                break
        else:
            raise bb.parse.SkipRecipe("incompatible with machine %s (not in COMPATIBLE_MACHINE)" % d.getVar('MACHINE'))
}

def isar_export_proxies(d):
    deadend_proxy = 'http://this.should.fail:4242'
    variables = ['http_proxy', 'HTTP_PROXY', 'https_proxy', 'HTTPS_PROXY',
                    'ftp_proxy', 'FTP_PROXY' ]

    if bb.utils.to_boolean(d.getVar('BB_NO_NETWORK')):
        for v in variables:
            d.setVar(v, deadend_proxy)
        for v in [ 'no_proxy', 'NO_PROXY' ]:
            d.setVar(v, '')

    return bb.utils.export_proxies(d)

def isar_export_ccache(d):
    if bb.utils.to_boolean(d.getVar('USE_CCACHE')):
        os.environ['CCACHE_DIR'] = '/ccache'
        os.environ['PATH_PREPEND'] = '/usr/lib/ccache'
        if bb.utils.to_boolean(d.getVar('CCACHE_DEBUG')):
            os.environ['CCACHE_DEBUG'] = '1'
            os.environ['CCACHE_DEBUGDIR'] = '/ccache/debug'
    else:
        os.environ['CCACHE_DISABLE'] = '1'

do_fetch[dirs] = "${DL_DIR}"
do_fetch[file-checksums] = "${@bb.fetch.get_checksum_file_list(d)}"
do_fetch[vardeps] += "SRCREV"
do_fetch[network] = "${TASK_USE_NETWORK}"

# Fetch package from the source link
python do_fetch() {
    src_uri = (d.getVar('SRC_URI') or "").split()
    if len(src_uri) == 0:
        return

    try:
        fetcher = bb.fetch2.Fetch(src_uri, d)
        fetcher.download()
    except bb.fetch2.BBFetchException as e:
        bb.fatal(str(e))
}

addtask fetch

do_unpack[dirs] = "${WORKDIR}"

# Unpack package and put it into working directory
python do_unpack() {
    src_uri = (d.getVar('SRC_URI') or "").split()
    if len(src_uri) == 0:
        return

    rootdir = d.getVar('WORKDIR')

    try:
        fetcher = bb.fetch2.Fetch(src_uri, d)
        fetcher.unpack(rootdir)
    except bb.fetch2.BBFetchException as e:
        bb.fatal(str(e))
}

addtask unpack after do_fetch

do_build[noexec] = "1"
do_build () {
    :
}

addtask build

CLEANFUNCS ?= ""

# Derived from OpenEmbedded Core: meta/classes/utility-tasks.bbclass
addtask clean
do_clean[nostamp] = "1"
do_clean[network] = "${TASK_USE_SUDO}"
python do_clean() {
    import subprocess
    import glob

    for f in (d.getVar('CLEANFUNCS') or '').split():
        bb.build.exec_func(f, d)

    workdir = d.expand("${WORKDIR}")
    subprocess.check_call(["sudo", "rm", "-rf", workdir])

    stampclean = bb.data.expand(d.getVar('STAMPCLEAN', False), d)
    stampdirs = glob.glob(stampclean)
    subprocess.check_call(["sudo", "rm", "-rf"] + stampdirs)
}

# Derived from OpenEmbedded Core: meta/classes/base.bbclass
addtask cleansstate after do_clean
do_cleansstate[nostamp] = "1"
python do_cleansstate() {
    sstate_clean_cachefiles(d)
}

addtask cleanall after do_cleansstate
do_cleanall[nostamp] = "1"
python do_cleanall() {
    src_uri = (d.getVar('SRC_URI') or "").split()
    if len(src_uri) == 0:
        return

    try:
        fetcher = bb.fetch2.Fetch(src_uri, d)
        fetcher.clean()
    except bb.fetch2.BBFetchException as e:
        bb.fatal(str(e))
}

# Derived from OpenEmbedded Core: meta/classes/utils.bbclass
def base_set_filespath(path, d):
    filespath = []
    extrapaths = (d.getVar("FILESEXTRAPATHS") or "")
    # Remove default flag which was used for checking
    extrapaths = extrapaths.replace("__default:", "")
    # Don't prepend empty strings to the path list
    if extrapaths != "":
        path = extrapaths.split(":") + path
    # The ":" ensures we have an 'empty' override
    overrides = (":" + (d.getVar("FILESOVERRIDES") or "")).split(":")
    overrides.reverse()
    for o in overrides:
        for p in path:
            if p != "":
                filespath.append(os.path.join(p, o))
    return ":".join(filespath)

def calculate_build_uuid(d):
    import uuid

    uuid_data = bb.persist_data.persist('BB_ISAR_UUID_DATA', d)
    if "uuid" not in uuid_data or not uuid_data["uuid"]:
        # Generate new UUID
        uuid_data["uuid"] = str(uuid.uuid4())

    return uuid_data["uuid"]

# Unique ID for this build, used to avoid name clashes on external mountpoints
# When running parallel builds in different PID namespaces
ISAR_BUILD_UUID = "${@ calculate_build_uuid(d)}"

do_deploy_source_date_epoch[dirs] = "${SDE_DEPLOYDIR}"
do_deploy_source_date_epoch[sstate-plaindirs] = "${SDE_DEPLOYDIR}"
addtask do_deploy_source_date_epoch_setscene
addtask do_deploy_source_date_epoch before do_configure after do_patch

python create_source_date_epoch_stamp() {
    # Version: 1
    source_date_epoch = oe.reproducible.get_source_date_epoch(d, d.getVar('S'))
    oe.reproducible.epochfile_write(source_date_epoch, d.getVar('SDE_FILE'), d)
}
do_unpack[postfuncs] += "create_source_date_epoch_stamp"

def get_source_date_epoch_value(d):
    return oe.reproducible.epochfile_read(d.getVar('SDE_FILE'), d)

def deb_list_beautify(d, varname):
    line = d.getVar(varname)
    if not line:
        return ''

    var_list = []
    for a in line.split(','):
        stripped = a.strip()
        if stripped:
            var_list.append(stripped)
    return ', '.join(var_list)

# Helpers for privileged execution. Only the non-underscore functions
# shall be used outside of this class.

def insert_isar_mounts(d, rootfs, mounts):
    """
    In unshare mode, all mounts must be created after unsharing the
    mount namespace. As needs to happen within the unshared session,
    we implement it as a code generator. Note, that the random and urandom
    mounts are needed for DDI images.
    """
    lines = []
    to_touch = ['/dev/null', '/dev/random', '/dev/urandom']
    to_mkdir = ['/dev/pts', '/dev/shm']
    if d.getVar('ISAR_CHROOT_MODE') == 'unshare':
        lines.append('touch ' + ' '.join(['{}/{}'.format(rootfs, f) for f in to_touch]))
        lines.append('mkdir -p ' + ' '.join(['{}/{}'.format(rootfs, f) for f in to_mkdir]))
        lines.append('mount -o bind,private,mode=666 /dev/null {}/dev/null'.format(rootfs))
        lines.append('mount -t devpts -o noexec,nosuid,uid=5,mode=620,ptmxmode=666 none {}/dev/pts'.format(rootfs))
        lines.append('( cd {}/dev; ln -sf pts/ptmx . )'.format(rootfs))
        lines.append('mount -t tmpfs none {}/dev/shm'.format(rootfs))
        lines.append('mount -o bind /dev/random {}/dev/random'.format(rootfs))
        lines.append('mount -o bind /dev/urandom {}/dev/urandom'.format(rootfs))
        lines.append('mount -t proc none {}/proc'.format(rootfs))
        # we do not unshare the network namespace, so we cannot create a sysfs, hence bind-mount
        lines.append('mount -o rbind /sys {}/sys'.format(rootfs))

    for m in mounts.split():
        host, inner = m.split(':') if ':' in m else (m, m)
        inner_full = os.path.join(rootfs, inner[1:])
        lines.append('mkdir -p {}'.format(inner_full))
        lines.append('mount -o bind,private {} {}'.format(host, inner_full))
    return '\n'.join(lines)

def insert_isar_umounts(d, rootfs, mounts):
    """
    In unshare mount we don't unmount the system mounts but just
    remove the mountpoints.
    """
    lines = []
    to_unlink = ['/dev/null', '/dev/random', '/dev/urandom', '/dev/ptmx']
    to_rmdir = ['/dev/pts', '/dev/shm']
    if d.getVar('ISAR_CHROOT_MODE') == 'unshare':
        lines.append('rm -f ' + ' '.join(['{}/{}'.format(rootfs, f) for f in to_unlink]))
        for d in ['{}/{}'.format(rootfs, _d) for _d in to_rmdir]:
            lines.append('[ -d {} ] && rmdir {}'.format(d, d))

    for m in mounts.split():
        host, inner = m.split(':') if ':' in m else (m, m)
        mp = '{}/{}'.format(rootfs, inner)
        lines.append('mountpoint -q {} && umount {}'.format(mp, mp))
        lines.append('[ -d {} ] && rmdir --ignore-fail-on-non-empty {}'.format(mp, mp))
    return '\n'.join(lines)

def get_subid_range(idmap, d):
    import getpass
    with open(idmap, 'r') as f:
        entries = f.readlines()
    for e in entries:
        user, base, cnt = e.split(':')
        if user == os.getuid() or user == getpass.getuser():
            return int(base), int(cnt)
    bb.error("No sub-id range specified in %s" % idmap)

def run_privileged_cmd(d):
    """
    In unshare mode we need to map the rootfs uid/gid range into the
    subuid/subgid range of the parent namespace. As we usually only
    get 65534 ids, we cannot map the whole range, as two ids are already
    used by the calling environment (root and builder user). Hence, map
    as much as we can but also map the highest id (nobody / nogroup) as
    these are used within the rootfs. It would be easier to use
    mmdebstrap --unshare-helper as command (which is also internally used
    by sbuild), but this only maps linear ranges, hence it cannot map the
    nobody / nogroup on the default subid range. By that, we have to avoid
    the nobody / nogroup when building packages in this case.
    """
    if d.getVar('ISAR_CHROOT_MODE') == 'unshare':
        nobody_id = 65534
        uid_base, uid_cnt = get_subid_range('/etc/subuid', d)
        nobody_subid = uid_base + uid_cnt - 1
        gid_base, gid_cnt = get_subid_range('/etc/subgid', d)
        nogroup_subid = gid_base + gid_cnt - 1
        cmd = 'unshare --mount --pid --uts --ipc --user' \
              ' --kill-child' \
              ' --setuid 0 --setgid 0 --fork' \
              f' --map-users  1:{uid_base+1}:{uid_cnt-2}' \
              f' --map-groups 1:{gid_base+1}:{gid_cnt-2}'
        if uid_cnt < nobody_id:
            cmd += f' --map-users  {nobody_id}:{nobody_subid}:1'
        if gid_cnt < nobody_id:
            cmd += f' --map-groups {nobody_id}:{nogroup_subid}:1'
        cmd += " --map-root-user"
    else:
        cmd = 'sudo -E'
    bb.debug(1, "privileged cmd: %s" % cmd)
    return cmd

UNSHARE_SUBUID_BASE  := "${@get_subid_range('/etc/subuid', d)[0] if d.getVar('ISAR_CHROOT_MODE') == 'unshare' else '0'}"
# store in variable to only compute once and make available to fetcher
RUN_PRIVILEGED_CMD := "${@run_privileged_cmd(d)}"

run_privileged() {
    ${RUN_PRIVILEGED_CMD} "$@"
}

run_privileged_heredoc() {
    ${RUN_PRIVILEGED_CMD} /bin/bash -s "$@"
}

run_in_chroot() {
    rootfs="$1"
    shift

    rootfs=$rootfs run_privileged_heredoc <<'EORIC' "$@"
        set -e
        ${@insert_isar_mounts(d, '$rootfs', '')}
        chroot "$rootfs" "$@"
EORIC
}
