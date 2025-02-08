#!/bin/sh

DB_URL=${BLUEMAP_DB_URL}
DB_USER=${BLUEMAP_DB_USER}
DB_PASSWORD=${BLUEMAP_DB_PASSWORD}

sed -i "s|{{DB_URL}}|$DB_URL|g" /app/config/storages/sql.conf
sed -i "s|{{DB_USER}}|$DB_USER|g" /app/config/storages/sql.conf
sed -i "s|{{DB_PASSWORD}}|$DB_PASSWORD|g" /app/config/storages/sql.conf

exec java -jar cli.jar -w