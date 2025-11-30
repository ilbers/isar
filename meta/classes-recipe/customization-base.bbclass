# Common class for customization packages, used by dpkg-customization.bbclass
# and image-customizations.bbclass.

LIST_VARIABLES += "CUSTOMIZATIONS CUSTOMIZATION_VARS CUSTOMIZATION_VARS_PREFIXED"

CUSTOMIZATIONS ?= ""
CUSTOMIZATIONS[doc] = "List of customization packages to be installed in images."

CUSTOMIZATION_VARS ?= "${DISTRO} ${MACHINE}"
CUSTOMIZATION_VARS[doc] = "List of variables that should be added to customization package names."
OVERRIDES:append = "${@ ':customization-for-images' if (d.getVar('CUSTOMIZATION_FOR_IMAGES') or '').strip() else '' }"
CUSTOMIZATION_VARS:append:customization-for-images = " ${IMAGE}"

CUSTOMIZATION_VARS_PREFIXED ?= "${DISTRO}"
CUSTOMIZATION_VARS_PREFIXED[doc] = "List of variables from CUSTOMIZATION_VARS that should be prefixed rather than suffixed to customization package names."

CUSTOMIZATION_FOR_IMAGES ?= ""
CUSTOMIZATION_FOR_IMAGES[doc] = "List of images that should install the customizations in CUSTOMIZATIONS"

CUSTOMIZATION_PREFIX ?= "${@'-'.join(var for var in d.getVar('CUSTOMIZATION_VARS').split() if var in d.getVar('CUSTOMIZATION_VARS_PREFIXED'))}"
CUSTOMIZATION_SUFFIX ?= "${@'-'.join(var for var in d.getVar('CUSTOMIZATION_VARS').split() if var not in d.getVar('CUSTOMIZATION_VARS_PREFIXED'))}"
