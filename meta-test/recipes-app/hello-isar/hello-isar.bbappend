# Checking patches apply
# Using PN only for testing autofix, BPN should be used instead
FILESPATH:prepend := "${FILE_DIRNAME}/${PN}:"

SRC_URI += " \
    file://yet-another-change.txt;apply=yes;striplevel=0 \
"

# Examples for SRC_URI parser testing
SRC_URI += " \
    file://nonexist-file \
"
SRC_URI:append = " \
    git://nonexist-git \
"
SRC_URI:remove = "file://nonexist-file"
SRC_URI:remove = "git://nonexist-git"

# avoid creating a dedicated sbuild chroot
SBUILD_FLAVOR = ""
