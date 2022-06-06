Tested Status
=============

Release next
------------

Release v0.9
------------

TBD

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
