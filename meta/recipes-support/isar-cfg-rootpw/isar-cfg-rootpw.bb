# This software is a part of ISAR.

DESCRIPTION = "Isar configuration package for root password"
MAINTAINER = "isar-users <isar-users@googlegroups.com>"
DEBIAN_DEPENDS = "passwd"

SRC_URI = "file://postinst.tmpl"

TEMPLATE_FILES = "postinst.tmpl"
TEMPLATE_VARS = "CFG_ROOT_PW CFG_ROOT_LOCKED"

CFG_ROOT_PW ??= ""
CFG_ROOT_LOCKED ??= "0"

inherit dpkg-raw

do_install() {
    echo "intentionally left blank"
}
