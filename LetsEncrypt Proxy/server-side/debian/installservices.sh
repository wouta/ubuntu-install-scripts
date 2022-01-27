#!/bin/sh
apt update
apt upgrade
apt -y install apache2
a2enmod proxy
a2enmod proxy_http
a2enmod proxy_balancer
service apache2 restart