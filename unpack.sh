#!/bin/bash

# Create new file without header
dd if=config_backup.bin of=config_backup.tgz bs=512 skip=1
# Extract it
tar xf config_backup.tgz
