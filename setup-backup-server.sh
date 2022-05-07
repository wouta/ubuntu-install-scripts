#!/bin/bash

# Run the default install.
chmod 755 setup-standard.sh
./setup-standard.sh

# Create a group called sftpgroup.
groupadd sftpgroup

# Update sshd_config to only allow users of the sftpgroup to connect over sftp.
sed -i "s/Subsystem/#Subsystem/g" /etc/ssh/sshd_config
echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config
echo "   Match Group sftpgroup" >> /etc/ssh/sshd_config
echo "   ChrootDirectory /backups" >> /etc/ssh/sshd_config
echo "   ForceCommand internal-sftp" >> /etc/ssh/sshd_config
echo "   X11Forwarding no" >> /etc/ssh/sshd_config
echo "   AllowTcpForwarding no" >> /etc/ssh/sshd_config

# Restart sshd to apply the config changes.
systemctl restart sshd.service

# Give the root user the add ssh user script.
mv ./add_ssh_user.sh /root/
chmod 755 /root/add_ssh_user.sh

# Make the backup directory
mkdir /backups

# Set the correct permission for the backup directory.
chown root:root /backups
