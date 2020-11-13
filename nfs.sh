#! /bin/sh

# If we already have SD, leave
if [ -e /mnt/mtd/ipc/tmpfs/sd/.sd_flag ]; then
        exit 0
fi

# Wait for reply from NFS server
while [ 1 ]
do
        if ping -c 1 -W 1 10.10.10.2 > /dev/null
        then
                break
        fi
        sleep 5
done

# Unpack files, mount them in /sys and touch flags to simulate SD
tar -C /mnt/mtd/ipc/tmpfs -xf /mnt/mtd/ipc/nosd.tgz
mount --bind /mnt/mtd/ipc/tmpfs/devices /sys/bus/mmc/devices
touch /dev/mmcblk0
touch /dev/mmcblk0p1
touch /mnt/mtd/ipc/tmpfs/sd_flag

# Mount and Monitor NFS
while [ 1 ]
do
        if [ ! -e /mnt/mtd/ipc/tmpfs/sd/.sd_flag ]; then
                umount /mnt/mtd/ipc/tmpfs/sd 2> /dev/null
                mount -o port=2049,nolock,proto=tcp -t nfs 10.10.10.2:/mnt/3TB/nvr-PTZ /mnt/mt
        fi
        sleep 15
done
