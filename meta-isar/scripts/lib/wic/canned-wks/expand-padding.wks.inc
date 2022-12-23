# some extra space we put in the end after the last partition
# that allows testing expand-on-first-boot while at the same time
# making our images more useful because they have space to play around

part --source empty --no-table --ondisk sda --size 256M
