# This file is included into 3 canned wks files from this directory
part /boot --source bootimg-pcbios-isar --ondisk sda --label boot --active --align 1024
part / --source rootfs --use-uuid --fstype=ext4 --label platform --align 1024 --exclude-path=boot --mkfs-extraopts "-T default" --fsuuid 1f55d66a-40d8-11ee-be56-0242ac120002
