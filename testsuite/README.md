# Install Avocado

The framework could be installed by using standard HOWTO:

  https://github.com/avocado-framework/avocado#installing-with-standard-python-tools

## For Debian (tested on Debian 10.x)

        $ sudo dpkg -i avocado_91.0_all.deb

# Run test

Each testsuite directory contains:
 - run_*.sh - script to start tests
 - *.py - test case

# Other

There is a tool start_vm.py which is the replacement for the bash script in isar/scripts directory.
