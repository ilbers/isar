inherit dpkg-customization

DESCRIPTION      = "Amend the system hostname"
LICENSE          = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"
MAINTAINER       = "isar-users <isar-users@googlegroups.com>"
DEBIAN_DEPENDS   = "netbase"
PV               = "0.3"
SRC_URI          = "file://postinst.tmpl"
TEMPLATE_FILES   = "postinst.tmpl"
TEMPLATE_VARS    = "HOSTNAME"
