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

die() {
	bbfatal "$*"
}

bbnote() {
	echo "NOTE:" "$*"
}

bbwarn() {
	echo "WARNING:" "$*"
}

bbfatal() {
	echo "FATAL:" "$*"
	exit 1
}

# Derived from bitbake: bitbake/classes/base.bbclass
addtask showdata
do_showdata[nostamp] = "1"
python do_showdata() {
    for e in d.keys():
        if d.getVarFlag(e, 'python'):
            bb.plain("\npython %s () {\n%s}\n" % (e, d.getVar(e, True)))
}

# Derived from Open Embedded: openembedded-core/meta/classes/utility-tasks.bbclass
addtask listtasks
do_listtasks[nostamp] = "1"
python do_listtasks() {
    taskdescs = {}
    maxlen = 0
    for e in d.keys():
        if d.getVarFlag(e, 'task'):
            maxlen = max(maxlen, len(e))
            if e.endswith('_setscene'):
                desc = "%s (setscene version)" % (d.getVarFlag(e[:-9], 'doc') or '')
            else:
                desc = d.getVarFlag(e, 'doc') or ''
            taskdescs[e] = desc

    tasks = sorted(taskdescs.keys())
    for taskname in tasks:
        bb.plain("%s  %s" % (taskname.ljust(maxlen), taskdescs[taskname]))
}

do_fetch[dirs] = "${DL_DIR}"

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
    import subprocess

    src_uri = (d.getVar('SRC_URI', True) or "").split()
    if len(src_uri) == 0:
        return

    rootdir = d.getVar('WORKDIR', True)

    uid = str(os.getuid())
    subprocess.call('sudo chown -R ' + uid + ' ' + rootdir, shell=True)

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

    for f in (d.getVar('CLEANFUNCS', True) or '').split():
        bb.build.exec_func(f, d)

    dir = d.expand("${WORKDIR}")
    subprocess.call('sudo rm -rf ' + dir, shell=True)

    dir = "%s.*" % bb.data.expand(d.getVar('STAMP', False), d)
    subprocess.call('sudo rm -rf ' + dir, shell=True)
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
