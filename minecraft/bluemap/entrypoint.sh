#!/bin/sh

sed -i "s|connection-url: \"\"|connection-url: \"$BLUEMAP_DB_URL\"|g" /app/config/storages/sql.conf

exec java -jar cli.jar -w