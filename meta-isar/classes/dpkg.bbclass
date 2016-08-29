DEPENDS += "buildroot"
do_unpack[deptask] = "do_build"

PP = "/home/builder/${PN}"
BUILDROOT = "${BUILDROOTDIR}/${PP}"

addtask fetch
do_fetch[dirs] = "${DL_DIR}"
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

do_unpack[dirs] = "${BUILDROOT}"
S = "${BUILDROOT}"
python do_unpack() {
	src_uri = (d.getVar('SRC_URI', True) or "").split()
	if len(src_uri) == 0:
		return

	rootdir = d.getVar('BUILDROOT', True)

	try:
		fetcher = bb.fetch2.Fetch(src_uri, d)
		fetcher.unpack(rootdir)
	except bb.fetch2.BBFetchException as e:
		raise bb.build.FuncFailed(e)
}
addtask unpack after do_fetch before do_build

do_build() {
    sudo chroot ${BUILDROOTDIR} /build.sh ${PP}/${SRC_DIR}
}

do_install() {
    install -d ${DEPLOY_DIR_DEB}
    install -m 755 ${BUILDROOT}/*.deb ${DEPLOY_DIR_DEB}/
}
addtask do_install after do_build
