DEPENDS += "buildroot"
do_build[deptask] = "do_build"

BUILDROOT = "${BUILDROOTDIR}/home/builder/${PN}"

do_prepare() {
    sudo install -d ${BUILDROOT}
}

addtask prepare before do_build
