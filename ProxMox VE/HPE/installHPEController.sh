#!/bin/bash

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
mv ./HPE/smartctl /usr/sbin/smartctl