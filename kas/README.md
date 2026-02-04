# Support of kas

[kas](https://github.com/siemens/kas) is a tool to set up BitBake-based projects.

The `kas` directory contains the required configuration fragments to set up and build
Isar using the `kas-container` script and Kconfig language.

## Requirements

Since kas uses Docker or Podman based containers, users who run an Isar build
using the `kas-container` script should be allowed to run these containers in
privileged mode.

## Configuring Isar build

```
./kas/kas-container menu
```

This creates a `.config.yaml` file in the Isar root directory that stores the
configuration.

## Building Isar after configuration is done

```
./kas/kas-container build
```

This generates the `build/conf/` configuration and starts building Isar using
the kas container. The required image will be downloaded if not already present.

To access the build shell, the following command can be used:

```
./kas/kas-container shell
```
