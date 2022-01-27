#!/bin/bash

if [ -z "$1" ]
then
	adddisk=0
else
	adddisk=1
fi

chmod 777 ./../Reuse-Scripts/scripts/standard-settings.sh
./../Reuse-Scripts/scripts/standard-settings.sh

if [[ "$adddisk" == 1 ]]
then
	(echo n; echo ""; echo ""; echo ""; echo ""; echo w; echo q) | fdisk $(echo $3)
	mkfs.ext4 $2
	mkdir /backups
	mount $2 /backups
	echo "${2} /backups ext4 defaults 1 2" >> /etc/fstab
	mv 10-sysinfo /etc/update-motd.d/
	chmod 777 /etc/update-motd.d/*
else
	mkdir /backups
fi

groupadd sftpgroup
sed -i 's/Subsystem/#Subsystem/g' /etc/ssh/sshd_config
echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config
echo "   Match Group sftpgroup" >> /etc/ssh/sshd_config
echo "   ChrootDirectory /backups" >> /etc/ssh/sshd_config
echo "   ForceCommand internal-sftp" >> /etc/ssh/sshd_config
echo "   X11Forwarding no" >> /etc/ssh/sshd_config
echo "   AllowTcpForwarding no" >> /etc/ssh/sshd_config
service sshd restart

chmod 700 ./../Reuse-Scripts/scripts/add_ssh_user.sh
chown root:root /backups

rm setup.sh