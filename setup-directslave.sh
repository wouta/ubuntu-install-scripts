#!/bin/bash

# Check if script is run as root.
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 0
fi

# Check if the login username is given.
if [ -z "$1" ]
	then
		echo "./setup-directslave.sh <login username> <login password>"
		exit 0
	else
		echo "Username given. Continue."
fi

# Check if the login password is given.
if [ -z "$2" ]
	then
		echo "./setup-directslave.sh <login username> <login password>"
		exit 0
	else
		echo "Password given. Continue."
fi

# Check if the OS is Debian.
os=`lsb_release -si`
if [[ $os != "Debian" ]]
	then
		echo "This system is not running Debian. Exiting..."
		exit 0
	else
		echo "This system is running Debian. Continue."
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

# Collect some needed data.
serverip=`hostname -I | awk '{print $1}'`
serverhostname=`dig -x ${serverip} +short | sed 's/\.[^.]*$//'`
randomdata=`(< /dev/urandom tr -dc 'a-zA-Z0-9' | fold -w 128 | head -n 1)`
binduid=`id -u bind`
bindgid=`id -g bind`

# Setup certbot for safely accessing the control panel.
certbot certonly --non-interactive --register-unsafely-without-email --agree-tos --standalone --preferred-challenges http -d $serverhostname

# Setup deploy script for later renewals.
echo '#!/bin/bash
rm /usr/local/directslave/ssl/*
cp /etc/letsencrypt/live/'$serverhostname'/fullchain.pem /usr/local/directslave/ssl/
cp /etc/letsencrypt/live/'$serverhostname'/privkey.pem /usr/local/directslave/ssl/
chown -R bind:bind /usr/local/directslave/ssl/
service directslave restart' > /etc/letsencrypt/renewal-hooks/deploy/directslave.sh

# Set correct permissions for deploy script.
chmod 755 /etc/letsencrypt/renewal-hooks/deploy/directslave.sh

# Remove old ssl files and add the new one.
rm /usr/local/directslave/ssl/*
cp /etc/letsencrypt/live/$serverhostname/fullchain.pem /usr/local/directslave/ssl/
cp /etc/letsencrypt/live/$serverhostname/privkey.pem /usr/local/directslave/ssl/

# Update conf settings.
sed -i "s/cookie_auth_key Change_this_line_to_something_long_\&_secure/cookie_auth_key $randomdata/g" /usr/local/directslave/etc/directslave.conf
#sed -i 's/background 	0/background 	1/g' /usr/local/directslave/etc/directslave.conf
sed -i "/uid/ c\uid             $binduid" /usr/local/directslave/etc/directslave.conf
sed -i "/gid/ c\gid             $bindgid" /usr/local/directslave/etc/directslave.conf
sed -i "s/rndc_path	\/usr\/local\/bin\/rndc/rndc_path	none/g" /usr/local/directslave/etc/directslave.conf
sed -i 's/debug		1/debug		0/g' /usr/local/directslave/etc/directslave.conf
sed -i "s/rndc_path	\/usr\/local\/bin\/rndc/rndc_path	none/g" /usr/local/directslave/etc/directslave.conf
sed -i "s/rndc_path	\/usr\/local\/bin\/rndc/rndc_path	none/g" /usr/local/directslave/etc/directslave.conf
sed -i "s/port  		2222/port  		2224/g" /usr/local/directslave/etc/directslave.conf
sed -i "s/sslport		2224/sslport		2222/g" /usr/local/directslave/etc/directslave.conf

# Set the correct permissions.
chown -R bind:bind /usr/local/directslave/

# Create the correct directory for the dns zone files and give it the correct owner.
mkdir -p /etc/namedb/secondary/
chown bind:bind -R /etc/namedb/

# Add the zone conf of directslave to the bind9 DNS server.
echo "include \"/etc/namedb/secondary/named.conf\"" >> /etc/bind/named.conf

# Create a user for directslave that can login.
/usr/local/directslave/bin/directslave --password $1:$2