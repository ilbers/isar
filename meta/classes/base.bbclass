# Copyright (C) 2003  Chris Larson
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

THISDIR = "${@os.path.dirname(d.getVar('FILE', True))}"

def get_deb_host_arch():
    import subprocess
    host_arch = subprocess.check_output(
        ["dpkg", "--print-architecture"]
    ).decode('utf-8').strip()
    return host_arch
HOST_ARCH ??= "${@get_deb_host_arch()}"
HOST_DISTRO ??= "${DISTRO}"

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
            code = d.getVar(e, True)
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
    ROOT_CLEANDIRS_DIRS_PY="${@d.getVar("ROOT_CLEANDIRS_DIRS", True) or ""}"
    ROOT_CLEANDIRS_DIRS="${ROOT_CLEANDIRS_DIRS-${ROOT_CLEANDIRS_DIRS_PY}}"
    for i in $ROOT_CLEANDIRS_DIRS; do
        awk '{ print $2 }' /proc/mounts | grep -q "^${i}\(/\|\$\)" && \
            die "Could not remove $i, because subdir is mounted"
    done
    if [ -n "$ROOT_CLEANDIRS_DIRS" ]; then
        sudo rm -rf --one-file-system $ROOT_CLEANDIRS_DIRS
        mkdir -p $ROOT_CLEANDIRS_DIRS
    fi
}

python() {
    import re

    for e in d.keys():
        flags = d.getVarFlags(e)
        if flags and flags.get('task'):
            rcleandirs = flags.get('root_cleandirs')
            if rcleandirs:
                tmpdir = os.path.normpath(d.getVar("TMPDIR", True))
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
                d.prependVar(
                    e, cleandir_code.format(ws=ws, dirlist=" ".join(rcleandirs))
                )
}

# filter out all "apt://" URIs out of SRC_URI and stick them into SRC_APT
python() {
    src_uri = (d.getVar('SRC_URI', True) or "").split()
    if len(src_uri) == 0:
        return

    prefix = "apt://"
    new_src_uri = []
    src_apt = []
    for u in src_uri:
        if u.startswith(prefix):
            src_apt.append(u[len(prefix) :])
        else:
            new_src_uri.append(u)

    d.setVar('SRC_URI', ' '.join(new_src_uri))
    d.prependVar('SRC_APT', ' '.join(src_apt))
}

do_fetch[dirs] = "${DL_DIR}"
do_fetch[file-checksums] = "${@bb.fetch.get_checksum_file_list(d)}"
do_fetch[vardeps] += "SRCREV"

# Fetch package from the source link
python do_fetch() {
    src_uri = (d.getVar('SRC_URI', True) or "").split()
    if len(src_uri) == 0:
        return

    try:
        fetcher = bb.fetch2.Fetch(src_uri, d)
        fetcher.download()
    except bb.fetch2.BBFetchException as e:
        raise bb.build.FuncFailed(e)
}

addtask fetch before do_build

do_unpack[dirs] = "${WORKDIR}"
do_unpack[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"

# Unpack package and put it into working directory
python do_unpack() {
    src_uri = (d.getVar('SRC_URI', True) or "").split()
    if len(src_uri) == 0:
        return

    rootdir = d.getVar('WORKDIR', True)

    try:
        fetcher = bb.fetch2.Fetch(src_uri, d)
        fetcher.unpack(rootdir)
    except bb.fetch2.BBFetchException as e:
        raise bb.build.FuncFailed(e)
}

addtask unpack after do_fetch before do_build

addtask build
do_build[dirs] = "${TOPDIR}"
python base_do_build () {
    bb.note("The included, default BB base.bbclass does not define a useful default task.")
    bb.note("Try running the 'listtasks' task against a .bb to see what tasks are defined.")
}

EXPORT_FUNCTIONS do_build

CLEANFUNCS ?= ""

# Derived from OpenEmbedded Core: meta/classes/utility-tasks.bbclass
addtask clean
do_clean[nostamp] = "1"
python do_clean() {
    import subprocess
    import glob

    for f in (d.getVar('CLEANFUNCS', True) or '').split():
        bb.build.exec_func(f, d)

    workdir = d.expand("${WORKDIR}")
    subprocess.check_call(["sudo", "rm", "-rf", workdir])

    stamppath = bb.data.expand(d.getVar('STAMP', False), d)
    stampdirs = glob.glob(stamppath + ".*")
    subprocess.check_call(["sudo", "rm", "-rf"] + stampdirs)
}

# Derived from OpenEmbedded Core: meta/classes/base.bbclass
addtask cleanall after do_clean
do_cleanall[nostamp] = "1"
python do_cleanall() {
    src_uri = (d.getVar('SRC_URI', True) or "").split()
    if len(src_uri) == 0:
        return

    try:
        fetcher = bb.fetch2.Fetch(src_uri, d)
        fetcher.clean()
    except bb.fetch2.BBFetchException as e:
        bb.fatal(str(e))
}
