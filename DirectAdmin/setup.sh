#!/bin/bash

chmod 777 ./../Reuse-Scripts/scripts/standard-settings.sh
./../Reuse-Scripts/scripts/standard-settings.sh

apt -y install sshpass gcc g++ make flex bison openssl libssl-dev perl perl-base perl-modules libperl-dev libperl4-corelibs-perl libwww-perl libaio1 libaio-dev zlib1g zlib1g-dev libcap-dev cron bzip2 zip automake autoconf libtool cmake pkg-config python libdb-dev libsasl2-dev libncurses5 libncurses5-dev libsystemd-dev bind9 dnsutils quota patch logrotate rsyslog libc6-dev libexpat1-dev libcrypt-openssl-rsa-perl libnuma-dev libnuma1

wget -O install.sh https://www.directadmin.com/setup.sh
chmod 755 install.sh
./install.sh auto

cd /usr/local/directadmin/custombuild
sed -i "s/curl=no/curl=yes/g" options.conf
./build curl

cd /usr/local/directadmin/scripts/custom/
wget -O ssh_script.zip https://github.com/poralix/directadmin-sftp-backups/archive/refs/heads/master.zip
unzip ssh_script.zip
cd directadmin-sftp-backups-master/
mv ftp_*.php ./../
cd ..
rm -rf directadmin-sftp-backups-master/
rm ssh_script.zip

cd /usr/local/directadmin/custombuild
./build rewrite_confs
./build update
./build letsencrypt
. /usr/local/directadmin/scripts/setup.txt
/usr/local/directadmin/scripts/letsencrypt.sh request_single $hostname 4096
/usr/local/directadmin/directadmin set ssl_redirect_host $hostname
service directadmin restart

echo "mail_sni=1" >> /usr/local/directadmin/conf/directadmin.conf
service directadmin restart
cd /usr/local/directadmin/custombuild
./build clean
./build update
./build set eximconf yes
./build set eximconf_release 4.5
./build set dovecot_conf yes
./build exim_conf
./build dovecot_conf
echo "action=rewrite&value=mail_sni" >> /usr/local/directadmin/data/task.queue

clear
. /usr/local/directadmin/scripts/setup.txt
echo "Username: $adminname"
echo "Password: $adminpass"
echo "Domain: $hostname"