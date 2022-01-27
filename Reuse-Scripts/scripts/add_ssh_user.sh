#!/bin/bash

echo "What should be the username of the SSH user?"
read username

adduser --home /backups/$username $username
usermod -G sftpgroup $username
chown $username:sftpgroup /backups/$username/
chmod 700 /backups/$username/
mkdir /backups/$username/.ssh
chown $username:$username /backups/$username/.ssh/
chmod 700 /backups/$username/.ssh/