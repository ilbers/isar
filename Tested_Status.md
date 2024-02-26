Tested Status
=============

Release next
------------

Release v0.10
-------------

### Host System: debian-stretch-amd64

NOT SUPPORTED

### Host System: debian-buster-amd64

NOT TESTED

### Host System: debian-bullseye-amd64

NOT TESTED

### Host System: debian-bookworm-amd64

| Target System            | Native Build  | Cross Build   |Login prompt ("smoke" test)|SDK Support|Cached repo| Version |
|:------------------------:|:-------------:|:-------------:|:-------------------------:|:---------:|:---------:|:-------:|
| qemuarm-buster           | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemuarm-bullseye         | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | PASSED    | d7caff0 |
| qemuarm-bookworm         | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemuarm64-buster         | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemuarm64-bullseye       | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | PASSED    | d7caff0 |
| qemuarm64-bookworm       | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemui386-buster          | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemui386-bullseye        | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemui386-bookworm        | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemuamd64-buster         | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemuamd64-bullseye       | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | PASSED    | d7caff0 |
| qemuamd64-sb-bullseye    | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemuamd64-bookworm       | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemumipsel-buster        | PASSED        | PASSED #9     | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemumipsel-bullseye      | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemumipsel-bookworm      | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemuriscv64-sid          | PASSED        | PASSED #8     | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemuarm64-focal          | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemuamd64-focal          | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemuarm64-jammy          | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| qemuamd64-jammy          | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | d7caff0 |
| container-amd64-buster   | PASSED        | PASSED        | PASSED (Docker)           | UNTESTED  | UNTESTED  | d7caff0 |
| container-amd64-bullseye | PASSED        | PASSED        | PASSED (Docker)           | UNTESTED  | UNTESTED  | d7caff0 |
| container-amd64-bookworm | PASSED        | PASSED        | PASSED (Docker)           | UNTESTED  | UNTESTED  | d7caff0 |
| virtualbox-bullseye      | PASSED        | PASSED        | PASSED (Virtualbox)       | UNTESTED  | UNTESTED  | d7caff0 |
| virtualbox-bookworm      | PASSED        | PASSED        | PASSED (Virtualbox)       | UNTESTED  | UNTESTED  | d7caff0 |
| bananapi-buster          | PASSED        | PASSED        | PASSED #3                 | UNTESTED  | UNTESTED  | d7caff0 |
| bananapi-bullseye        | PASSED        | PASSED        | PASSED #3                 | UNTESTED  | UNTESTED  | d7caff0 |
| bananapi-bookworm        | PASSED        | PASSED        | PASSED #3                 | UNTESTED  | UNTESTED  | d7caff0 |
| de0-nano-soc-buster      | FAILED        | FAILED        | UNTESTED                  | UNTESTED  | UNTESTED  | d7caff0 |
| de0-nano-soc-bullseye    | PASSED        | PASSED        | PASSED #4                 | UNTESTED  | UNTESTED  | d7caff0 |
| de0-nano-soc-bookworm    | PASSED        | PASSED        | PASSED #4                 | UNTESTED  | UNTESTED  | d7caff0 |
| hikey-bullseye           | PASSED        | PASSED        | PASSED #5                 | UNTESTED  | UNTESTED  | d7caff0 |
| hikey-bookworm           | PASSED        | PASSED        | PASSED #5                 | UNTESTED  | UNTESTED  | d7caff0 |
| imx6-sabrelite-buster    | PASSED        | PASSED        | UNTESTED                  | UNTESTED  | UNTESTED  | d7caff0 |
| imx6-sabrelite-bullseye  | PASSED        | PASSED        | UNTESTED                  | UNTESTED  | UNTESTED  | d7caff0 |
| phyboard-mira-bullseye   | PASSED        | PASSED        | PASSED #7                 | UNTESTED  | UNTESTED  | d7caff0 |
| nanopi-neo-buster        | PASSED        | PASSED        | PASSED #6                 | UNTESTED  | UNTESTED  | d7caff0 |
| nanopi-neo-bullseye      | PASSED        | PASSED        | PASSED #6                 | UNTESTED  | UNTESTED  | d7caff0 |
| nanopi-neo-bookworm      | PASSED        | PASSED        | PASSED #6                 | UNTESTED  | UNTESTED  | d7caff0 |
| nanopi-neo-efi-bookworm  | PASSED        | PASSED        | PASSED #6                 | UNTESTED  | UNTESTED  | d7caff0 |
| stm32mp15x-bullseye      | PASSED        | PASSED        | UNTESTED                  | UNTESTED  | UNTESTED  | d7caff0 |
| rpi-arm-bullseye         | PASSED        | PASSED        | PASSED #1                 | UNTESTED  | UNTESTED  | d7caff0 |
| rpi-arm-bookworm         | PASSED        | PASSED        | PASSED #1                 | UNTESTED  | UNTESTED  | d7caff0 |
| rpi-arm-v7-bullseye      | PASSED        | PASSED        | PASSED #1                 | UNTESTED  | PASSED    | d7caff0 |
| rpi-arm-v7-bookworm      | PASSED        | PASSED        | PASSED #1                 | UNTESTED  | UNTESTED  | d7caff0 |
| rpi-arm-v7l-bullseye     | PASSED        | PASSED        | PASSED #1                 | UNTESTED  | UNTESTED  | d7caff0 |
| rpi-arm-v7l-bookworm     | PASSED        | PASSED        | PASSED #1                 | UNTESTED  | UNTESTED  | d7caff0 |
| rpi-arm64-v8-bullseye    | PASSED        | PASSED        | PASSED #2                 | UNTESTED  | PASSED    | d7caff0 |
| rpi-arm64-v8-bookworm    | PASSED        | PASSED        | PASSED #2                 | UNTESTED  | UNTESTED  | d7caff0 |
| sifive-fu540-sid         | PASSED        | PASSED        | UNTESTED                  | UNTESTED  | UNTESTED  | d7caff0 |
| starfive-visionfive2-sid | PASSED        | PASSED        | PASSED                    | UNTESTED  | UNTESTED  | d7caff0 |

#1: Tested on RPI3B+
#2: Tested on RPI4B
#3: Tested on BPI-M1
#4: Tested on Terasic Atlas-SoC
#5: Tested on LeMaker HiKey 2 GB
#6: Tested on NanoPi Neo LTS 512 MB
#7: Tested on i.MX6 Quad
#8: Built with snapshot.debian.org/archive/debian/20240226T213049Z/
#9: Built with disabled debian-security

### Host System: debian-stretch-i386

NOT SUPPORTED

### Host System: debian-buster-i386

NOT TESTED

Release v0.9
------------

### Host System : debian-stretch-amd64

NOT TESTED

### Host System : debian-jessie-amd64

NOT SUPPORTED

### Host System : debian-buster-amd64

NOT TESTED

### Host System : debian-bullseye-amd64

| Target System            | Native Build  | Cross Build   |Login prompt ("smoke" test)|SDK Support|Cached repo| Version |
|:------------------------:|:-------------:|:-------------:|:-------------------------:|:---------:|:---------:|:-------:|
| qemuarm-stretch          | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemuarm-buster           | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemuarm-bullseye         | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | PASSED    | c806c9d |
| qemuarm-bookworm         | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemuarm64-stretch        | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemuarm64-buster         | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemuarm64-bullseye       | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | PASSED    | c806c9d |
| qemuarm64-bookworm       | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemui386-stretch         | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemui386-buster          | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemui386-bullseye        | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemui386-bookworm        | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemuamd64-stretch        | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemuamd64-buster         | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemuamd64-bullseye       | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | PASSED    | c806c9d |
| qemuamd64-bookworm       | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemumipsel-stretch       | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemumipsel-buster        | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemumipsel-bullseye      | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemumipsel-bookworm      | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemuriscv64-sid-ports    | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | 79fe150 |
| qemuarm64-focal          | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| qemuamd64-focal          | PASSED        | PASSED        | PASSED (QEMU)             | PASSED    | UNTESTED  | c806c9d |
| container-amd64-stretch  | PASSED        | UNTESTED      | PASSED (Docker)           | UNTESTED  | UNTESTED  | 1000df8 |
| container-amd64-buster   | PASSED        | UNTESTED      | PASSED (Docker)           | UNTESTED  | UNTESTED  | 1000df8 |
| container-amd64-bullseye | PASSED        | UNTESTED      | PASSED (Docker)           | UNTESTED  | UNTESTED  | 1000df8 |
| container-amd64-bookworm | PASSED        | UNTESTED      | PASSED (Docker)           | UNTESTED  | UNTESTED  | 1000df8 |
| virtualbox-bullseye      | PASSED        | UNTESTED      | PASSED (Virtualbox)       | UNTESTED  | UNTESTED  | fb1370b |
| bananapi-buster          | PASSED        | PASSED        | PASSED                    | UNTESTED  | UNTESTED  | 1000df8 |
| bananapi-bullseye        | PASSED        | PASSED        | PASSED                    | UNTESTED  | PASSED    | 1000df8 |
| de0-nano-soc-buster      | PASSED        | PASSED        | PASSED                    | UNTESTED  | UNTESTED  | 1000df8 |
| de0-nano-soc-bullseye    | PASSED        | PASSED        | PASSED                    | UNTESTED  | UNTESTED  | 1000df8 |
| hikey-bullseye           | PASSED        | PASSED        | PASSED                    | UNTESTED  | UNTESTED  | 1000df8 |
| hikey-bookworm           | PASSED        | PASSED        | PASSED                    | UNTESTED  | UNTESTED  | 1000df8 |
| imx6-sabrelite-buster    | PASSED        | PASSED        | UNTESTED                  | UNTESTED  | UNTESTED  | 1000df8 |
| imx6-sabrelite-bullseye  | PASSED        | PASSED        | UNTESTED                  | UNTESTED  | UNTESTED  | 1000df8 |
| nanopi-neo-buster        | PASSED        | PASSED        | PASSED                    | UNTESTED  | UNTESTED  | 1000df8 |
| nanopi-neo-bullseye      | PASSED        | PASSED        | PASSED                    | UNTESTED  | UNTESTED  | 1000df8 |
| stm32mp15x-buster        | PASSED        | PASSED        | UNTESTED                  | UNTESTED  | UNTESTED  | 1000df8 |
| stm32mp15x-bullseye      | PASSED        | PASSED        | UNTESTED                  | UNTESTED  | UNTESTED  | 1000df8 |
| rpi-stretch              | PASSED        | PASSED        | PASSED                    | UNTESTED  | UNTESTED  | c806c9d |
| rpi-arm-bullseye         | PASSED        | PASSED        | PASSED but #1             | UNTESTED  | UNTESTED  | c806c9d |
| rpi-arm-v7-bullseye      | PASSED        | PASSED        | PASSED but #1             | UNTESTED  | UNTESTED  | c806c9d |
| rpi-arm-v7l-bullseye     | PASSED        | PASSED        | PASSED but #1             | UNTESTED  | UNTESTED  | c806c9d |
| rpi-arm64-v8-bullseye    | PASSED        | PASSED        | PASSED                    | UNTESTED  | UNTESTED  | c806c9d |
| sifive-fu540-sid-ports   | PASSED        | PASSED        | UNTESTED                  | UNTESTED  | UNTESTED  | 79fe150 |

#1:
 - raspi-os provides three different kernel/modules sets for different hardware
(e.g. kernel/5.15.32+, kernel7/5.15.32-v7+, kernel7l/5.15.32-v7l+). So, rpi-arm,
rpi-arm-v7 and rpi-arm-v7l builds differ in kernel example-module.ko build for.
All three images can boot on any RPi hardware, but only on corresponding boards
example-module is autoloaded.

### Host System : debian-bookworm-amd64

NOT TESTED

### Host System : debian-jessie-i386

NOT SUPPORTED

### Host System : debian-stretch-i386

NOT TESTED

### Host System : debian-buster-i386

NOT TESTED

Release v0.8
------------

### Host System : debian-stretch-amd64

NOT TESTED

### Host System : debian-jessie-amd64

NOT SUPPORTED

### Host System : debian-buster-amd64

|Target System              |Native Build |Cross Build  |Login prompt ("smoke" test)|SDK Support  |Cached repo    |Version  |
|:-------------------------:|:-----------:|:------------|:-------------------------:|:-----------:|:-------------:|:-------:|
| qemuarm-stretch           |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuarm-buster            |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuarm-bullseye          |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuarm-bookworm          |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuarm64-stretch         |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuarm64-buster          |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuarm64-bullseye        |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuarm64-bookworm        |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemui386-stretch          |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemui386-buster           |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemui386-bullseye         |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemui386-bookworm         |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuamd64-stretch         |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuamd64-buster          |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuamd64-buster-tgz      |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuamd64-buster-cpiogz   |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuamd64-bullseye        |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuamd64-bullseye-tgz    |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuamd64-bullseye-cpiogz |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuamd64-bookworm        |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemumipsel-stretch        |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemumipsel-buster         |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemumipsel-bullseye       |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemumipsel-bookworm       |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuriscv64-sid-ports     |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuarm64-focal           |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| qemuamd64-focal           |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |UNTESTED       |49642d3  |
| container-amd64-stretch   |PASSED       |PASSED       |UNTESTED                   |UNTESTED     |UNTESTED       |49642d3  |
| container-amd64-buster    |PASSED       |PASSED       |UNTESTED                   |UNTESTED     |UNTESTED       |49642d3  |
| container-amd64-bullseye  |PASSED       |PASSED       |UNTESTED                   |UNTESTED     |UNTESTED       |49642d3  |
| container-amd64-bookworm  |PASSED       |PASSED       |UNTESTED                   |UNTESTED     |UNTESTED       |49642d3  |
| virtualbox-bullseye       |PASSED       |PASSED       |UNTESTED                   |UNTESTED     |UNTESTED       |49642d3  |
| bananapi-buster           |PASSED       |PASSED       |UNTESTED                   |UNTESTED     |UNTESTED       |5989136  |
| bananapi-bullseye         |PASSED       |PASSED       |UNTESTED                   |UNTESTED     |UNTESTED       |5989136  |
| de0-nano-soc-buster       |PASSED       |PASSED       |PASSED                     |UNTESTED     |UNTESTED       |5989136  |
| de0-nano-soc-bullseye     |PASSED       |PASSED       |PASSED, not #6             |UNTESTED     |UNTESTED       |5989136  |
| hikey-bullseye            |PASSED       |PASSED       |PASSED, not #4, #6         |UNTESTED     |UNTESTED       |5989136  |
| hikey-bookworm            |PASSED       |PASSED       |PASSED, not #4, #6         |UNTESTED     |UNTESTED       |5989136  |
| imx6-sabrelite-buster     |PASSED       |PASSED       |UNTESTED                   |UNTESTED     |UNTESTED       |5989136  |
| imx6-sabrelite-bullseye   |PASSED       |PASSED       |UNTESTED                   |UNTESTED     |UNTESTED       |5989136  |
| nanopi-neo-buster         |PASSED       |PASSED       |PASSED                     |UNTESTED     |UNTESTED       |5989136  |
| nanopi-neo-bullseye       |PASSED       |PASSED       |PASSED                     |UNTESTED     |UNTESTED       |5989136  |
| stm32mp15x-buster         |PASSED       |PASSED       |UNTESTED                   |UNTESTED     |UNTESTED       |5989136  |
| stm32mp15x-bullseye       |PASSED       |PASSED       |UNTESTED                   |UNTESTED     |UNTESTED       |5989136  |
| rpi-stretch               |PASSED       |PASSED       |PASSED                     |UNTESTED     |UNTESTED       |5989136  |
| rpi-arm-bullseye          |PASSED       |PASSED       |PASSED                     |UNTESTED     |UNTESTED       |2911926d |
| rpi-arm-v7-bullseye       |PASSED       |PASSED       |PASSED, not #6             |UNTESTED     |UNTESTED       |2911926d |
| rpi-arm-v7l-bullseye      |PASSED       |PASSED       |PASSED, not #6             |UNTESTED     |UNTESTED       |2911926d |
| rpi-arm64-v8-bullseye     |PASSED       |PASSED       |PASSED                     |UNTESTED     |UNTESTED       |2911926d |
| sifive-fu540-sid-ports    |PASSED       |PASSED       |UNTESTED                   |UNTESTED     |UNTESTED       |5989136  |

"Smoke" test:
1. system boots
2. seial connection with grkterm established
3. login prompt
4. no service failed
5. packages from IMAGE_INSTALL installed
6. example_module loaded
7. shutdown

debian-bullseye-hikey, debian-bookworm-hikey:
 - systemd-modules-load.service failed
 - e2scrub_reap.service failed
 - no modules are loaded

### Host System : debian-bullseye-amd64

NOT TESTED

### Host System : debian-bookworm-amd64

NOT TESTED

### Host System : debian-jessie-i386

NOT SUPPORTED

### Host System : debian-stretch-i386

NOT TESTED

### Host System : debian-buster-i386

NOT TESTED

Release v0.7
------------

### Host System : debian-stretch-amd64

|Target System                |Native Build |Cross Build  |Login prompt ("smoke" test)|SDK Support  |Cached repo    |Version |
|:---------------------------:|:-----------:|:------------|:-------------------------:|:-----------:|:-------------:|:------:|
| debian-jessie-i386          |PASSED       |UNTESTED     |PASSED (QEMU)              |NO           |UNTESTED       |e13be9c |
| debian-jessie-amd64         |PASSED       |PASSED       |PASSED (QEMU)              |NO           |PASSED         |e13be9c |
| debian-jessie-armhf         |PASSED       |PASSED       |PASSED (QEMU)              |NO           |PASSED see #47 |e13be9c |
| raspbian-jessie-rpi         |PASSED       |UNTESTED     |PASSED                     |NO           |UNTESTED       |e13be9c |
| debian-jessie-arm64         |UNTESTED     |UNTESTED     |UNTESTED                   |UNTESTED     |UNTESTED       |e13be9c |
| debian-stretch-i386         |PASSED       |UNTESTED     |PASSED (QEMU)              |UNTESTED     |UNTESTED       |e13be9c |
| debian-stretch-amd64        |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |PASSED         |e13be9c |
| debian-stretch-armhf        |PASSED       |PASSED       |PASSED (QEMU)              |PASSED       |PASSED         |e13be9c |
| debian-stretch-de0-nano-soc |UNTESTED     |PASSED       |PASSED                     |UNTESTED     |UNTESTED       |e13be9c |
| debian-stretch-bananapi     |PASSED       |PASSED       |PASSED                     |UNTESTED     |UNTESTED       |e13be9c |
| debian-stretch-arm64        |PASSED       |PASSED       |PASSED (QEMU)              |PASSED       |PASSED         |e13be9c |
| debian-stretch-hikey        |UNTESTED     |PASSED       |UNTESTED                   |UNTESTED     |UNTESTED       |e13be9c |
| debian-buster-i386          |PASSED       |UNTESTED     |PASSED (QEMU)              |UNTESTED     |UNTESTED       |e13be9c |
| debian-buster-amd64         |PASSED       |PASSED       |PASSED (QEMU)              |UNTESTED     |PASSED         |e13be9c |
| debian-buster-armhf         |PASSED       |PASSED       |PASSED (QEMU)              |PASSED       |PASSED see #47 |e13be9c |
| debian-buster-arm64         |UNTESTED     |UNTESTED     |UNTESTED                   |UNTESTED     |UNTESTED       |e13be9c |

### Host System : debian-jessie-amd64

NOT SUPPORTED

### Host System : debian-buster-amd64

NOT TESTED

### Host System : debian-jessie-i386

NOT SUPPORTED

### Host System : debian-stretch-i386

NOT TESTED

### Host System : debian-buster-i386

NOT TESTED

Release v0.6
------------

### Host System : debian-jessie-amd64

|Target System         |Native Build |QEMU test    |SDK Support  |Version |
|:--------------------:|:-----------:|:-----------:|:-----------:|:------:|
| debian-jessie-i386   |PASSED       |PASSED       |NO           |422b0be |
| debian-jessie-amd64  |PASSED       |PASSED       |NO           |422b0be |
| debian-jessie-armhf  |PASSED       |PASSED       |NO           |422b0be |
| debian-jessie-arm64  |UNTESTED     |UNTESTED     |UNTESTED     |UNTESTED|
| debian-stretch-i386  |PASSED       |PASSED       |UNTESTED     |422b0be |
| debian-stretch-amd64 |PASSED       |PASSED       |UNTESTED     |422b0be |
| debian-stretch-armhf |PASSED       |PASSED       |UNTESTED     |422b0be |
| debian-stretch-arm64 |PASSED       |PASSED       |UNTESTED     |422b0be |
| debian-buster-i386   |PASSED       |PASSED       |UNTESTED     |422b0be |
| debian-buster-amd64  |PASSED       |PASSED       |UNTESTED     |422b0be |
| debian-buster-armhf  |PASSED       |FAILED       |UNTESTED     |422b0be |
| debian-buster-arm64  |PASSED       |FAILED       |UNTESTED     |422b0be |


### Host System : debian-stretch-amd64

|Target System         |Native Build |Cross Build  |QEMU test    |SDK Support  |Version |
|:--------------------:|:-----------:|:------------|:-----------:|:-----------:|:------:|
| debian-jessie-i386   |PASSED       |UNTESTED     |PASSED       |NO           |96672c7 |
| debian-jessie-amd64  |PASSED       |PASSED       |PASSED       |NO           |96672c7 |
| debian-jessie-armhf  |PASSED       |PASSED       |PASSED       |NO           |96672c7 |
| debian-jessie-arm64  |UNTESTED     |UNTESTED     |UNTESTED     |UNTESTED     |UNTESTED|
| debian-stretch-i386  |PASSED       |UNTESTED     |PASSED       |UNTESTED     |96672c7 |
| debian-stretch-amd64 |PASSED       |PASSED       |PASSED       |PASSED       |96672c7 |
| debian-stretch-armhf |PASSED       |PASSED       |PASSED       |PASSED       |96672c7 |
| debian-stretch-arm64 |PASSED       |PASSED       |PASSED       |PASSED       |96672c7 |
| debian-buster-i386   |PASSED       |UNTESTED     |PASSED       |UNTESTED     |96672c7 |
| debian-buster-amd64  |PASSED       |PASSED       |PASSED       |PASSED       |96672c7 |
| debian-buster-armhf  |PASSED       |PASSED       |PASSED       |PASSED       |96672c7 |
| debian-buster-arm64  |PASSED       |UNTESTED     |FAILED       |UNTESTED     |96672c7 |

### Host System : debian-buster-amd64

NOT TESTED

### Host System : debian-jessie-i386

NOT TESTED

### Host System : debian-stretch-i386

NOT TESTED

### Host System : debian-buster-i386

NOT TESTED
