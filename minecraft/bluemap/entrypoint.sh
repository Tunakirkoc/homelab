#!/bin/sh

if [ -n "$BLUEMAP_DB_URL" ]; then
    escaped_url=$(printf '%s\n' "$BLUEMAP_DB_URL" | sed 's/[\/&]/\\&/g')
    sed -i "s#connection-url: \"\"#connection-url: \"$escaped_url\"#" /app/config/storages/sql.conf
fi

if [ -n "$BLUEMAP_DB_USER" ]; then
    escaped_user=$(printf '%s\n' "$BLUEMAP_DB_USER" | sed 's/[\/&]/\\&/g')
    sed -i "s/{{DB_USER}}/$escaped_user/" /app/config/storages/sql.conf
fi

if [ -n "$BLUEMAP_DB_PASSWORD" ]; then
    escaped_password=$(printf '%s\n' "$BLUEMAP_DB_PASSWORD" | sed 's/[\/&]/\\&/g')
    sed -i "s/{{DB_PASSWORD}}/$escaped_password/" /app/config/storages/sql.conf
fi

exec java -jar cli.jar -r -w