inherit dpkg-raw customization-base

PRE_CUSTOMIZATION_PN := "${PN}"
FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
PN =. "${@d.getVar('CUSTOMIZATION_PREFIX') + '-' if d.getVar('CUSTOMIZATION_PREFIX') else ''}"
PN .= "${@'-' + d.getVar('CUSTOMIZATION_SUFFIX') if d.getVar('CUSTOMIZATION_SUFFIX') else ''}"

BBCLASSEXTEND = "${@' '.join(f'dpkg-customization:{image}' for image in d.getVar('CUSTOMIZATION_FOR_IMAGES').split())}"

python customization_virtclass_handler() {
    orig_pn = d.getVar('PRE_CUSTOMIZATION_PN')

    d = e.data
    extend = d.getVar('BBEXTENDCURR') or ''
    variant = d.getVar('BBEXTENDVARIANT') or ''
    if extend != 'dpkg-customization' or variant == '':
        d.appendVar('PROVIDES', f' {orig_pn}')
        d.setVar('IMAGE', '')
        return

    vars = (d.getVar('CUSTOMIZATION_VARS', expand=False) or '').split()
    if '${IMAGE}' not in vars:
        return

    images = (d.getVar('CUSTOMIZATION_FOR_IMAGES') or '').split()
    if variant not in images:
        return

    d.setVar('IMAGE', variant)
    if not d.getVar('BPN').endswith(f'-{variant}'):
        d.appendVar('BPN', f'-{variant}')
    d.appendVar('PROVIDES', f' {orig_pn}-{variant}')
    d.appendVar('OVERRIDES', f':{variant}')
}
addhandler customization_virtclass_handler
customization_virtclass_handler[eventmask] = "bb.event.RecipePreFinalise"

