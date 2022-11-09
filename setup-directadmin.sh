#!/bin/bash

# Check if a license key is given.
if [ -z "$1" ]
  then
    echo "./setup-directadmin.sh <DirectAdmin license key>"
	exit 1
fi

echo "Configuring System Time... "
dpkg-reconfigure tzdata

# Run the default install.
chmod 755 setup-standard.sh
./setup-standard.sh

# Run common pre-install commands
apt -y update
apt -y upgrade
apt -y install gcc g++ make flex bison openssl libssl-dev perl perl-base perl-modules libperl-dev libperl4-corelibs-perl libwww-perl libaio1 libaio-dev zlib1g zlib1g-dev libcap-dev cron bzip2 zip automake autoconf libtool cmake pkg-config python libdb-dev libsasl2-dev libncurses5 libncurses5-dev libsystemd-dev bind9 dnsutils quota patch logrotate rsyslog libc6-dev libexpat1-dev libcrypt-openssl-rsa-perl libnuma-dev libnuma1

# Get the server IP for reverse DNS lookup.
serverip=`hostname -I | awk '{print $1}'`

# Get server hostname from reverse DNS lookup.
serverhostname=`dig -x ${serverip} +short | sed 's/\.[^.]*$//'`

# Get just the domain name.
domainhostname=`echo $serverhostname | sed 's/^[^.]*.//g'`

# NS hostnames.
ns1host="ns1.${domainhostname}"
ns2host="ns2.${domainhostname}"

# Set some variables to let DirectAdmin install correctly.
export DA_CHANNEL=current
export DA_HOSTNAME=$serverhostname
export DA_NS1=$ns1host
export DA_NS2=$ns2host
export DA_FOREGROUND_CUSTOMBUILD=yes
export mariadb=10.6

# Download and run the DirectAdmin install script.
wget -O directadmin.sh https://download.directadmin.com/setup.sh
chmod 755 directadmin.sh
./directadmin.sh $1

# Install and request LetsEncrypt Certificates for the directadmin domain itself.
cd /usr/local/directadmin/custombuild
./build letsencrypt
/usr/local/directadmin/scripts/letsencrypt.sh request_single $serverhostname 4096
systemctl restart directadmin.service

# Enable multi SSL support for the mail server.
echo "mail_sni=1" >> /usr/local/directadmin/conf/directadmin.conf
systemctl restart directadmin.service
cd /usr/local/directadmin/custombuild
./build clean
./build set_fastest
./build update
./build set eximconf yes
./build set dovecot_conf yes
./build exim_conf
./build dovecot_conf
echo "action=rewrite&value=mail_sni" >> /usr/local/directadmin/data/task.queue

# Enable and build cURL in CustomBuilds and build it.
cd /usr/local/directadmin/custombuild
sed -i "s/curl=no/curl=yes/g" options.conf
./build curl

# Change the installed PHP versions.
cd /usr/local/directadmin/custombuild
./build update
./build set php1_release 8.1
./build set php2_release 8.0
./build set php3_release 7.4
./build set php1_mode php-fpm
./build set php2_mode php-fpm
./build set php3_mode php-fpm
./build php n
./build secure_php
./build rewrite_confs

# Install everything needed for the Pro Pack.
cd /usr/local/directadmin/custombuild
./build composer
./build wp
./build imapsync
apt -y install git

# Setup SSO for PHPMyAdmin.
cd /usr/local/directadmin/
./directadmin set one_click_pma_login 1
service directadmin restart
cd custombuild
./build set phpmyadmin_public no
./build update
./build phpmyadmin

# Clear the screen and display the login data.
clear
. /usr/local/directadmin/scripts/setup.txt
echo "Username: $adminname"
echo "Password: $adminpass"
echo "Domain: $serverhostname"

exit 0
