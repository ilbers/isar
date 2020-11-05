#
# This is a copy on write dictionary and set which abuses classes to try and be nice and fast.
#
# Copyright (C) 2006 Tim Ansell
#
#Please Note:
# Be careful when using mutable types (ie Dict and Lists) - operations involving these are SLOW.
# Assign a file to __warn__ to get warnings about slow operations.
#


import copy
import types
ImmutableTypes = (
    bool,
    complex,
    float,
    int,
    tuple,
    frozenset,
    str
)

MUTABLE = "__mutable__"

class COWMeta(type):
    pass

class COWDictMeta(COWMeta):
    __warn__ = False
    __hasmutable__ = False
    __marker__ = tuple()

    def __str__(cls):
        """
        Return a string representation of the class.

        Args:
            cls: (todo): write your description
        """
        # FIXME: I have magic numbers!
        return "<COWDict Level: %i Current Keys: %i>" % (cls.__count__, len(cls.__dict__) - 3)
    __repr__ = __str__

    def cow(cls):
        """
        Creates a new class with the given cnf.

        Args:
            cls: (todo): write your description
        """
        class C(cls):
            __count__ = cls.__count__ + 1
        return C
    copy = cow
    __call__ = cow

    def __setitem__(cls, key, value):
        """
        Sets the key to the given value pair.

        Args:
            cls: (todo): write your description
            key: (str): write your description
            value: (str): write your description
        """
        if value is not None and not isinstance(value, ImmutableTypes):
            if not isinstance(value, COWMeta):
                cls.__hasmutable__ = True
            key += MUTABLE
        setattr(cls, key, value)

    def __getmutable__(cls, key, readonly=False):
        """
        Get the value of a key.

        Args:
            cls: (callable): write your description
            key: (str): write your description
            readonly: (todo): write your description
        """
        nkey = key + MUTABLE
        try:
            return cls.__dict__[nkey]
        except KeyError:
            pass

        value = getattr(cls, nkey)
        if readonly:
            return value

        if not cls.__warn__ is False and not isinstance(value, COWMeta):
            print("Warning: Doing a copy because %s is a mutable type." % key, file=cls.__warn__)
        try:
            value = value.copy()
        except AttributeError as e:
            value = copy.copy(value)
        setattr(cls, nkey, value)
        return value

    __getmarker__ = []
    def __getreadonly__(cls, key, default=__getmarker__):
        """\
        Get a value (even if mutable) which you promise not to change.
        """
        return cls.__getitem__(key, default, True)

    def __getitem__(cls, key, default=__getmarker__, readonly=False):
        """
        Return the value of a given key.

        Args:
            cls: (todo): write your description
            key: (str): write your description
            default: (todo): write your description
            __getmarker__: (todo): write your description
            readonly: (todo): write your description
        """
        try:
            try:
                value = getattr(cls, key)
            except AttributeError:
                value = cls.__getmutable__(key, readonly)

            # This is for values which have been deleted
            if value is cls.__marker__:
                raise AttributeError("key %s does not exist." % key)

            return value
        except AttributeError as e:
            if not default is cls.__getmarker__:
                return default

            raise KeyError(str(e))

    def __delitem__(cls, key):
        """
        Removes item from the item.

        Args:
            cls: (todo): write your description
            key: (str): write your description
        """
        cls.__setitem__(key, cls.__marker__)

    def __revertitem__(cls, key):
        """
        Recursively copies of the item.

        Args:
            cls: (todo): write your description
            key: (str): write your description
        """
        if key not in cls.__dict__:
            key += MUTABLE
        delattr(cls, key)

    def __contains__(cls, key):
        """
        Determine if key contains a key.

        Args:
            cls: (todo): write your description
            key: (todo): write your description
        """
        return cls.has_key(key)

    def has_key(cls, key):
        """
        Returns true if the key exists.

        Args:
            cls: (todo): write your description
            key: (str): write your description
        """
        value = cls.__getreadonly__(key, cls.__marker__)
        if value is cls.__marker__:
            return False
        return True

    def iter(cls, type, readonly=False):
        """
        Iterate over the key / value pairs.

        Args:
            cls: (todo): write your description
            type: (str): write your description
            readonly: (bool): write your description
        """
        for key in dir(cls):
            if key.startswith("__"):
                continue

            if key.endswith(MUTABLE):
                key = key[:-len(MUTABLE)]

            if type == "keys":
                yield key

            try:
                if readonly:
                    value = cls.__getreadonly__(key)
                else:
                    value = cls[key]
            except KeyError:
                continue

            if type == "values":
                yield value
            if type == "items":
                yield (key, value)
        return

    def iterkeys(cls):
        """
        Return an iterator over all keys in the keys.

        Args:
            cls: (todo): write your description
        """
        return cls.iter("keys")
    def itervalues(cls, readonly=False):
        """
        Return a list of the file iservice.

        Args:
            cls: (todo): write your description
            readonly: (bool): write your description
        """
        if not cls.__warn__ is False and cls.__hasmutable__ and readonly is False:
            print("Warning: If you arn't going to change any of the values call with True.", file=cls.__warn__)
        return cls.iter("values", readonly)
    def iteritems(cls, readonly=False):
        """
        Return an iterator over all items.

        Args:
            cls: (todo): write your description
            readonly: (bool): write your description
        """
        if not cls.__warn__ is False and cls.__hasmutable__ and readonly is False:
            print("Warning: If you arn't going to change any of the values call with True.", file=cls.__warn__)
        return cls.iter("items", readonly)

class COWSetMeta(COWDictMeta):
    def __str__(cls):
        """
        Return a string representation of the class.

        Args:
            cls: (todo): write your description
        """
        # FIXME: I have magic numbers!
        return "<COWSet Level: %i Current Keys: %i>" % (cls.__count__, len(cls.__dict__) -3)
    __repr__ = __str__

    def cow(cls):
        """
        Creates a new class with the given cnf.

        Args:
            cls: (todo): write your description
        """
        class C(cls):
            __count__ = cls.__count__ + 1
        return C

    def add(cls, value):
        """
        : param dict to : class : class : ~set.

        Args:
            cls: (todo): write your description
            value: (todo): write your description
        """
        COWDictMeta.__setitem__(cls, repr(hash(value)), value)

    def remove(cls, value):
        """
        Removes an item from the dictionary.

        Args:
            cls: (todo): write your description
            value: (todo): write your description
        """
        COWDictMeta.__delitem__(cls, repr(hash(value)))

    def __in__(cls, value):
        """
        Return a repr of the given value.

        Args:
            cls: (todo): write your description
            value: (todo): write your description
        """
        return repr(hash(value)) in COWDictMeta

    def iterkeys(cls):
        """
        Return an iterator over all keys of the dictionary.

        Args:
            cls: (todo): write your description
        """
        raise TypeError("sets don't have keys")

    def iteritems(cls):
        """
        Iterate over all the items.

        Args:
            cls: (todo): write your description
        """
        raise TypeError("sets don't have 'items'")

# These are the actual classes you use!
class COWDictBase(object, metaclass = COWDictMeta):
    __count__ = 0

class COWSetBase(object, metaclass = COWSetMeta):
    __count__ = 0

if __name__ == "__main__":
    import sys
    COWDictBase.__warn__ = sys.stderr
    a = COWDictBase()
    print("a", a)

    a['a'] = 'a'
    a['b'] = 'b'
    a['dict'] = {}

    b = a.copy()
    print("b", b)
    b['c'] = 'b'

    print()

    print("a", a)
    for x in a.iteritems():
        print(x)
    print("--")
    print("b", b)
    for x in b.iteritems():
        print(x)
    print()

    b['dict']['a'] = 'b'
    b['a'] = 'c'

    print("a", a)
    for x in a.iteritems():
        print(x)
    print("--")
    print("b", b)
    for x in b.iteritems():
        print(x)
    print()

    try:
        b['dict2']
    except KeyError as e:
        print("Okay!")

    a['set'] = COWSetBase()
    a['set'].add("o1")
    a['set'].add("o1")
    a['set'].add("o2")

    print("a", a)
    for x in a['set'].itervalues():
        print(x)
    print("--")
    print("b", b)
    for x in b['set'].itervalues():
        print(x)
    print()

    b['set'].add('o3')

    print("a", a)
    for x in a['set'].itervalues():
        print(x)
    print("--")
    print("b", b)
    for x in b['set'].itervalues():
        print(x)
    print()

    a['set2'] = set()
    a['set2'].add("o1")
    a['set2'].add("o1")
    a['set2'].add("o2")

    print("a", a)
    for x in a.iteritems():
        print(x)
    print("--")
    print("b", b)
    for x in b.iteritems(readonly=True):
        print(x)
    print()

    del b['b']
    try:
        print(b['b'])
    except KeyError:
        print("Yay! deleted key raises error")

    if 'b' in b:
        print("Boo!")
    else:
        print("Yay - has_key with delete works!")

    print("a", a)
    for x in a.iteritems():
        print(x)
    print("--")
    print("b", b)
    for x in b.iteritems(readonly=True):
        print(x)
    print()

    b.__revertitem__('b')

    print("a", a)
    for x in a.iteritems():
        print(x)
    print("--")
    print("b", b)
    for x in b.iteritems(readonly=True):
        print(x)
    print()

    b.__revertitem__('dict')
    print("a", a)
    for x in a.iteritems():
        print(x)
    print("--")
    print("b", b)
    for x in b.iteritems(readonly=True):
        print(x)
    print()
