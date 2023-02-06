# Install Avocado

The framework could be installed by using standard HOWTO:

  https://github.com/avocado-framework/avocado#installing-with-standard-python-tools

## For Debian (tested on Debian 11.x)

```
$ pip install avocado-framework==99.0
```

# Run test

## Quick developers test

```
$ avocado run ../testsuite/citest.py -t dev --nrunner-max-parallel-tasks=1
```

## Fast build test

```
$ avocado run ../testsuite/citest.py -t fast --nrunner-max-parallel-tasks=1 -p quiet=1
```

## Full build test

```
$ avocado run ../testsuite/citest.py -t full --nrunner-max-parallel-tasks=1 -p quiet=1
```

## Fast boot test

```
$ avocado run ../testsuite/citest.py -t startvm,fast -p time_to_wait=300
```

## Full boot test

```
$ avocado run ../testsuite/citest.py -t startvm,full -p time_to_wait=300
```

# Other

There is a tool start_vm.py which is the replacement for the bash script in isar/scripts directory.
