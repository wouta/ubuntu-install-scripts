#!/bin/bash

# Remove default motd and replace it with an usefull one.
rm /etc/motd
mv ./Debian/00-header /etc/update-motd.d/
mv ./Debian/10-sysinfo /etc/update-motd.d/
mv ./Debian/10-uname /etc/update-motd.d/
mv ./Debian/90-footer /etc/update-motd.d/
chmod 777 /etc/update-motd.d/*

# Install some software needed for the motd and install + configure ssh-server.
apt update
apt -y upgrade
apt -y install figlet vim openssh-server
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
service sshd restart

# Check if the user want to combine the root and data storage and handle that request.
read -p "\nDo you want to combine the root and data storage? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
	# Double check due to no testing!!!!
	read -p "\nThis feature is NOT tested. Continue anyway? " -n 1 -r
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		chmod 777 ./Scripts/combineDataWithLocal.sh
		./Scripts/combineDataWithLocal.sh
	fi
fi

# Check if the user want to add HPE software and handle that request.
read -p "\nDo you want to install HPE software? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
	chmod 777 ./HPE/installHPEController.sh
    ./HPE/installHPEController.sh
fi

# Check if the user want to readd existing drives and handle that request.
read -p "\nDo you want to readd existing disks? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mv ./Scripts/importOldDirectory.sh ./../
	chmod 777 ./../importOldDirectory.sh
fi

#Cleanup
cd ..
rm -rf realcryptonight-proxmox/
# We are done now.
exit 0