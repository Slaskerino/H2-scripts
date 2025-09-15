#!/bin/bash

# Stop scriptet ved fejl
set -e

#Tjek om Docker kører
docker --version
docker compose version

#Lav en projektmappe ved navn wordpress
mkdir ~/wordpress && cd ~/wordpress

#Opretter en docker-compose.yml fil

cat <<EOF | tee "docker-compose.yml" > /dev/null
version: '3.9'

services:
  db:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: wppass

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    ports:
      - "8080:80"
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: wppass
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wp_data:/var/www/html

volumes:
  db_data: {}
  wp_data: {}

EOF
#Starter Wordpress
docker compose up -d

