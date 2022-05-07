#!/bin/bash

# Check if we have a location that we will mount to.
if [ -z "$1" ]
then
	echo "Invalid arguments. Use: ./importOldDirectory.sh <directory location> <device name>"
    exit 1
fi

# Check if we have a location from where we will mount.
if [ -z "$2" ]
then
	echo "Invalid arguments. Use: ./importOldDirectory.sh <directory location> <device name>"
    exit 1
fi

# Check if the directory location does exists. And stop if it does.
if [ -d "$1" ]; then
	echo "Directory already exists. Exiting..."
	exit 2
fi

# Check if the device is a block device that can mount.
if [ ! -b "/dev/$2" ]
then
	echo "$2 is not a block device. Exiting..."
	exit 3;
fi

# Create the directory location and mount the device to it.
mkdir $1
mount /dev/$2 $1