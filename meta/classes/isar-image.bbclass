# Class for backwards compatibility of images that use it
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH
# Copyright (c) Siemens AG, 2019
inherit image

python() {
    bb.warn("isar-image is deprecated, please change 'isar-image' inheritance "
            "to 'image'.")
}
