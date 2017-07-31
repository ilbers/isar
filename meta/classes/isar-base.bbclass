do_build[nostamp] = "0"

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
do_fetch[dirs] = "${DL_DIR}"

# Unpack package and put it into working directory in buildchroot
python do_unpack() {
    src_uri = (d.getVar('SRC_URI', True) or "").split()
    if len(src_uri) == 0:
        return

    try:
        fetcher = bb.fetch2.Fetch(src_uri, d)
        fetcher.unpack(d.getVar('WORKDIR', True))
    except bb.fetch2.BBFetchException as e:
        raise bb.build.FuncFailed(e)
}

addtask unpack after do_fetch before do_build
do_unpack[dirs] = "${WORKDIR}"
do_unpack[stamp-extra-info] = "${DISTRO}"
