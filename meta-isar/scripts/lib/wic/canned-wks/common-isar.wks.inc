# This file is included into 3 canned wks files from this directory
part /boot --source bootimg-pcbios-isar --ondisk sda --label boot --active --align 1024
part / --source rootfs --ondisk sda --fstype=ext4 --mkfs-extraopts "-T default" --label platform --align 1024 --exclude-path=boot
