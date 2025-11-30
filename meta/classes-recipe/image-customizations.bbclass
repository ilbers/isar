inherit customization-base

def customization_packages(d):
    customizations = d.getVar('CUSTOMIZATIONS').split()
    if not customizations:
        return ''

    # Use image-specific customization if enabled for this image
    images = (d.getVar('CUSTOMIZATION_FOR_IMAGES') or '').split()
    image = d.getVar('BPN')
    if not images or image not in images:
        d.setVar('IMAGE', '')
    else:
        d.setVar('IMAGE', image)

    prefix = d.getVar('CUSTOMIZATION_PREFIX')
    if prefix:
        prefix += '-'

    suffix = d.getVar('CUSTOMIZATION_SUFFIX')
    if suffix:
        suffix = '-customization-' + suffix
    else:
        suffix = '-customization'

    customizations = [ prefix + package + suffix for package in customizations ]
    return ' '.join(customizations)

CUSTOMIZATION_PACKAGES = "${@ customization_packages(d) }"
IMAGE_INSTALL:append = " ${CUSTOMIZATION_PACKAGES}"
