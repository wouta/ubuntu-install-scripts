#!/bin/bash

chmod 755 setup-standard.sh
./setup-standard.sh

# Check if the user want to combine the root and data storage and handle that request.
read -p "\nDo you want to combine the root and data storage? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
	# Double check due to no testing!!!!
	read -p "\nThis feature is NOT tested. Continue anyway? " -n 1 -r
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		# Remove the data storage.
		lvremove --yes /dev/pve/data
		# Add the left over space to the root storage.
		lvresize -l +100%FREE /dev/pve/root
		# Resize it to the correct file system.
		resize2fs /dev/mapper/pve-root
	fi
fi

# Check if the user want to add HPE software and handle that request.
read -p "\nDo you want to install HPE software? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
	# Get the HPE keys for apt.
	wget http://downloads.linux.hpe.com/SDR/hpPublicKey1024.pub
	wget http://downloads.linux.hpe.com/SDR/hpPublicKey2048.pub
	wget http://downloads.linux.hpe.com/SDR/hpPublicKey2048_key1.pub
	wget http://downloads.linux.hpe.com/SDR/hpePublicKey2048_key1.pub
	mv hp* /etc/apt/trusted.gpg.d/

	# Add the HPE repo for bullseye.
	echo "deb http://downloads.linux.hpe.com/SDR/repo/mcp bullseye/current non-free" > /etc/apt/sources.list.d/hp-mcp.list

	# Install ssacli.
	apt update
	apt -y install ssacli

	# Update the smartctl to use the ssacli.
	mv /usr/sbin/smartctl /usr/sbin/smartctl.orig
	mv smartctl /usr/sbin/smartctl
fi