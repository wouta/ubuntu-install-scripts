#!/bin/bash

chmod 755 setup-standard.sh
./setup-standard.sh

groupadd sftpgroup
sed -i "s/Subsystem(.*)/#Subsystem $1/g" /etc/ssh/sshd_config
echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config
echo "   Match Group sftpgroup" >> /etc/ssh/sshd_config
echo "   ChrootDirectory /backups" >> /etc/ssh/sshd_config
echo "   ForceCommand internal-sftp" >> /etc/ssh/sshd_config
echo "   X11Forwarding no" >> /etc/ssh/sshd_config
echo "   AllowTcpForwarding no" >> /etc/ssh/sshd_config
service sshd restart

mv ./add_ssh_user.sh /root/
chmod 755 /root/add_ssh_user.sh

chown root:root /backups:q
