#!/bin/bash
sudo su
sudo su - root
sudo apt-get update
sudo apt-get install apache2 -y
cd /var/www/html
rm index.html
cd /root
git clone https://github.com/amolshete/card-website.git
cp -rf card-website/* /var/www/html/