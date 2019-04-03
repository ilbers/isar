# Install Avocado

The framework could be installed by using standard HOWTO:

  https://github.com/avocado-framework/avocado#installing-with-standard-python-tools

Then you need to install varianter yaml-to-mux plugin by following these instructions:

  https://github.com/avocado-framework/avocado/tree/master/optional_plugins

## For Debian 9.x

        $ sudo apt-get install python-pip
        $ pip install --user subprocess32
        $ pip install --user avocado-framework
        $ pip install --user avocado-framework-plugin-varianter-yaml-to-mux

# Pre

        $ export PATH=$PATH:~/.local/bin
        $ cd isar
        $ source isar-init-build-env


# Run test

Each testsuite directory contains:
 - run.sh - script to start tests
 - variants.yaml - set of input data
 - *.py - test case

# Other

There is a tool start_vm.py which is the replacement for the bash script in isar/scripts directory.
