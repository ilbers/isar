# Example of the downstream testcase

Use `meta-isar/test/` as working directory. Make sure `kas-container` is
available in $PATH (look at https://github.com/siemens/kas for it).

Build an image:

```
kas-container build sample_kas_config.yml
```

Run testcase:

```
kas-container shell sample_kas_config.yml -c '/work/run_test.sh'
```
