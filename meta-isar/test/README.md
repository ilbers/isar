# Common requirements

Use `meta-isar/test/` as working directory. Make sure `kas-container` is
available in $PATH (look at https://github.com/siemens/kas for it).

# Example of the downstream qemu-based testcase

1. Build an image:

```
kas-container build sample_kas_config.yml
```

2. Run testcase:

```
kas-container shell sample_kas_config.yml -c '/work/run_test.sh'
```

# Example of the downstream hardware testcase (example for RPi 3b+)

1. Build an image:

```
kas-container build sample_kas_config.yml
```

2. Flash resulted wic image to SD-card and boot the board

3. Run testcase (adjust `host` to RPi's IP address):

```
kas-container shell sample_kas_config_hw.yml -c "/work/run_test_hw.sh -p host=192.168.100.117"
```
