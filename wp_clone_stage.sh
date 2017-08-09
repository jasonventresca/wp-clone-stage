#! /usr/bin/env bash
set -eu

# Assumes you've set [client] user and password in ~/.my.cnf

################################################
# You'll want to set these.
SITE='helloworld'
PARENT_DIR="/home/ubuntu/${SITE}"
SRC='staging'
DST='prod'
SRC_HOSTNAME='staging.aliceinhelloworld.com'
DST_HOSTNAME='www.aliceinhelloworld.com'
################################################

if [[ $SRC = $DST ]]; then
    echo "Source and destination sites must be different: $SRC and $DST."
    exit 1
fi

if [[ $SRC_HOSTNAME = $DST_HOSTNAME ]]; then
    echo "Source and destination hostnames must be different: $SRC and $DST."
    exit 1
fi

echo "Disabling apache site: ${SITE}_${DST}"
sudo a2dissite ${SITE}_${DST}.conf && sudo service apache2 reload
# TODO - After running a2dissite, if you navigate to the $DST site, you'll be redirected to
#        another subdomain hosted on this server. For example, if you disable www.helloworld.com,
#        you'll be redirected to www.someothersite.com that exists in /etc/apache2/sites-enabled.
#        It would be nicer to instead get a "Site is down for maintenance, we'll be back shortly"
#        message, or even just an HTTP 404.

echo "Wiping the ${DST} webroot directory."
sudo rm -rf $PARENT_DIR/webroot_${DST}

echo "Dropping ${DST} database completely, to prevent extra tables from sticking around."
echo "drop database wp_${SITE}_${DST}" | mysql

echo "Copying the webroot directory from ${SRC} -> ${DST}."
sudo cp -r $PARENT_DIR/webroot_{$SRC,$DST}
sudo chown -R www-data:public_html $PARENT_DIR/webroot_${DST}

echo "Pointing ${DST} wp-config.php to the ${DST} database."
sudo sed -i "s/DB_NAME\(.*\)_${SRC}/DB_NAME\1_${DST}/" $PARENT_DIR/webroot_${DST}/wp-config.php

echo "Dumping and loading database from ${SRC} -> ${DST} database."
echo "create database wp_${SITE}_${DST}" | mysql
mysqldump wp_${SITE}_${SRC} | mysql wp_${SITE}_${DST}

echo "Updating Site URL in database."
wp search-replace \
    $SRC_HOSTNAME $DST_HOSTNAME \
    --path="$PARENT_DIR/webroot_${DST}" \
    --precise --all-tables --verbose

echo "Enabling apache site: ${SITE}_${DST}"
sudo a2ensite ${SITE}_${DST}.conf && sudo service apache2 reload

echo "Successfully cloned from ${SRC} -> ${DST}."
