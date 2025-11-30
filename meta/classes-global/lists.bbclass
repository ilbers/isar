# Functions to improve the functionality of bitbake list variables.
#
# - Add the ability to remove items from a list variable without using :remove.
# - Add the ability for a list item to imply the addition of other list items.
#

# Usage requires either adding the variable name to LIST_VARIABLES, or manually
# adding a :remove and a :prepend to each fully supported list variable.
#
# To remove items from a configured list, simply append the item to be removed
# to the variable with a '-' or '~' prefix. For example, to remove 'alpha' from
# ROOTFS_FEATURES, add '-alpha' to ROOTFS_FEATURES.
#
# To support implied list items, create a mapping of items to be appended to
# the variable when a specific item is present. For example, to append 'beta'
# to ROOTFS_FEATURES when 'alpha' is present, configure ROOTFS_FEATURES as such,
# then set IMPLIED_ROOTFS_FEATURES[alpha] = "beta".
#
# Boilerplate example:
#
#   # Either this:
#   LIST_VARIABLES += "ROOTFS_FEATURES"
#
#   # Or this:
#   ROOTFS_FEATURES:remove = "${@remove_prefixed_items('ROOTFS_FEATURES', d)}"
#   ROOTFS_FEATURES:prepend = "${@add_implied_items('ROOTFS_FEATURES', 'IMPLIED_ROOTFS_FEATURES', d)} "
#
# Usage example:
#
#   # ROOTFS_FEATURES will be "beta alpha" if the following configuration is used:
#   IMPLIED_ROOTFS_FEATURES[alpha] = "beta"
#   ROOTFS_FEATURES += "alpha"
#
#   # ROOTFS_FEATURES will be "first" if the following configuration is used:
#   ROOTFS_FEATURES = "first second"
#   ROOTFS_FEATURES += "-second"

python enable_list_variables() {
    """Enable list variable functionality."""
    for variable in d.getVar("LIST_VARIABLES").split():
        d.setVar(variable + ':remove', ' ${@remove_prefixed_items("%s", d)}' % variable)
        d.setVar(variable + ':prepend', '${@add_implied_items("%s", "IMPLIED_%s", d)} ' % (variable, variable))
}
enable_list_variables[eventmask] = "bb.event.ConfigParsed"
addhandler enable_list_variables

def remove_prefixed_items(var, d):
    """Return the items to be removed from var with :remove.

    This function is intended to be used in a :remove handler to remove
    items from a variable. It will interpret items prefixed with a '-'
    or '~' as items to be removed.
    """
    # Use a flag to avoid infinite recursion.
    if d.getVarFlag(var, 'remove_prefixed_items_internal') == '1':
        return ''

    from collections import Counter

    d.setVarFlag(var, 'remove_prefixed_items_internal', '1')
    try:
        value = d.getVar(var)
        counter = Counter()
        for v in value.split():
            if v.startswith('-') or v.startswith('~'):
                counter[v[1:]] -= 1
                counter[v] -= 1
            else:
                counter[v] += 1
        return ' '.join(v for v, c in counter.items() if c < 1)
    finally:
        d.delVarFlag(var, 'remove_prefixed_items_internal')


def add_implied_items(var, implied_var, d):
    """Return the items to be appended due to the presence of other items in var.

    This function is intended to be used in a :append handler to append
    items from a variable. It will rely on the supplied mapping of implied items
    to append the corresponding items.
    """
    # Use a flag to avoid infinite recursion.
    if d.getVarFlag(var, 'add_implied_items_internal') == '1':
        return ''

    def implied_items(item, implied_mapping, d, seen=None):
        """Return the implied items for a given item."""
        if seen is None:
            seen = set()
        if item in seen:
            return ''
        seen.add(item)
        implied = implied_mapping.get(item, '').split()
        return ' '.join(implied + [implied_items(f, implied_mapping, d, seen) for f in implied])

    d.setVarFlag(var, 'add_implied_items_internal', '1')
    try:
        value = d.getVar(var)
        implied_mapping = d.getVarFlags(implied_var)
        if implied_mapping is None:
            return ''

        return ' '.join(implied_items(f, implied_mapping, d) for f in value.split())
    finally:
        d.delVarFlag(var, 'add_implied_items_internal')
