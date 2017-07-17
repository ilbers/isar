THISDIR = "${@os.path.dirname(d.getVar('FILE', True))}"

bbdebug() {
	test $# -ge 2 || {
		echo "Usage: bbdebug level \"message\""
		exit 1
	}

	test ${@bb.msg.debug_level['default']} -ge $1 && {
		shift
		echo "DEBUG:" $*
	}
}

do_build[nostamp] = "0"
