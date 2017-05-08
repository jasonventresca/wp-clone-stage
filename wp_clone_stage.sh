#! /usr/bin/env bash
set -eu

# Assumes you've set [client] user and password in ~/.my.cnf

# You'll want to set these.
SITE='gatoflow'
SRC='prod'
DST='staging'
DST_DOMAIN="staging.${SITE}.com" # either staging or www
PARENT_DIR="/home/ubuntu/${SITE}"

NEW_DOMAIN_SCRIPT='/home/ubuntu/wordpress-change-site-url/update_wp_db_new_domain.sh'

if ! [ -f $NEW_DOMAIN_SCRIPT ]; then
    echo "Requires NEW_DOMAIN_SCRIPT to be installed. Bailing now!"
    exit 1
fi

echo "Taking the ${DST} site down, first."
sudo rm -rf $PARENT_DIR/webroot_${DST}

echo "Dropping and re-creating ${DST} database, to prevent extra tables from sticking around."
echo "drop database wp_${SITE}_${DST}" | mysql
echo "create database wp_${SITE}_${DST}" | mysql

echo "Dumping and loading from ${SRC} -> ${DST} database."
mysqldump wp_${SITE}_${SRC} | mysql wp_${SITE}_${DST}

echo "Updating Site URL in database."
$NEW_DOMAIN_SCRIPT wp_${SITE}_${DST} $DST_DOMAIN

echo "Copying the webroot directory from ${SRC} -> ${DST}."
sudo cp -r $PARENT_DIR/webroot_{$SRC,$DST}
sudo chown -R www-data:public_html $PARENT_DIR/webroot_${DST}

echo "Pointing ${DST} wp-config.php to the ${DST} database."
sudo sed -i "s/DB_NAME\(.*\)_${SRC}/DB_NAME\1_${DST}/" $PARENT_DIR/webroot_${DST}/wp-config.php

echo "Successfully cloned from ${SRC} -> ${DST}."
