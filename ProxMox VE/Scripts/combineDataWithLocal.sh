#!/bin/bash

# Remove the data storage.
lvremove --yes /dev/pve/data
# Add the left over space to the root storage.
lvresize -l +100%FREE /dev/pve/root
# Resize it to the correct file system.
resize2fs /dev/mapper/pve-root