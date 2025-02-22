#!/bin/sh

if [ -n "$BLUEMAP_DB_URL" ]; then
    escaped_url=$(printf '%s\n' "$BLUEMAP_DB_URL" | sed 's/[\/&]/\\&/g')
    sed -i "s#connection-url: \"\"#connection-url: \"$escaped_url\"#" /app/config/storages/sql.conf
fi

exec java -jar cli.jar -r -w