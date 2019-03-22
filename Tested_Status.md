Tested Status
=============

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
