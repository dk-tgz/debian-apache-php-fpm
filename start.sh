#!/bin/bash
set -ex

docker run --detach --name debian-apache-php-fpm -p 80:80 -p 443:443 -v ./html:/var/www/html dktgz/debian-apache-php-fpm:latest 
