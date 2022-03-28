#!/bin/bash

# Check if script is run as root.
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Check if the OS is Debian.
os=`lsb_release -si`
if [[ $os != "Debian" ]]
	then
		echo "This system is not running Debian. Exiting..."
		exit
	else
		echo "This system is running Debian. Continue."
fi

# Check if the login username is given.
if [ -z "$1" ]
	then
		echo "./setup-directslave.sh <login username> <login password>"
		exit
	else
		echo "Username given. Continue."
fi

# Check if the login password is given.
if [ -z "$2" ]
	then
		echo "./setup-directslave.sh <login username> <login password>"
		exit
	else
		echo "Password given. Continue."
fi

# Install certbot and bind9 as DNS server.
apt -y install certbot bind9

# Get the directslave files.
wget -O files.tar.gz https://directslave.com/download/directslave-3.4.2-advanced-all.tar.gz

# Extract the directslave files
tar -xf files.tar.gz

# Move the directslave folder to the correct location.
mv directslave/ /usr/local/

# Remove the downloaded archive.
rm files.tar.gz

# Get the correct package for Debian and remove the rest.
mv /usr/local/directslave/bin/directslave-linux-amd64 /usr/local/directslave/bin/directslave
rm /usr/local/directslave/bin/directslave-*

# Make the conf and passwd file.
cp /usr/local/directslave/etc/directslave.conf.sample /usr/local/directslave/etc/directslave.conf
cp /usr/local/directslave/etc/passwd.sample /usr/local/directslave/etc/passwd

# Get the server IP for reverse DNS lookup.
serverip=`hostname -I | awk '{print $1}'`

# Get server hostname from reverse DNS lookup.
serverhostname=`dig -x ${serverip} +short | sed 's/\.[^.]*$//'`

# Remove last dot from serverhostname.
domain=`echo $serverhostname | sed 's/^[^.]*.//g'`

# Random strong for cookie_auth_key.
randomdata=`(< /dev/urandom tr -dc 'a-zA-Z0-9' | fold -w 128 | head -n 1)`

# UID and GID for directslave.conf
binduid=`id -u bind`
bindgid=`id -g bind`

# Setup certbot for safely accessing the control panel with SSL.
certbot certonly --non-interactive --register-unsafely-without-email --agree-tos --standalone --preferred-challenges http -d $serverhostname

# Setup deploy script for later renewals.
echo '#!/bin/bash
rm /usr/local/directslave/ssl/*
cp /etc/letsencrypt/live/'$serverhostname'/fullchain.pem /usr/local/directslave/ssl/
cp /etc/letsencrypt/live/'$serverhostname'/privkey.pem /usr/local/directslave/ssl/
chown -R bind:bind /usr/local/directslave/ssl/
systemctl restart directslave.service' > /etc/letsencrypt/renewal-hooks/deploy/directslave.sh

# Set correct permissions for deploy script.
chmod 755 /etc/letsencrypt/renewal-hooks/deploy/directslave.sh

# Remove old ssl files and add the new one.
rm /usr/local/directslave/ssl/*
cp /etc/letsencrypt/live/$serverhostname/fullchain.pem /usr/local/directslave/ssl/
cp /etc/letsencrypt/live/$serverhostname/privkey.pem /usr/local/directslave/ssl/

# Update conf settings.
sed -i "s/cookie_auth_key Change_this_line_to_something_long_\&_secure/cookie_auth_key $randomdata/g" /usr/local/directslave/etc/directslave.conf
sed -i 's/background 	0/background 	1/g' /usr/local/directslave/etc/directslave.conf
sed -i "/uid/ c\uid             $binduid" /usr/local/directslave/etc/directslave.conf
sed -i "/gid/ c\gid             $bindgid" /usr/local/directslave/etc/directslave.conf
sed -i "s/rndc_path	\/usr\/local\/bin\/rndc/rndc_path	none/g" /usr/local/directslave/etc/directslave.conf
sed -i 's/debug		1/debug		0/g' /usr/local/directslave/etc/directslave.conf
sed -i "s/rndc_path	\/usr\/local\/bin\/rndc/rndc_path	none/g" /usr/local/directslave/etc/directslave.conf
sed -i "s/rndc_path	\/usr\/local\/bin\/rndc/rndc_path	none/g" /usr/local/directslave/etc/directslave.conf
sed -i "s/port  		2222/port  		2224/g" /usr/local/directslave/etc/directslave.conf
sed -i "s/sslport		2224/sslport		2222/g" /usr/local/directslave/etc/directslave.conf
sed -i "s/named_workdir	\/etc\/namedb\/secondary/named_workdir	\/etc\/bind\/directslave/g" /usr/local/directslave/etc/directslave.conf
sed -i "s/named_conf	\/etc\/namedb\/directslave.inc/named_conf	\/etc\/bind\/directslave.inc/g" /usr/local/directslave/etc/directslave.conf

# Set the correct permissions.
chown -R bind:bind /usr/local/directslave/

# Create the correct directory for the dns zone files and give it the correct owner.
mkdir -p /etc/bind/directslave/
chmod 775 /etc/bind/directslave/

touch /etc/bind/directslave.inc
chmod 664 /etc/bind/directslave.inc

# Add the zone conf of directslave to the bind9 DNS server.
echo "include \"/etc/bind/directslave.inc\";" >> /etc/bind/named.conf

systemctl restart bind9.service

echo "/etc/bind/directslave/** rw," >> /etc/apparmor.d/local/usr.sbin.named
systemctl reload apparmor.service
systemctl restart apparmor.service

# Create a user for directslave that can login into the web interface.
/usr/local/directslave/bin/directslave --password $1:$2

# Setup DirectSlave as a service.
sed -i "s/User=named/User=bind/g" /usr/local/directslave/etc/systemd/directslave.service
cp /usr/local/directslave/etc/systemd/directslave.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable directslave.service
systemctl start directslave.service