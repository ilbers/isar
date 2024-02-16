# Examples for SRC_URI parser testing
SRC_URI += " \
    file://nonexist-file \
"
SRC_URI:append = " \
    git://nonexist-git \
"
SRC_URI:remove = "file://nonexist-file"
SRC_URI:remove = "git://nonexist-git"
