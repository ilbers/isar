# Install Avocado

The framework could be installed by using standard HOWTO:

  https://github.com/avocado-framework/avocado#installing-with-standard-python-tools

## For Debian (tested on Debian 10.x)

        $ sudo dpkg -i avocado_91.0_all.deb

# Run test

## Fast build test

```
$ avocado run build_test.py -t fast -p quiet=1 -p cross=1
```

## Full build test

```
$ avocado run build_test.py -t full -p quiet=1
```

## Fast boot test

```
$ avocado run vm_boot_test.py -t fast -p build_dir="$BUILDDIR" -p time_to_wait=300
```

## Full boot test

```
$ avocado run vm_boot_test.py -t full -p build_dir="$BUILDDIR" -p time_to_wait=300
```

# Other

There is a tool start_vm.py which is the replacement for the bash script in isar/scripts directory.
