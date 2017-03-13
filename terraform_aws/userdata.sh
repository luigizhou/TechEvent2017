#!/bin/bash 
sudo su
sudo yum update -y 
sudo yum install httpd -y
sudo service httpd start
sudo service httpd enable
echo '<h1>' $(hostname) '</h1>' >> /var/www/html/index.html