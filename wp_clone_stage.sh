#! /usr/bin/env bash
set -eu

# You'll want to set these.
PARENT_DIR='/home/ubuntu/gatoflow'
SRC='prod'
DST='staging'

# Assumes you've set [client] user and password in ~/.my.cnf

echo "Taking the ${DST} site down, first."
sudo rm -rf $PARENT_DIR/webroot_${DST}

echo "Dropping and re-creating ${DST} database, to prevent extra tables from sticking around."
echo "drop database wp_gatoflow_${DST}" | mysql
echo "create database wp_gatoflow_${DST}" | mysql

echo "Dumping and loading from ${SRC} -> ${DST} database."
mysqldump wp_gatoflow_${SRC} | mysql wp_gatoflow_${DST}

echo "Copying the webroot directory from ${SRC} -> ${DST}."
sudo cp -r $PARENT_DIR/webroot_{$SRC,$DST}
sudo chown -R www-data:public_html $PARENT_DIR/webroot_${DST}

echo "Pointing ${DST} wp-config.php to the ${DST} database."
sudo sed -i "s/DB_NAME\(.*\)_${SRC}/DB_NAME\1_${DST}/" $PARENT_DIR/webroot_${DST}/wp-config.php

echo "Successfully cloned from ${SRC} -> ${DST}."
