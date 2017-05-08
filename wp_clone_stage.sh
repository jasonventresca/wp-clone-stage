#! /usr/bin/env bash
set -eu

SRC='prod'
DST='staging'

MYSQL_USER='root'
MYSQL_PASS='YOUR_PASSWORD'

MYSQL_CREDS="--user='${MYSQL_USER}' --password='${MYSQL_PASS}'"

# Take the site down, first.
sudo rm -rf webroot_${DST}

# Drop and re-create dst database, to prevent extra tables from sticking around.
echo "drop database wp_gatoflow_${DST}" | mysql $MYSQL_CREDS
echo "create database wp_gatoflow_${DST}" | mysql $MYSQL_CREDS

# Dump and load from src -> dst DB.
mysqldump $MYSQL_CREDS wp_gatoflow_${SRC} | mysql $MYSQL_CREDS wp_gatoflow_${DST}

# Copy the webroot directory from src -> dst.
sudo cp -r webroot_{$SRC,$DST}
sudo chown -R www-data:public_html webroot_${DST}

# Point wp-config.php to the dst DB.
sudo sed -i "s/DB_NAME\(.*\)_${SRC}/DB_NAME\1_${DST}/" webroot_${DST}/wp-config.php

echo "Successfully cloned from ${SRC} -> ${DST}."
