#!/bin/bash

# Create new package with our contents
tar czpf new_config_backup.tgz mnt/mtd/ipc/conf/
# Create new package file with 'IPCAM' added to the end of file
echo -n "IPCAM" | cat new_config_backup.tgz - > new_config_backup.tgz.md5
# Get the MD5 sum of the package with 'IPCAM' at the end of file
MD=$(md5sum new_config_backup.tgz.md5 | awk '{print $1}')
# Clean up (we no longer need this file)
rm -f new_config_backup.tgz.md5
# Get size of package (without IPCAM at the end of file)
SZ=$(printf '%X' `stat -c %s new_config_backup.tgz`)
# Create new header for our config backup starting by signature
echo -ne 'PIHC\x01\x10' > nh.bin
# Fill in blank space
dd if=/dev/zero bs=18 count=1 >> nh.bin
# Add in size of package/payload
echo -ne "\x${SZ:2:2}\x${SZ:0:2}\x00\x00IPCAM" >> nh.bin
# Fill in blank space
dd if=/dev/zero bs=195 count=1 >> nh.bin
# Add in MD5 sum of package/payload
echo -n "$MD" >> nh.bin
# Fill in blank space
dd if=/dev/zero bs=252 count=1 >> nh.bin
# Create new config_backup with header and package/payload combined
cat nh.bin new_config_backup.tgz > new_config_backup.bin
# Clean up header and package files (no longer needed)
rm -rf nh.bin new_config_backup.tgz
