# Support of kas

[kas](https://github.com/siemens/kas) is a tool to setup bitbake based projects.

Directory `kas` contains required configuration fragments to setup and build
Isar with `kas-container` script and Kconfig language.

## Requirements

Since kas uses Docker or Podman based containers, users that runs Isar build
using `kas-container` script should be allowed to run these containers in
privileged mode.

## Configuring Isar build

```
./kas/kas-container menu
```

This creates `.config.yaml` file in isar root that stores the configuration.


## Building Isar after configuration done

```
./kas/kas-container build
```

This generates `build/conf/` configuration and starts building Isar using
kas container. Required image will be downloaded if not yet).

To access bulid shell, the following command can be used:

```
./kas/kas-container shell
```
